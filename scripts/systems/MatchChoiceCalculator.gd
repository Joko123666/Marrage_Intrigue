class_name MatchChoiceCalculator
extends RefCounted

const DEFAULT_SCALING := {
    "reference_stat": 25.0,
    "positive_min_multiplier": 0.75,
    "positive_max_multiplier": 1.75,
    "drawback_max_multiplier": 1.25,
    "drawback_min_multiplier": 0.50,
    "soft_requirement_reversal_below": 0.40,
    "soft_requirement_positive_floor": 0.00,
    "soft_requirement_reversal_max": 0.60,
    "soft_requirement_drawback_max": 2.00,
}


static func calculate_effects(choice: Dictionary, tag_definitions: Array, player_stats: Dictionary, scaling: Dictionary = {}) -> Dictionary:
    var skill := choice_skill(choice, tag_definitions, player_stats)
    var effects: Dictionary = choice.get("effects", {})
    var adjusted: Dictionary = {}
    for key in effects.keys():
        var base_value := int(effects[key])
        if base_value == 0:
            adjusted[String(key)] = 0
            continue
        var multiplier := _effect_multiplier(skill, base_value > 0, scaling)
        var value := roundi(float(base_value) * multiplier)
        if value == 0:
            value = 1 if base_value > 0 else -1
        adjusted[String(key)] = value
    return _apply_soft_requirement_scaling(adjusted, soft_requirement_evaluation(choice, player_stats, scaling), scaling)


static func soft_requirement_evaluation(choice: Dictionary, player_stats: Dictionary, scaling: Dictionary = {}) -> Dictionary:
    var settings := DEFAULT_SCALING.duplicate()
    settings.merge(scaling, true)
    var requirements: Dictionary = choice.get("requirements", {})
    var entries: Array[Dictionary] = []
    var ratio := 1.0
    for raw_key in requirements.keys():
        var requirement_id := String(raw_key)
        var stat_id := requirement_id.trim_prefix("min_")
        var required_value = requirements[raw_key]
        if not player_stats.has(stat_id) or (typeof(required_value) != TYPE_INT and typeof(required_value) != TYPE_FLOAT):
            continue
        var required := maxf(0.0, float(required_value))
        if required <= 0.0:
            continue
        var current := clampf(float(player_stats.get(stat_id, 0)), 0.0, 100.0)
        var entry_ratio := clampf(current / required, 0.0, 1.0)
        ratio = minf(ratio, entry_ratio)
        entries.append({
            "stat_id": stat_id,
            "current": roundi(current),
            "required": roundi(required),
            "ratio": entry_ratio,
            "met": current >= required,
        })
    var reversal_below := clampf(float(settings["soft_requirement_reversal_below"]), 0.05, 0.95)
    var state := "stable"
    if not entries.is_empty() and ratio < reversal_below:
        state = "backfire"
    elif not entries.is_empty() and ratio < 1.0:
        state = "reduced"
    return {
        "has_soft_requirements": not entries.is_empty(),
        "ratio": ratio,
        "state": state,
        "entries": entries,
        "reversal_below": reversal_below,
    }


static func apply_candidate_affinity(effects: Dictionary, choice: Dictionary, candidate: Dictionary, rules: Dictionary) -> Dictionary:
    if not choice_has_affinity(choice, candidate):
        return effects.duplicate(true)
    var positive_multiplier := float(rules.get("affinity_positive_multiplier", 1.0))
    var drawback_multiplier := float(rules.get("affinity_drawback_multiplier", 1.0))
    var adjusted := {}
    for raw_key in effects.keys():
        var key := String(raw_key)
        var value := int(effects[raw_key])
        if value == 0:
            adjusted[key] = 0
            continue
        var multiplier := positive_multiplier if value > 0 else drawback_multiplier
        var affinity_value := roundi(float(value) * multiplier)
        if affinity_value == 0:
            affinity_value = 1 if value > 0 else -1
        adjusted[key] = affinity_value
    return adjusted


static func choice_has_affinity(choice: Dictionary, candidate: Dictionary) -> bool:
    var affinity_tags: Array = candidate.get("match_affinity_tags", [])
    for raw_tag in choice.get("tags", []):
        if affinity_tags.has(String(raw_tag)):
            return true
    return false


static func choice_skill(choice: Dictionary, tag_definitions: Array, player_stats: Dictionary) -> float:
    var stat_ids := related_stat_ids(choice, tag_definitions, player_stats)
    if stat_ids.is_empty():
        return float(DEFAULT_SCALING["reference_stat"])
    var total := 0.0
    for stat_id in stat_ids:
        total += clampf(float(player_stats.get(stat_id, 0)), 0.0, 100.0)
    return total / float(stat_ids.size())


static func related_stat_ids(choice: Dictionary, tag_definitions: Array, player_stats: Dictionary) -> Array[String]:
    var result: Array[String] = []
    for raw_tag in choice.get("tags", []):
        var tag_id := String(raw_tag)
        for definition in tag_definitions:
            if typeof(definition) != TYPE_DICTIONARY or String(definition.get("id", "")) != tag_id:
                continue
            for raw_stat_id in definition.get("uses_stats", []):
                _append_unique_stat(result, String(raw_stat_id), player_stats)
            break
        # Some choices use a player stat itself as a lightweight tag.
        _append_unique_stat(result, tag_id, player_stats)

    # Custom choices without a registered tag scale from their stat requirements.
    if result.is_empty():
        for raw_key in choice.get("requirements", {}).keys():
            var stat_id := String(raw_key).trim_prefix("min_")
            _append_unique_stat(result, stat_id, player_stats)
    return result


static func _append_unique_stat(result: Array[String], stat_id: String, player_stats: Dictionary) -> void:
    if player_stats.has(stat_id) and not result.has(stat_id):
        result.append(stat_id)


static func _effect_multiplier(skill: float, is_positive: bool, scaling: Dictionary) -> float:
    var settings := DEFAULT_SCALING.duplicate()
    settings.merge(scaling, true)
    var reference := clampf(float(settings["reference_stat"]), 1.0, 99.0)
    var low := float(settings["positive_min_multiplier"] if is_positive else settings["drawback_max_multiplier"])
    var high := float(settings["positive_max_multiplier"] if is_positive else settings["drawback_min_multiplier"])
    if skill <= reference:
        return lerpf(low, 1.0, clampf(skill / reference, 0.0, 1.0))
    return lerpf(1.0, high, clampf((skill - reference) / (100.0 - reference), 0.0, 1.0))


static func _apply_soft_requirement_scaling(effects: Dictionary, evaluation: Dictionary, scaling: Dictionary) -> Dictionary:
    if not bool(evaluation.get("has_soft_requirements", false)):
        return effects
    var settings := DEFAULT_SCALING.duplicate()
    settings.merge(scaling, true)
    var ratio := clampf(float(evaluation.get("ratio", 1.0)), 0.0, 1.0)
    if ratio >= 1.0:
        return effects
    var reversal_below := clampf(float(settings["soft_requirement_reversal_below"]), 0.05, 0.95)
    var positive_floor := clampf(float(settings["soft_requirement_positive_floor"]), 0.0, 1.0)
    var reversal_max := clampf(float(settings["soft_requirement_reversal_max"]), 0.05, 2.0)
    var drawback_max := maxf(1.0, float(settings["soft_requirement_drawback_max"]))
    var adjusted: Dictionary = {}
    for raw_key in effects.keys():
        var key := String(raw_key)
        var value := int(effects[raw_key])
        if value > 0 and ratio < reversal_below:
            var reversal_progress := clampf(ratio / reversal_below, 0.0, 1.0)
            var reversal_multiplier := lerpf(reversal_max, 0.15, reversal_progress)
            adjusted[key] = -maxi(1, roundi(float(value) * reversal_multiplier))
        elif value > 0:
            var recovery_progress := clampf((ratio - reversal_below) / (1.0 - reversal_below), 0.0, 1.0)
            # The exact reversal boundary is a neutral buffer instead of jumping
            # directly from at least -1 to at least +1.
            adjusted[key] = maxi(0, roundi(float(value) * lerpf(positive_floor, 1.0, recovery_progress)))
        elif value < 0:
            adjusted[key] = mini(-1, roundi(float(value) * lerpf(drawback_max, 1.0, ratio)))
        else:
            adjusted[key] = 0
    return adjusted
