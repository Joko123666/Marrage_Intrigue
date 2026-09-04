extends SceneTree


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var packed: PackedScene = load("res://scenes/main/Main.tscn")
    var scene: Control = packed.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame
    assert(int(scene.call("_minimum_wedding_cash")) == 8)
    assert(String(scene.call("_name_for", "access_to_household")) == "저택 접근권")
    assert(String(scene.call("_name_for", "wildness")) != "wildness")
    var data_manager := root.get_node("/root/DataManager")
    var game_state := root.get_node("/root/GameState")
    for npc_id in ["npc_knight_adrien", "npc_knight_cedric", "npc_knight_rohan"]:
        var portrait_npc: Dictionary = data_manager.call("find_by_id", "npcs", "characters", npc_id)
        var match_portraits: Dictionary = portrait_npc.get("match_portraits", {})
        for expression in ["neutral", "favorable", "wary"]:
            var portrait_path := String(match_portraits.get(expression, ""))
            if portrait_path == "" or not ResourceLoader.exists(portrait_path):
                push_error("missing match portrait: %s/%s -> %s" % [npc_id, expression, portrait_path])
                quit(1)
                return
    var candidate: Dictionary = data_manager.call("find_by_id", "candidate_profiles", "candidate_profiles", "candidate_knight_tutorial_adrien")
    scene.call("_start_match", candidate)
    await process_frame
    assert(scene.get("current_screen") == "match")
    assert(bool(scene.get("match_backdrop").visible))
    assert(not bool(scene.get("header_label").visible))
    assert(not bool(scene.get("nav_bar").visible))
    assert(not bool(scene.get("log_frame").visible))
    assert(scene.get("content").find_child("MatchBattleShell", true, false) != null)
    assert(scene.find_child("MatchMomentumRibbon", true, false) != null)
    var polite_choice: Button = scene.find_child("MatchChoice_match_choice_polite_listen", true, false)
    if polite_choice == null:
        push_error("polite match choice button was not created")
        quit(1)
        return
    if polite_choice.disabled:
        push_error("soft stat requirement should not disable a match choice")
        quit(1)
        return
    if not polite_choice.text.contains("효과↓") and not polite_choice.text.contains("역효과"):
        push_error("soft stat requirement warning was not shown: " + polite_choice.text)
        quit(1)
        return
    if not polite_choice.text.begins_with("[") or not polite_choice.text.contains("]"):
        push_error("visible numeric shortcut hint was not shown: " + polite_choice.text)
        quit(1)
        return
    DisplayServer.window_set_size(Vector2i(640, 760))
    root.size = Vector2i(640, 760)
    await process_frame
    await process_frame
    scene.call("_show_match")
    await process_frame
    polite_choice = scene.find_child("MatchChoice_match_choice_polite_listen", true, false)
    if polite_choice == null or not polite_choice.text.contains("관련") or not polite_choice.text.contains("권장"):
        push_error("mobile match choice did not expose inline skill context")
        quit(1)
        return
    DisplayServer.window_set_size(Vector2i(1280, 720))
    root.size = Vector2i(1280, 720)
    await process_frame
    await process_frame
    scene.call("_show_match")
    await process_frame
    polite_choice = scene.find_child("MatchChoice_match_choice_polite_listen", true, false)

    var choices: Array = data_manager.call("get_table", "match_config").get("choice_examples", [])
    var polite_listen: Dictionary = choices[1]
    var reduced_dialogue := String(scene.call("_match_dialogue_for_choice", polite_listen, "reduced"))
    var backfire_dialogue := String(scene.call("_match_dialogue_for_choice", polite_listen, "backfire"))
    if reduced_dialogue == backfire_dialogue or not reduced_dialogue.contains("예를 조금 놓쳤다면"):
        push_error("reduced match dialogue was not selected: " + reduced_dialogue)
        quit(1)
        return
    if not backfire_dialogue.contains("실례했습니다"):
        push_error("backfire match dialogue was not selected: " + backfire_dialogue)
        quit(1)
        return
    var transition_values := [5, 6, 15, 14, 5]
    var transition_states := ["backfire", "reduced", "stable", "reduced", "backfire"]
    var transition_labels := ["역효과", "효과↓", "충분", "효과↓", "역효과"]
    for index in transition_values.size():
        var current_etiquette := int(game_state.call("get_stat", "etiquette"))
        game_state.call("change_stat", "etiquette", int(transition_values[index]) - current_etiquette)
        await process_frame
        await process_frame
        polite_choice = scene.find_child("MatchChoice_match_choice_polite_listen", true, false)
        assert(polite_choice != null)
        assert(polite_choice.text.contains(String(transition_labels[index])))
        var preview: Dictionary = scene.call("_match_choice_effects", polite_listen)
        var expected_scroll := -1
        if index == 0:
            var match_scroll: ScrollContainer = scene.get("main_scroll")
            match_scroll.scroll_vertical = 420
            await process_frame
            expected_scroll = match_scroll.scroll_vertical
        scene.call("_apply_match_choice", polite_listen)
        await process_frame
        await process_frame
        if expected_scroll >= 0:
            assert(abs(int(scene.get("main_scroll").scroll_vertical) - expected_scroll) <= 2)
        var dialogue_state: Dictionary = game_state.get("current_match")
        assert(String(dialogue_state.get("last_readiness_state", "")) == String(transition_states[index]))
        assert(Dictionary(dialogue_state.get("last_effects", {})) == preview)
        assert(String(dialogue_state.get("last_dialogue", "")) == String(scene.call("_match_dialogue_for_choice", polite_listen, transition_states[index], index)))
        if String(transition_states[index]) == "backfire":
            assert(String(dialogue_state.get("last_reaction", "")).contains("온기"))
        var turn_flow: Label = scene.find_child("MatchTurnFlow", true, false)
        var candidate_reaction: Label = scene.find_child("MatchCandidateReactionState", true, false)
        assert(turn_flow != null and turn_flow.text.contains("교섭 흐름"))
        assert(candidate_reaction != null and candidate_reaction.text.begins_with("반응 ·"))
        var candidate_portrait: Control = scene.find_child("MatchCandidatePortrait", true, false)
        var turn_net := 0
        for effect_value in Dictionary(dialogue_state.get("last_effects", {})).values():
            turn_net += int(effect_value)
        var atmosphere_snapshot: Dictionary = scene.get("match_backdrop").call("feedback_snapshot")
        assert(int(atmosphere_snapshot.get("net_effect", 999)) == turn_net)
        assert(int(atmosphere_snapshot.get("repeat_level", -1)) == index)
        assert(String(atmosphere_snapshot.get("dominant_axis", "")) != "")
        var momentum_snapshot: Dictionary = scene.find_child("MatchMomentumRibbon", true, false).call("state_snapshot")
        assert(int(momentum_snapshot.get("net_effect", 999)) == turn_net)
        assert(int(momentum_snapshot.get("repeat_level", -1)) == index)
        var expected_expression := "neutral"
        if String(dialogue_state.get("last_readiness_state", "")) == "backfire" or turn_net < 0:
            expected_expression = "wary"
        elif turn_net > 0:
            expected_expression = "favorable"
        assert(candidate_portrait != null)
        assert(String(candidate_portrait.get_meta("match_expression", "")) == expected_expression)
        if index == 0:
            var face_delta: Label = scene.find_child("MatchAxisDelta_face", true, false)
            assert(face_delta != null and face_delta.text.contains("▼"))
        var exported: Dictionary = game_state.call("export_state")
        game_state.call("import_state", exported)
        var restored: Dictionary = game_state.get("current_match")
        for key in ["last_readiness_state", "last_dialogue", "last_reaction", "last_effects", "choice_history", "choice_usage"]:
            assert(restored.get(key) == dialogue_state.get(key))

    var raw_honesty: Dictionary = choices[0]
    var failing_match: Dictionary = game_state.get("current_match")
    failing_match["turns_left"] = 1
    failing_match["axes"] = {"favor": 0, "interest": 0, "trust": 0, "comfort": 0, "face": 0, "political_value": 0}
    game_state.set("current_match", failing_match)
    scene.call("_apply_match_choice", raw_honesty)
    await process_frame
    assert(String(game_state.get("current_match").get("result", "")) == "failure")
    assert(scene.get("current_screen") == "match")
    scene.call("_continue_match_result")
    await process_frame
    assert(scene.get("current_screen") == "candidates")
    assert(not bool(scene.get("match_backdrop").visible))
    assert(bool(scene.get("header_label").visible))

    scene.call("_start_match", candidate)
    var winning_match: Dictionary = game_state.get("current_match")
    winning_match["turns_left"] = 1
    winning_match["axes"] = {"favor": 80, "interest": 80, "trust": 80, "comfort": 80, "face": 80, "political_value": 80}
    game_state.set("current_match", winning_match)
    scene.call("_apply_match_choice", raw_honesty)
    await process_frame
    assert(String(game_state.get("current_match").get("result", "")) == "success")
    assert(scene.get("current_screen") == "match")
    scene.call("_continue_match_result")
    await process_frame
    assert(scene.get("current_screen") == "wedding")
    assert(String(scene.call("_candidate_display_name", candidate)) != String(candidate.get("id", "")))
    print("MATCH_BATTLE_UI_SMOKE_OK")
    quit()
