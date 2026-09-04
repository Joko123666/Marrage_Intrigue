extends SceneTree

func _init() -> void:
    call_deferred("_capture")

func _capture() -> void:
    DisplayServer.window_set_size(Vector2i(1280, 720))
    root.size = Vector2i(1280, 720)
    var packed_scene: PackedScene = load("res://scenes/main/Main.tscn")
    var scene: Node = packed_scene.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame
    await create_timer(0.2).timeout
    var tmp_dir := ProjectSettings.globalize_path("res://tmp")
    DirAccess.make_dir_recursive_absolute(tmp_dir)
    var feedback: Control = scene.get("feedback_layer")

    await _save_capture(tmp_dir, "dashboard")
    scene.call("_request_new_game")
    await process_frame
    await _save_capture(tmp_dir, "confirmation_new_game")
    feedback.call("_close_confirmation")
    await process_frame
    scene.call("_queue_dashboard_action", "street_errands")
    scene.call("_queue_dashboard_action", "practice_etiquette")
    scene.call("_queue_dashboard_action", "rest_and_recover")
    await process_frame
    await _save_capture(tmp_dir, "dashboard_schedule")
    scene.call("_clear_dashboard_schedule")
    await process_frame
    DisplayServer.window_set_size(Vector2i(820, 720))
    root.size = Vector2i(820, 720)
    await process_frame
    await process_frame
    scene.call("_show_dashboard")
    await process_frame
    await _save_capture(tmp_dir, "dashboard_compact")
    DisplayServer.window_set_size(Vector2i(640, 760))
    root.size = Vector2i(640, 760)
    await process_frame
    await process_frame
    scene.call("_show_dashboard")
    await process_frame
    await _save_capture(tmp_dir, "dashboard_mobile")
    feedback.call("show_time_passage", {
        "type": "time_passage", "from_week": 3, "to_week": 4,
        "from_year": 1, "from_month": 1, "year": 1, "month": 1,
        "weeks": 1, "age": 14, "crossed_month": false, "crossed_year": false,
    })
    await process_frame
    await _save_capture(tmp_dir, "time_passage_mobile")
    feedback.call("_dismiss_active_sequence")
    await process_frame
    DisplayServer.window_set_size(Vector2i(1280, 720))
    root.size = Vector2i(1280, 720)
    await process_frame
    await process_frame
    scene.call("_show_free_actions")
    await process_frame
    await _save_capture(tmp_dir, "free")
    var data_manager: Node = root.get_node("/root/DataManager")
    var training_action: Dictionary = data_manager.call("find_by_id", "free_actions", "actions", "practice_mask")
    root.get_node("/root/ActionResolver").call("run_action", training_action)
    await process_frame
    await _save_capture(tmp_dir, "time_passage")
    feedback.call("_dismiss_active_sequence")
    await process_frame
    await process_frame
    await _save_capture(tmp_dir, "free_action_result")
    await _drain_feedback_sequence(feedback)
    feedback.call("show_action_result", {
        "title": "교양 공부", "kicker": "육성 기록", "category": "self_improvement", "weeks": 3,
        "detail": "촛불이 짧아질 때까지 책과 기록을 읽었습니다. 낯설던 궁정의 화제가 이제는 대화의 실마리로 보입니다.",
        "effects": {"culture": 4, "impulse_control": 1, "fatigue": 3},
        "backdrop": "res://assets/art/actions/action_study_chamber.png",
    })
    await process_frame
    await _save_capture(tmp_dir, "free_action_result_study")
    await _drain_feedback_sequence(feedback)
    feedback.call("show_action_result", {
        "title": "소문 조사", "kicker": "정보 활동", "category": "rumor", "weeks": 1,
        "detail": "하인들의 뒷말과 시장의 풍문을 한데 맞췄습니다. 누가 누구를 두려워하는지 윤곽이 드러났습니다.",
        "effects": {"information": 2, "cash": -1, "fatigue": 2},
        "backdrop": "res://assets/art/actions/action_market_alley.png",
    })
    await process_frame
    await _save_capture(tmp_dir, "free_action_result_market")
    await _drain_feedback_sequence(feedback)
    DisplayServer.window_set_size(Vector2i(820, 720))
    root.size = Vector2i(820, 720)
    await process_frame
    await process_frame
    scene.call("_show_free_actions")
    await process_frame
    await _save_capture(tmp_dir, "free_compact")
    DisplayServer.window_set_size(Vector2i(1280, 720))
    root.size = Vector2i(1280, 720)
    await process_frame
    await process_frame
    scene.call("_show_shop")
    await process_frame
    await _save_capture(tmp_dir, "shop")
    scene.call("_show_characters")
    await process_frame
    await _save_capture(tmp_dir, "characters")
    scene.set("character_filter", "rumor")
    scene.call("_show_characters")
    await process_frame
    await _save_capture(tmp_dir, "characters_rumor_filter")
    scene.set("character_filter", "all")
    var game_state: Node = root.get_node("/root/GameState")
    var time_manager: Node = root.get_node("/root/TimeManager")
    game_state.call("unlock_candidates_for_rank", "knight", 65, 3)
    scene.call("_show_candidates")
    await process_frame
    await _save_capture(tmp_dir, "candidates")
    scene.set("candidate_sort_mode", "quality")
    scene.call("_show_candidates")
    await process_frame
    await _save_capture(tmp_dir, "candidates_quality_sort")
    scene.set("candidate_sort_mode", "rank")
    DisplayServer.window_set_size(Vector2i(820, 720))
    root.size = Vector2i(820, 720)
    await process_frame
    await process_frame
    scene.call("_show_candidates")
    await process_frame
    await _save_capture(tmp_dir, "candidates_compact")
    DisplayServer.window_set_size(Vector2i(640, 760))
    root.size = Vector2i(640, 760)
    await process_frame
    await process_frame
    scene.call("_show_candidates")
    await process_frame
    await _save_capture(tmp_dir, "candidates_mobile")
    DisplayServer.window_set_size(Vector2i(1280, 720))
    root.size = Vector2i(1280, 720)
    await process_frame
    await process_frame
    var candidate: Dictionary = data_manager.call("find_by_id", "candidate_profiles", "candidate_profiles", "candidate_knight_tutorial_adrien")
    var match_config: Dictionary = data_manager.call("get_table", "match_config")
    var choices: Array = match_config.get("choice_examples", [])
    scene.call("_start_match", candidate)
    if choices.size() > 1:
        var capture_player: Dictionary = game_state.get("player")
        var capture_stats: Dictionary = capture_player.get("stats", {}).duplicate(true)
        capture_stats["etiquette"] = 2
        capture_player["stats"] = capture_stats
        game_state.set("player", capture_player)
        scene.call("_apply_match_choice", choices[1])
    await process_frame
    await _save_capture(tmp_dir, "match")
    var match_scroll: ScrollContainer = scene.get("main_scroll")
    match_scroll.scroll_vertical = 100000
    await process_frame
    await process_frame
    await _save_capture(tmp_dir, "match_choices")
    match_scroll.scroll_vertical = 0
    var boundary_etiquette := int(game_state.call("get_stat", "etiquette"))
    game_state.call("change_stat", "etiquette", 6 - boundary_etiquette)
    await process_frame
    await process_frame
    if choices.size() > 1:
        scene.call("_apply_match_choice", choices[1])
    await process_frame
    await _save_capture(tmp_dir, "match_boundary")
    game_state.call("clear_current_match")
    scene.call("_start_match", candidate)
    var favorable_etiquette := int(game_state.call("get_stat", "etiquette"))
    game_state.call("change_stat", "etiquette", 15 - favorable_etiquette)
    await process_frame
    await process_frame
    if choices.size() > 1:
        scene.call("_apply_match_choice", choices[1])
    await process_frame
    await _save_capture(tmp_dir, "match_favorable")
    DisplayServer.window_set_size(Vector2i(640, 760))
    root.size = Vector2i(640, 760)
    await process_frame
    await process_frame
    scene.call("_show_match")
    await process_frame
    await _save_capture(tmp_dir, "match_mobile")
    match_scroll.scroll_vertical = 100000
    await process_frame
    await process_frame
    await _save_capture(tmp_dir, "match_choices_mobile")
    match_scroll.scroll_vertical = 0
    DisplayServer.window_set_size(Vector2i(1280, 720))
    root.size = Vector2i(1280, 720)
    await process_frame
    await process_frame
    var winning_match: Dictionary = game_state.get("current_match")
    winning_match["turns_left"] = 1
    winning_match["axes"] = {"favor": 80, "interest": 80, "trust": 80, "comfort": 80, "face": 80, "political_value": 80}
    game_state.set("current_match", winning_match)
    if not choices.is_empty():
        scene.call("_apply_match_choice", choices[0])
    await process_frame
    await _save_capture(tmp_dir, "match_result_success")
    DisplayServer.window_set_size(Vector2i(1280, 720))
    root.size = Vector2i(1280, 720)
    await process_frame
    await process_frame
    game_state.set("current_match", {})
    game_state.call("set_flag", "match_success_pending", true)
    var wedding_flags: Dictionary = game_state.get("flags").duplicate(true)
    wedding_flags["pending_spouse_candidate"] = "candidate_knight_tutorial_adrien"
    game_state.set("flags", wedding_flags)
    var wedding_player: Dictionary = game_state.get("player").duplicate(true)
    wedding_player["flags"] = wedding_flags
    game_state.set("player", wedding_player)
    game_state.call("change_stat", "cash", 40)
    scene.call("_show_wedding")
    await process_frame
    await _save_capture(tmp_dir, "wedding")
    game_state.call("set_flag", "match_success_pending", false)
    wedding_flags = game_state.get("flags").duplicate(true)
    wedding_flags.erase("pending_spouse_candidate")
    game_state.set("flags", wedding_flags)
    wedding_player = game_state.get("player").duplicate(true)
    wedding_player["flags"] = wedding_flags
    game_state.set("player", wedding_player)
    game_state.call("change_stat", "status", 1)
    game_state.call("unlock_accessible_candidates", 55, 3)
    scene.call("_show_candidates")
    await process_frame
    await _save_capture(tmp_dir, "candidates_accessible")
    game_state.set("known_candidates", {})
    game_state.call("unlock_candidates_for_rank", "baron", 65, 3)
    scene.call("_show_candidates")
    await process_frame
    await _save_capture(tmp_dir, "candidates_baron")
    game_state.set("known_candidates", {})
    game_state.call("unlock_candidates_for_rank", "viscount", 65, 3)
    scene.call("_show_candidates")
    await process_frame
    await _save_capture(tmp_dir, "candidates_viscount")
    game_state.set("known_candidates", {})
    game_state.call("unlock_candidates_for_rank", "count", 65, 3)
    scene.call("_show_candidates")
    await process_frame
    await _save_capture(tmp_dir, "candidates_count")
    game_state.set("known_candidates", {})
    game_state.call("unlock_candidates_for_rank", "marquis", 65, 3)
    scene.call("_show_candidates")
    await process_frame
    await _save_capture(tmp_dir, "candidates_marquis")
    game_state.set("known_candidates", {})
    game_state.call("unlock_candidates_for_rank", "duke", 65, 3)
    scene.call("_show_candidates")
    await process_frame
    await _save_capture(tmp_dir, "candidates_duke")
    game_state.set("known_candidates", {})
    game_state.call("unlock_candidates_for_rank", "duke", 90, 3)
    scene.call("_show_candidates")
    await process_frame
    await _save_capture(tmp_dir, "candidates_duke_deep_info")
    game_state.call("create_spouse_from_candidate", candidate)
    var spouse_wedding_option: Dictionary = data_manager.call("find_by_id", "marriage_config", "wedding_options", "wedding_social")
    game_state.call("apply_wedding_result_event", spouse_wedding_option, candidate)
    scene.call("_show_spouse")
    await process_frame
    await _save_capture(tmp_dir, "spouse")
    DisplayServer.window_set_size(Vector2i(640, 760))
    root.size = Vector2i(640, 760)
    await process_frame
    await process_frame
    scene.call("_show_spouse")
    await process_frame
    await _save_capture(tmp_dir, "spouse_mobile")
    DisplayServer.window_set_size(Vector2i(1280, 720))
    root.size = Vector2i(1280, 720)
    await process_frame
    await process_frame
    game_state.call("change_stat", "cash", 10)
    time_manager.call("advance_weeks", 11)
    scene.call("_show_spouse")
    await process_frame
    await _save_capture(tmp_dir, "spouse_rank_event")
    scene.call("_show_dashboard")
    await process_frame
    await _save_capture(tmp_dir, "dashboard_rank_event")
    _set_spouse_values(game_state, {"affection": 60, "public_harmony": 65, "direct_suspicion": 5, "threat_alert": 5, "health": 78})
    scene.call("_show_spouse")
    await process_frame
    await _save_capture(tmp_dir, "spouse_affectionate")
    _set_spouse_values(game_state, {"affection": 20, "public_harmony": 20, "direct_suspicion": 55, "threat_alert": 50, "health": 78})
    scene.call("_show_spouse")
    await process_frame
    await _save_capture(tmp_dir, "spouse_suspicious")
    _set_spouse_values(game_state, {"affection": 20, "public_harmony": 20, "direct_suspicion": 10, "threat_alert": 10, "health": 30})
    scene.call("_show_spouse")
    await process_frame
    await _save_capture(tmp_dir, "spouse_weakened")
    _set_spouse_values(game_state, {"affection": 30, "public_harmony": 25, "direct_suspicion": 25, "threat_alert": 45, "health": 78})
    scene.call("_show_removal")
    await process_frame
    await _save_capture(tmp_dir, "removal")
    DisplayServer.window_set_size(Vector2i(820, 720))
    root.size = Vector2i(820, 720)
    await process_frame
    await process_frame
    scene.call("_show_removal")
    await process_frame
    await _save_capture(tmp_dir, "removal_compact")
    DisplayServer.window_set_size(Vector2i(1280, 720))
    root.size = Vector2i(1280, 720)
    await process_frame
    await process_frame
    game_state.set("active_case", {
        "method_id": "capture_open_case",
        "success": true,
        "case_type": "fatal_case",
        "result_name": "사망 사건",
        "result_text": "배우자가 사망하고 사건 파일이 열린다.",
        "investigation_progress": 76,
        "rumor_spread": 24,
        "evidence_risk": 26,
        "alibi_strength": 8,
        "public_grief": 10,
    })
    scene.call("_show_coverup")
    await process_frame
    await _save_capture(tmp_dir, "coverup")
    var political_method: Dictionary = data_manager.call("find_by_id", "removal_methods", "methods", "removal_scandal_disgrace")
    game_state.call("create_spouse_from_candidate", candidate)
    game_state.call("create_case_from_removal", political_method, true)
    scene.call("_show_coverup")
    await process_frame
    await _save_capture(tmp_dir, "political_aftermath")
    DisplayServer.window_set_size(Vector2i(820, 720))
    root.size = Vector2i(820, 720)
    await process_frame
    await process_frame
    scene.call("_show_coverup")
    await process_frame
    await _save_capture(tmp_dir, "political_aftermath_compact")
    DisplayServer.window_set_size(Vector2i(1280, 720))
    root.size = Vector2i(1280, 720)
    await process_frame
    await process_frame
    game_state.set("active_case", {
        "method_id": "capture_resolved_case",
        "success": true,
        "case_type": "fatal_case",
        "result_name": "사망 사건",
        "result_text": "배우자가 사망하고 사건 파일이 열린다.",
        "investigation_progress": 30,
        "rumor_spread": 25,
        "evidence_risk": 20,
        "alibi_strength": 30,
        "public_grief": 10,
    })
    game_state.call("evaluate_active_case")
    scene.call("_show_vertical_slice_complete")
    await process_frame
    await _save_capture(tmp_dir, "complete")
    game_state.set("active_case", {
        "method_id": "capture_case",
        "success": false,
        "investigation_progress": 100,
        "rumor_spread": 60,
        "evidence_risk": 70,
        "alibi_strength": 5,
        "public_grief": 10,
    })
    game_state.call("evaluate_active_case")
    scene.call("_show_game_over")
    await process_frame
    await _save_capture(tmp_dir, "game_over")
    quit()

func _set_spouse_values(game_state: Node, values: Dictionary) -> void:
    var spouse: Dictionary = game_state.get("spouse").duplicate(true)
    for key in values.keys():
        spouse[key] = values[key]
    game_state.set("spouse", spouse)

func _drain_feedback_sequence(feedback: Control) -> void:
    for _index in range(12):
        var scrim: ColorRect = feedback.get("passage_scrim")
        if scrim == null or not scrim.visible:
            return
        feedback.call("_dismiss_active_sequence")
        await process_frame
        await process_frame

func _save_capture(tmp_dir: String, screen_id: String) -> void:
    await create_timer(0.20).timeout
    var image: Image = null
    for attempt in range(6):
        var texture := root.get_texture()
        if texture != null and texture.get_rid().is_valid():
            image = texture.get_image()
            if image != null and image.get_width() > 0 and image.get_height() > 0:
                break
        await process_frame
    if image == null or image.get_width() <= 0 or image.get_height() <= 0:
        push_warning("capture skipped: %s" % screen_id)
        return
    var out_path := tmp_dir.path_join("ui_capture_%s.png" % screen_id)
    var err := image.save_png(out_path)
    print("capture_size=", image.get_size(), " out=", out_path, " err=", err)
