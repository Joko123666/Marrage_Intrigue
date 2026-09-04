extends SceneTree

const CALCULATOR := preload("res://scripts/systems/MatchChoiceCalculator.gd")


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var choice := {
        "tags": ["wild"],
        "effects": {"interest": 8, "comfort": -4},
    }
    var definitions: Array = [{"id": "wild", "uses_stats": ["wildness"]}]
    var low: Dictionary = CALCULATOR.calculate_effects(choice, definitions, {"wildness": 0})
    var reference: Dictionary = CALCULATOR.calculate_effects(choice, definitions, {"wildness": 25})
    var high: Dictionary = CALCULATOR.calculate_effects(choice, definitions, {"wildness": 100})

    assert(int(low["interest"]) < int(reference["interest"]))
    assert(int(reference["interest"]) < int(high["interest"]))
    assert(abs(int(low["comfort"])) > abs(int(reference["comfort"])))
    assert(abs(int(reference["comfort"])) > abs(int(high["comfort"])))
    assert(CALCULATOR.related_stat_ids({"tags": ["beauty"]}, [], {"beauty": 50}) == ["beauty"])
    assert(CALCULATOR.related_stat_ids({"requirements": {"culture": 20}}, [], {"culture": 50}) == ["culture"])

    var soft_choice := {
        "tags": ["etiquette"],
        "requirements": {"etiquette": 20},
        "effects": {"comfort": 6, "face": 4, "favor": -2},
    }
    var soft_defs: Array = [{"id": "etiquette", "uses_stats": ["etiquette"]}]
    var severe: Dictionary = CALCULATOR.calculate_effects(soft_choice, soft_defs, {"etiquette": 4})
    var boundary: Dictionary = CALCULATOR.calculate_effects(soft_choice, soft_defs, {"etiquette": 8})
    var partial: Dictionary = CALCULATOR.calculate_effects(soft_choice, soft_defs, {"etiquette": 12})
    var ready: Dictionary = CALCULATOR.calculate_effects(soft_choice, soft_defs, {"etiquette": 20})
    assert(int(severe["comfort"]) < 0)
    assert(int(severe["face"]) < 0)
    assert(int(boundary["comfort"]) == 0)
    assert(int(boundary["face"]) == 0)
    assert(abs(int(severe["favor"])) > abs(int(ready["favor"])))
    assert(int(partial["comfort"]) > 0)
    assert(int(partial["comfort"]) < int(ready["comfort"]))
    var severe_evaluation: Dictionary = CALCULATOR.soft_requirement_evaluation(soft_choice, {"etiquette": 4})
    var partial_evaluation: Dictionary = CALCULATOR.soft_requirement_evaluation(soft_choice, {"etiquette": 12})
    assert(String(severe_evaluation["state"]) == "backfire")
    assert(String(partial_evaluation["state"]) == "reduced")

    var data_manager: Node = root.get_node("/root/DataManager")
    var match_config: Dictionary = data_manager.call("get_table", "match_config")
    var scaling: Dictionary = match_config.get("default_match", {}).get("choice_stat_scaling", {})
    var all_definitions: Array = data_manager.call("get_table", "choice_tags").get("choice_tags", [])
    var base_stats: Dictionary = data_manager.call("get_table", "player_initial_state").get("stats", {}).duplicate(true)
    var choices: Array = match_config.get("choice_examples", []).duplicate()
    for candidate in data_manager.call("get_table", "candidate_profiles").get("candidate_profiles", []):
        if typeof(candidate) == TYPE_DICTIONARY:
            choices.append_array(Dictionary(candidate).get("unique_match_choices", []))
    var checked := 0
    for candidate_choice in choices:
        if typeof(candidate_choice) != TYPE_DICTIONARY or not _has_soft_requirement(candidate_choice, base_stats):
            continue
        checked += 1
        _check_choice_boundaries(Dictionary(candidate_choice), base_stats, all_definitions, scaling)
    assert(checked == 8)

    print("MATCH_CHOICE_SCALING_SMOKE_OK choices=%d low=%s reference=%s high=%s severe=%s boundary=%s partial=%s ready=%s" % [checked, low, reference, high, severe, boundary, partial, ready])
    quit()


func _check_choice_boundaries(choice: Dictionary, base_stats: Dictionary, definitions: Array, scaling: Dictionary) -> void:
    var modes := ["below_40", "at_40", "below_100", "at_100"]
    var expected_states := ["backfire", "reduced", "reduced", "stable"]
    for index in modes.size():
        var stats := _stats_for_mode(choice, base_stats, String(modes[index]))
        var evaluation: Dictionary = CALCULATOR.soft_requirement_evaluation(choice, stats, scaling)
        assert(String(evaluation.get("state", "")) == String(expected_states[index]))
        var effects: Dictionary = CALCULATOR.calculate_effects(choice, definitions, stats, scaling)
        assert(effects == CALCULATOR.calculate_effects(choice, definitions, stats, scaling))
        for raw_axis in Dictionary(choice.get("effects", {})).keys():
            var base_value := int(Dictionary(choice.get("effects", {}))[raw_axis])
            var value := int(effects.get(raw_axis, 0))
            if base_value > 0:
                if index == 0:
                    assert(value < 0)
                elif index == 1:
                    assert(value == 0)
                else:
                    assert(value > 0)
            elif base_value < 0:
                assert(value < 0)


func _stats_for_mode(choice: Dictionary, base_stats: Dictionary, mode: String) -> Dictionary:
    var stats := base_stats.duplicate(true)
    for raw_key in Dictionary(choice.get("requirements", {})).keys():
        var stat_id := String(raw_key).trim_prefix("min_")
        var required_value = Dictionary(choice.get("requirements", {}))[raw_key]
        if not stats.has(stat_id) or (typeof(required_value) != TYPE_INT and typeof(required_value) != TYPE_FLOAT):
            continue
        var required := float(required_value)
        match mode:
            "below_40": stats[stat_id] = maxi(0, ceili(required * 0.4) - 1)
            "at_40": stats[stat_id] = ceili(required * 0.4)
            "below_100": stats[stat_id] = maxi(ceili(required * 0.4), ceili(required) - 1)
            _: stats[stat_id] = ceili(required)
    return stats


func _has_soft_requirement(choice: Dictionary, stats: Dictionary) -> bool:
    for raw_key in Dictionary(choice.get("requirements", {})).keys():
        var stat_id := String(raw_key).trim_prefix("min_")
        var value = Dictionary(choice.get("requirements", {}))[raw_key]
        if stats.has(stat_id) and (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and float(value) > 0.0:
            return true
    return false
