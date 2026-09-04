class_name MatchOutcomeCalculator
extends RefCounted


static func rules_for_candidate(candidate: Dictionary, config: Dictionary) -> Dictionary:
    var rules: Dictionary = config.get("default_match", {}).duplicate(true)
    var rank_rules: Dictionary = config.get("rank_rules", {})
    var rank_id := String(candidate.get("rank", ""))
    if rank_rules.has(rank_id):
        rules.merge(Dictionary(rank_rules.get(rank_id, {})), true)
    if candidate.has("match_rules"):
        rules.merge(Dictionary(candidate.get("match_rules", {})), true)
    return rules


static func evaluate(axes: Dictionary, candidate: Dictionary, config: Dictionary, preparation_bonus: int) -> Dictionary:
    var rules := rules_for_candidate(candidate, config)
    var weight_overrides: Dictionary = rules.get("axis_weights", {})
    var critical_axis_ids: Array = rules.get("critical_axes", [])
    var critical_below := int(rules.get("critical_fail_axis_below", 10))
    var weighted_total := 0.0
    var weight_sum := 0.0
    var critical_axes: Array[String] = []
    for raw_definition in config.get("axes", []):
        if typeof(raw_definition) != TYPE_DICTIONARY:
            continue
        var definition: Dictionary = raw_definition
        var axis_id := String(definition.get("id", ""))
        var weight := float(weight_overrides.get(axis_id, definition.get("success_weight", 1.0)))
        var value := int(axes.get(axis_id, 0))
        if weight > 0.0:
            weighted_total += float(value) * weight
            weight_sum += weight
        var checks_critical := critical_axis_ids.is_empty() or critical_axis_ids.has(axis_id)
        if checks_critical and value < critical_below:
            critical_axes.append(axis_id)
    var raw_score := int(weighted_total / maxf(weight_sum, 1.0))
    var score := raw_score + preparation_bonus
    var threshold := int(rules.get("success_threshold", 62))
    return {
        "success": score >= threshold and critical_axes.is_empty(),
        "score": score,
        "raw_score": raw_score,
        "threshold": threshold,
        "critical": not critical_axes.is_empty(),
        "critical_axes": critical_axes,
        "rules": rules,
    }
