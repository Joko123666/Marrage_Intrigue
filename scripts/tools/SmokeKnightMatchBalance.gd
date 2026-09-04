extends SceneTree

const CHOICE_CALCULATOR := preload("res://scripts/systems/MatchChoiceCalculator.gd")
const OUTCOME_CALCULATOR := preload("res://scripts/systems/MatchOutcomeCalculator.gd")


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var data_manager := root.get_node("/root/DataManager")
    var game_state := root.get_node("/root/GameState")
    data_manager.call("load_all")
    var initial: Dictionary = data_manager.call("get_table", "player_initial_state")
    var config: Dictionary = data_manager.call("get_table", "match_config")
    var tag_definitions: Array = data_manager.call("get_table", "choice_tags").get("choice_tags", [])
    var results: Array[String] = []
    for candidate_id in ["candidate_knight_tutorial_adrien", "candidate_knight_cedric", "candidate_knight_rohan"]:
        game_state.call("start_new_game", initial)
        var candidate: Dictionary = data_manager.call("find_by_id", "candidate_profiles", "candidate_profiles", candidate_id)
        assert(not candidate.is_empty())
        var stats: Dictionary = game_state.get("player").get("stats", {})
        for raw_stat_id in candidate.get("minimums", {}).keys():
            var stat_id := String(raw_stat_id)
            stats[stat_id] = maxi(int(stats.get(stat_id, 0)), int(candidate.get("minimums", {}).get(stat_id, 0)))
        game_state.get("player")["stats"] = stats
        assert(int(stats.get("social", 0)) == 0)
        assert(int(stats.get("culture", 0)) <= 8)

        var choices: Array = candidate.get("unique_match_choices", [])
        assert(not choices.is_empty())
        var choice: Dictionary = choices[0]
        assert(CHOICE_CALCULATOR.choice_has_affinity(choice, candidate))
        var rules := OUTCOME_CALCULATOR.rules_for_candidate(candidate, config)
        var effects := CHOICE_CALCULATOR.calculate_effects(choice, tag_definitions, stats, config.get("default_match", {}).get("choice_stat_scaling", {}))
        effects = CHOICE_CALCULATOR.apply_candidate_affinity(effects, choice, candidate, rules)
        var prep := int(game_state.call("candidate_preparation_bonus", candidate))
        assert(int(rules.get("success_threshold", 0)) == 50)
        assert(_effect_sum(effects) > 0)
        results.append("%s prep=%d first=%s" % [candidate_id, prep, effects])

    var baron: Dictionary = data_manager.call("find_by_id", "candidate_profiles", "candidate_profiles", "candidate_baron_lucas")
    var baron_rules := OUTCOME_CALCULATOR.rules_for_candidate(baron, config)
    assert(int(baron_rules.get("success_threshold", 0)) == 62)
    assert(int(baron_rules.get("critical_fail_axis_below", 0)) == 10)

    var packed: PackedScene = load("res://scenes/main/Main.tscn")
    var scene: Control = packed.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame

    # 동일한 화제만 8번 되풀이하면 기사 튜토리얼도 더 이상 통과할 수 없어야 한다.
    game_state.call("start_new_game", initial)
    var adrien: Dictionary = data_manager.call("find_by_id", "candidate_profiles", "candidate_profiles", "candidate_knight_tutorial_adrien")
    _meet_candidate_minimums(game_state, adrien)
    scene.call("_start_match", adrien)
    var repeated_choice: Dictionary = adrien.get("unique_match_choices", [])[0]
    var first_effects: Dictionary = scene.call("_match_choice_effects", repeated_choice)
    scene.call("_apply_match_choice", repeated_choice)
    var second_effects: Dictionary = scene.call("_match_choice_effects", repeated_choice)
    assert(_effect_sum(second_effects) < _effect_sum(first_effects))
    scene.call("_apply_match_choice", repeated_choice)
    assert(String(game_state.get("current_match").get("last_reaction", "")).contains("같은 화제"))
    for _turn in range(6):
        scene.call("_apply_match_choice", repeated_choice)
    await process_frame
    var repeated_match: Dictionary = game_state.get("current_match")
    assert(String(repeated_match.get("result", "")) == "failure")
    assert(int(Dictionary(repeated_match.get("choice_usage", {})).get(String(repeated_choice.get("id", "")), 0)) == 8)
    results.append("repeat_only=failure score=%d" % int(repeated_match.get("final_score", 0)))

    # 매 턴 현재 축에 가장 유리한 화제를 고르면 여러 화제를 섞어 기사 루프를 통과한다.
    for candidate_id in ["candidate_knight_tutorial_adrien", "candidate_knight_cedric", "candidate_knight_rohan"]:
        game_state.call("start_new_game", initial)
        var candidate: Dictionary = data_manager.call("find_by_id", "candidate_profiles", "candidate_profiles", candidate_id)
        _meet_candidate_minimums(game_state, candidate)
        scene.call("_start_match", candidate)
        for _turn in range(8):
            var choice := _best_match_choice(scene, candidate, config, game_state)
            assert(not choice.is_empty())
            scene.call("_apply_match_choice", choice)
        await process_frame
        var actual_match: Dictionary = game_state.get("current_match")
        assert(String(actual_match.get("result", "")) == "success")
        assert(Array(actual_match.get("choice_history", [])).size() == 8)
        assert(Dictionary(actual_match.get("choice_usage", {})).size() >= 3)
        results.append("%s actual=%d topics=%d" % [candidate_id, int(actual_match.get("final_score", 0)), Dictionary(actual_match.get("choice_usage", {})).size()])
    print("KNIGHT_MATCH_BALANCE_OK ", " | ".join(results))
    scene.queue_free()
    await process_frame
    quit()


func _meet_candidate_minimums(game_state: Node, candidate: Dictionary) -> void:
    var stats: Dictionary = game_state.get("player").get("stats", {})
    for raw_stat_id in candidate.get("minimums", {}).keys():
        var stat_id := String(raw_stat_id)
        stats[stat_id] = maxi(int(stats.get(stat_id, 0)), int(candidate.get("minimums", {}).get(stat_id, 0)))
    game_state.get("player")["stats"] = stats


func _best_match_choice(scene: Control, candidate: Dictionary, config: Dictionary, game_state: Node) -> Dictionary:
    var best: Dictionary = {}
    var best_score := -999999
    var best_usage := 999999
    var prep := int(game_state.call("candidate_preparation_bonus", candidate))
    for raw_choice in scene.call("_all_match_choices", candidate):
        if typeof(raw_choice) != TYPE_DICTIONARY:
            continue
        var choice: Dictionary = raw_choice
        var axes: Dictionary = game_state.get("current_match").get("axes", {}).duplicate(true)
        var effects: Dictionary = scene.call("_match_choice_effects", choice)
        for raw_axis_id in effects.keys():
            var axis_id := String(raw_axis_id)
            axes[axis_id] = clampi(int(axes.get(axis_id, 0)) + int(effects[raw_axis_id]), 0, 100)
        var outcome := OUTCOME_CALCULATOR.evaluate(axes, candidate, config, prep)
        var score := int(outcome.get("score", 0))
        var usage := int(scene.call("_match_choice_usage_count", choice))
        if score > best_score or (score == best_score and usage < best_usage):
            best = choice
            best_score = score
            best_usage = usage
    return best


func _effect_sum(effects: Dictionary) -> int:
    var total := 0
    for value in effects.values():
        total += int(value)
    return total
