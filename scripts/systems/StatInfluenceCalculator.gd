class_name StatInfluenceCalculator
extends RefCounted

# Most values prefer to rise. These danger/strain values prefer to fall.
const LOWER_IS_BETTER := {
    "fatigue": true,
    "stress": true,
    "social_suspicion": true,
    "origin_rumor": true,
    "notoriety": true,
    "underworld_trace": true,
    "direct_suspicion": true,
    "suspicion": true,
    "threat_alert": true,
    "evidence_risk": true,
    "investigation_progress": true,
    "rumor_spread": true,
}

const STAT_MAXIMUMS := {
    # Social rank is stored as a compact 0~6 progression value.
    "status": 6.0,
}

const DEFAULTS := {
    "reference_stat": 40.0,
    "chance_per_point": 0.45,
    "positive_min_multiplier": 0.75,
    "positive_max_multiplier": 1.50,
    "adverse_max_multiplier": 1.25,
    "adverse_min_multiplier": 0.60,
    "fatigue_free": 40.0,
    "fatigue_penalty_per_point": 0.12,
    "stress_free": 40.0,
    "stress_penalty_per_point": 0.10,
}


static func evaluate(action: Dictionary, player_stats: Dictionary, extra_chance_modifier: int = 0) -> Dictionary:
    var profile: Dictionary = action.get("stat_influence", {})
    if profile.is_empty():
        return {
            "enabled": false,
            "has_chance": action.has("base_success"),
            "skill": float(DEFAULTS["reference_stat"]),
            "effective_skill": float(DEFAULTS["reference_stat"]),
            "condition_modifier": 0,
            "stat_modifier": 0,
            "extra_modifier": extra_chance_modifier,
            "chance": clampi(int(action.get("base_success", 100)) + extra_chance_modifier, 5, 95),
            "stat_ids": [],
            "contributions": {},
        }

    var settings := DEFAULTS.duplicate()
    settings.merge(profile, true)
    var influences: Dictionary = profile.get("stats", {})
    var contributions: Dictionary = {}
    var weight_sum := 0.0
    var weighted_total := 0.0
    for raw_stat_id in influences.keys():
        var stat_id := String(raw_stat_id)
        var weight := maxf(0.0, float(influences[raw_stat_id]))
        if weight <= 0.0:
            continue
        var raw_value := maxf(0.0, float(player_stats.get(stat_id, 0)))
        var stat_max := float(STAT_MAXIMUMS.get(stat_id, 100.0))
        var value := clampf(raw_value / maxf(stat_max, 1.0) * 100.0, 0.0, 100.0)
        weighted_total += value * weight
        weight_sum += weight
        contributions[stat_id] = {"value": raw_value, "normalized": value, "weight": weight}

    var reference := clampf(float(settings["reference_stat"]), 1.0, 99.0)
    var skill := weighted_total / weight_sum if weight_sum > 0.0 else reference
    var condition_modifier := 0.0
    if not bool(profile.get("ignore_condition", false)):
        condition_modifier -= maxf(0.0, float(player_stats.get("fatigue", 0)) - float(settings["fatigue_free"])) * float(settings["fatigue_penalty_per_point"])
        condition_modifier -= maxf(0.0, float(player_stats.get("stress", 0)) - float(settings["stress_free"])) * float(settings["stress_penalty_per_point"])
    var stat_modifier := roundi((skill - reference) * float(settings["chance_per_point"]))
    var chance := int(action.get("base_success", 100)) + stat_modifier + roundi(condition_modifier) + extra_chance_modifier
    var stat_ids: Array[String] = []
    for stat_id in contributions.keys():
        stat_ids.append(String(stat_id))
    return {
        "enabled": true,
        "has_chance": action.has("base_success"),
        "skill": skill,
        "effective_skill": clampf(skill + condition_modifier, 0.0, 100.0),
        "condition_modifier": roundi(condition_modifier),
        "stat_modifier": stat_modifier,
        "extra_modifier": extra_chance_modifier,
        "chance": clampi(chance, int(profile.get("min_chance", 5)), int(profile.get("max_chance", 95))),
        "stat_ids": stat_ids,
        "contributions": contributions,
        "reference_stat": reference,
    }


static func adjusted_effects(action: Dictionary, effects: Dictionary, player_stats: Dictionary, evaluation: Dictionary = {}) -> Dictionary:
    var profile: Dictionary = action.get("stat_influence", {})
    if profile.is_empty() or bool(profile.get("chance_only", false)):
        return effects.duplicate(true)
    var result: Dictionary = {}
    var fixed_effects: Array = profile.get("fixed_effects", ["cash"])
    var current_evaluation := evaluation if not evaluation.is_empty() else evaluate(action, player_stats)
    var performance := float(current_evaluation.get("effective_skill", DEFAULTS["reference_stat"]))
    var reference := float(current_evaluation.get("reference_stat", profile.get("reference_stat", DEFAULTS["reference_stat"])))
    for raw_key in effects.keys():
        var key := String(raw_key)
        var base_value := int(effects[raw_key])
        if base_value == 0 or fixed_effects.has(key):
            result[key] = base_value
            continue
        var preferred_direction := -1 if LOWER_IS_BETTER.has(key) else 1
        var is_beneficial := base_value * preferred_direction > 0
        var multiplier := _effect_multiplier(performance, reference, is_beneficial, profile)
        var adjusted := roundi(float(base_value) * multiplier)
        if adjusted == 0:
            adjusted = 1 if base_value > 0 else -1
        result[key] = adjusted
    return result


static func summary(evaluation: Dictionary, display_names: Dictionary = {}) -> String:
    if not bool(evaluation.get("enabled", false)):
        return ""
    var parts: Array[String] = []
    var contributions: Dictionary = evaluation.get("contributions", {})
    for raw_stat_id in contributions.keys():
        var stat_id := String(raw_stat_id)
        var entry: Dictionary = contributions[raw_stat_id]
        parts.append("%s %d×%.1f" % [String(display_names.get(stat_id, stat_id)), roundi(float(entry.get("value", 0))), float(entry.get("weight", 0))])
    var text := ", ".join(parts) + " → 숙련 %d" % roundi(float(evaluation.get("skill", 0)))
    var stat_modifier := int(evaluation.get("stat_modifier", 0))
    if bool(evaluation.get("has_chance", false)) and stat_modifier != 0:
        text += " / 능력 성공률 %s%d" % ["+" if stat_modifier > 0 else "", stat_modifier]
    var condition_modifier := int(evaluation.get("condition_modifier", 0))
    if condition_modifier != 0:
        text += " / 컨디션 %s%d" % ["+" if condition_modifier > 0 else "", condition_modifier]
    var extra_modifier := int(evaluation.get("extra_modifier", 0))
    if bool(evaluation.get("has_chance", false)) and extra_modifier != 0:
        text += " / 상황 %s%d" % ["+" if extra_modifier > 0 else "", extra_modifier]
    return text


static func _effect_multiplier(performance: float, reference: float, is_beneficial: bool, profile: Dictionary) -> float:
    var low := float(profile.get("positive_min_multiplier" if is_beneficial else "adverse_max_multiplier", DEFAULTS["positive_min_multiplier" if is_beneficial else "adverse_max_multiplier"]))
    var high := float(profile.get("positive_max_multiplier" if is_beneficial else "adverse_min_multiplier", DEFAULTS["positive_max_multiplier" if is_beneficial else "adverse_min_multiplier"]))
    if performance <= reference:
        return lerpf(low, 1.0, clampf(performance / maxf(reference, 1.0), 0.0, 1.0))
    return lerpf(1.0, high, clampf((performance - reference) / maxf(100.0 - reference, 1.0), 0.0, 1.0))
