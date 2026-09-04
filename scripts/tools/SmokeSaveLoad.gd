extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var game_state: Node = root.get_node("/root/GameState")
    var data_manager: Node = root.get_node("/root/DataManager")
    var save_manager: Node = root.get_node("/root/SaveManager")
    var time_manager: Node = root.get_node("/root/TimeManager")
    game_state.call("start_new_game", data_manager.call("get_table", "player_initial_state"))
    game_state.call("change_stat", "cash", 3)
    var saved_cash := int(game_state.call("get_stat", "cash"))
    if not bool(save_manager.call("save_game")):
        push_error("save failed")
        quit(1)
        return
    game_state.call("change_stat", "cash", -3)
    if not bool(save_manager.call("load_game")):
        push_error("load failed")
        quit(1)
        return
    if int(game_state.call("get_stat", "cash")) != saved_cash:
        push_error("cash was not restored")
        quit(1)
        return
    game_state.call("change_stat", "cash", 5)
    var slot_cash := int(game_state.call("get_stat", "cash"))
    if not bool(save_manager.call("save_slot", 1)):
        push_error("slot save failed")
        quit(1)
        return
    game_state.call("change_stat", "cash", -5)
    if not bool(save_manager.call("load_slot", 1)):
        push_error("slot load failed")
        quit(1)
        return
    if int(game_state.call("get_stat", "cash")) != slot_cash:
        push_error("slot cash was not restored")
        quit(1)
        return
    time_manager.call("advance_weeks", 1)
    if not bool(save_manager.call("has_auto_save")):
        push_error("auto save was not created")
        quit(1)
        return
    var before_count := int(game_state.get("known_candidates").size())
    var changed := int(game_state.call("unlock_next_rank_candidates", "baron", 45, 1))
    if changed <= 0 or int(game_state.get("known_candidates").size()) <= before_count:
        push_error("next rank candidate was not unlocked")
        quit(1)
        return
    game_state.call("import_state", {"week": 3, "player": {"stats": {"cash": 9}, "global_risks": {}, "flags": {}, "counters": {}}})
    if int(game_state.get("week")) != 3 or int(game_state.call("get_stat", "cash")) != 9:
        push_error("legacy save migration failed")
        quit(1)
        return
    game_state.call("start_new_game", data_manager.call("get_table", "player_initial_state"))
    var wedding_candidate: Dictionary = data_manager.call("find_by_id", "candidate_profiles", "candidate_profiles", "candidate_knight_tutorial_adrien")
    var wedding_option: Dictionary = data_manager.call("find_by_id", "marriage_config", "wedding_options", "wedding_social")
    game_state.call("create_spouse_from_candidate", wedding_candidate)
    var harmony_before := int(game_state.get("spouse").get("public_harmony", 0))
    var wedding_event: Dictionary = game_state.call("apply_wedding_result_event", wedding_option, wedding_candidate)
    if wedding_event.is_empty():
        push_error("wedding result event was not selected")
        quit(1)
        return
    if not game_state.get("flags").has("last_wedding_event_title"):
        push_error("wedding result event flag was not stored")
        quit(1)
        return
    if int(game_state.get("spouse").get("public_harmony", 0)) <= harmony_before:
        push_error("wedding result event effect was not applied")
        quit(1)
        return
    game_state.call("change_stat", "cash", 10)
    var rank_event_known_before := int(game_state.get("known_candidates").size())
    time_manager.call("advance_weeks", 11)
    if String(game_state.get("flags").get("last_rank_event_id", "")) != "rank_pressure_knight_debt_roll":
        push_error("rank pressure event was not selected")
        quit(1)
        return
    if not game_state.get("flags").has("last_rank_event_effects"):
        push_error("rank pressure event effects were not stored")
        quit(1)
        return
    if int(game_state.get("known_candidates").size()) <= rank_event_known_before:
        push_error("rank pressure event did not unlock next rank candidate")
        quit(1)
        return
    game_state.call("start_new_game", data_manager.call("get_table", "player_initial_state"))
    game_state.call("create_spouse_from_candidate", wedding_candidate)
    var removal_spouse: Dictionary = game_state.get("spouse").duplicate(true)
    removal_spouse["threat_alert"] = 45
    game_state.set("spouse", removal_spouse)
    var removal_method: Dictionary = data_manager.call("find_by_id", "removal_methods", "methods", "removal_accident_frame")
    var counter_event: Dictionary = game_state.call("select_removal_counter_event", removal_method)
    if String(counter_event.get("id", "")) != "counter_high_security_watch":
        push_error("removal counter event was not selected")
        quit(1)
        return
    var suspicion_before := int(game_state.get("spouse").get("direct_suspicion", 0))
    game_state.call("apply_removal_counter_event", counter_event)
    if int(game_state.get("spouse").get("direct_suspicion", 0)) <= suspicion_before:
        push_error("removal counter event effect was not applied")
        quit(1)
        return
    game_state.call("create_case_from_removal", removal_method, true)
    var evidence_before := int(game_state.get("active_case").get("evidence_risk", 0))
    game_state.call("apply_removal_counter_case_effects", counter_event)
    if not game_state.get("active_case").has("counter_event_name"):
        push_error("removal counter event was not stored on case")
        quit(1)
        return
    if int(game_state.get("active_case").get("evidence_risk", 0)) <= evidence_before:
        push_error("removal counter case effect was not applied")
        quit(1)
        return
    game_state.call("start_new_game", data_manager.call("get_table", "player_initial_state"))
    game_state.call("create_spouse_from_candidate", wedding_candidate)
    var political_method: Dictionary = data_manager.call("find_by_id", "removal_methods", "methods", "removal_scandal_disgrace")
    game_state.call("create_case_from_removal", political_method, true)
    if String(game_state.get("active_case").get("case_type", "")) != "political_disgrace":
        push_error("nonlethal political result type was not stored")
        quit(1)
        return
    if bool(game_state.get("flags").get("widowed", false)):
        push_error("nonlethal political result incorrectly set widowed")
        quit(1)
        return
    if not bool(game_state.get("flags").get("marriage_ended_nonlethal", false)):
        push_error("nonlethal political result flag was not set")
        quit(1)
        return
    game_state.call("start_new_game", data_manager.call("get_table", "player_initial_state"))
    game_state.call("change_stat", "cash", 20)
    game_state.call("change_stat", "fatigue", -10)
    var etiquette_book: Dictionary = data_manager.call("find_by_id", "items", "items", "item_basic_etiquette_book")
    game_state.call("add_item", "item_basic_etiquette_book")
    game_state.call("equip_item", etiquette_book)
    if int(game_state.call("equipped_effect_value", "etiquette_training_bonus")) != 1:
        push_error("equipped item bonus was not detected")
        quit(1)
        return
    var etiquette_before := int(game_state.call("get_stat", "etiquette"))
    var grace_before := int(game_state.call("get_stat", "grace"))
    var etiquette_action: Dictionary = data_manager.call("find_by_id", "free_actions", "actions", "practice_etiquette")
    var scaled_training_effects: Dictionary = root.get_node("/root/ActionResolver").call("adjusted_effects", etiquette_action)
    if not bool(root.get_node("/root/ActionResolver").call("run_action", etiquette_action)):
        push_error("etiquette action failed")
        quit(1)
        return
    if int(game_state.call("get_stat", "etiquette")) - etiquette_before != int(scaled_training_effects.get("etiquette", 0)) + 1:
        push_error("etiquette item bonus was not applied")
        quit(1)
        return
    if int(game_state.call("get_stat", "grace")) - grace_before != int(scaled_training_effects.get("grace", 0)) + 1:
        push_error("grace item bonus was not applied")
        quit(1)
        return
    game_state.call("start_new_game", data_manager.call("get_table", "player_initial_state"))
    game_state.call("change_stat", "etiquette", 15)
    game_state.call("change_stat", "mask", 6)
    time_manager.call("advance_weeks", 1)
    if String(game_state.get("player").get("current_voice_stage", "")) != "voice_1_borrowed_dress":
        push_error("voice stage did not advance from progression stats")
        quit(1)
        return
    var persona_player: Dictionary = game_state.get("player").duplicate(true)
    persona_player["current_persona"] = "persona_innocent_protegee"
    game_state.set("player", persona_player)
    var maintenance_cash := int(game_state.call("get_stat", "cash"))
    var maintenance_fatigue := int(game_state.call("get_stat", "fatigue"))
    time_manager.call("advance_weeks", 1)
    if int(game_state.call("get_stat", "cash")) != maintenance_cash - 1:
        push_error("persona weekly cash maintenance was not applied")
        quit(1)
        return
    if int(game_state.call("get_stat", "fatigue")) != maintenance_fatigue + 1:
        push_error("persona weekly fatigue maintenance was not applied")
        quit(1)
        return
    game_state.set("age_years", 30)
    if int(game_state.call("marriage_market_age_penalty")) != 3:
        push_error("soft age limit marriage penalty was not applied")
        quit(1)
        return
    game_state.set("age_years", 35)
    game_state.call("on_week_elapsed")
    if not bool(game_state.get("flags").get("game_over", false)):
        push_error("hard age limit did not end the run")
        quit(1)
        return
    print("SAVE_LOAD_OK")
    quit()
