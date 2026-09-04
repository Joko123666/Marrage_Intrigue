extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error(message)
    quit(1)

func _run() -> void:
    var game_state: Node = root.get_node("/root/GameState")
    var data_manager: Node = root.get_node("/root/DataManager")
    var action_resolver: Node = root.get_node("/root/ActionResolver")
    var initial_state: Dictionary = data_manager.call("get_table", "player_initial_state")
    game_state.call("start_new_game", initial_state)

    if not bool(game_state.call("can_start_match")):
        _fail("a new game should allow starting a match")
        return
    game_state.set("active_case", {"investigation_progress": 10})
    if bool(game_state.call("can_start_match")):
        _fail("an active case should block starting a match")
        return
    game_state.set("active_case", {})
    game_state.set("current_match", {"candidate_id": "test"})
    if bool(game_state.call("can_start_match")):
        _fail("an existing match should block starting another match")
        return
    game_state.set("current_match", {})

    var candidate: Dictionary = data_manager.call("find_by_id", "candidate_profiles", "candidate_profiles", "candidate_knight_tutorial_adrien")
    game_state.call("set_flag", "widowed", true)
    game_state.call("set_flag", "widowed_once", true)
    game_state.call("set_flag", "marriage_ended_nonlethal", true)
    game_state.call("set_flag", "case_resolved", true)
    game_state.get("flags")["last_case_resolution"] = "old case"
    game_state.get("flags")["accusation_event_seen"] = true
    game_state.call("create_spouse_from_candidate", candidate)
    var flags: Dictionary = game_state.get("flags")
    if bool(flags.get("widowed", false)) or bool(flags.get("marriage_ended_nonlethal", false)) or bool(flags.get("case_resolved", false)):
        _fail("a new marriage did not clear current-marriage lifecycle flags")
        return
    if flags.has("last_case_resolution") or flags.has("accusation_event_seen"):
        _fail("a new marriage retained stale case metadata")
        return
    if not bool(flags.get("widowed_once", false)):
        _fail("a new marriage erased historical widow progression")
        return
    if bool(game_state.call("can_start_match")):
        _fail("an existing marriage should block starting a match")
        return

    game_state.call("set_flag", "case_resolved", true)
    game_state.get("flags")["last_case_resolution"] = "stale second case"
    game_state.get("flags")["accusation_event_seen"] = true
    var removal_method: Dictionary = data_manager.call("find_by_id", "removal_methods", "methods", "removal_accident_frame")
    game_state.call("create_case_from_removal", removal_method, true)
    flags = game_state.get("flags")
    if bool(flags.get("case_resolved", false)) or flags.has("last_case_resolution") or flags.has("accusation_event_seen"):
        _fail("a new case retained stale resolution or accusation state")
        return

    game_state.call("create_spouse_from_candidate", candidate)
    if bool(game_state.get("flags").get("widowed", false)):
        _fail("remarriage retained current widow status")
        return
    if not bool(game_state.get("flags").get("widowed_once", false)):
        _fail("remarriage erased historical widow status")
        return

    game_state.call("start_new_game", initial_state)
    game_state.call("change_stat", "social_suspicion", -100)
    var veil: Dictionary = data_manager.call("find_by_id", "items", "items", "item_black_mourning_veil")
    game_state.call("add_item", "item_black_mourning_veil")
    var mask_before := int(game_state.call("get_stat", "mask"))
    game_state.call("equip_item", veil)
    if int(game_state.call("get_risk", "social_suspicion")) != 0:
        _fail("a negative item effect crossed the lower risk boundary")
        return
    var equipped_save: Dictionary = game_state.call("export_state")
    if int(equipped_save.get("schema_version", 0)) != 3 or Dictionary(equipped_save.get("equipped_applied_effects", {})).is_empty():
        _fail("equipped applied effects were not exported")
        return
    game_state.call("import_state", equipped_save)
    game_state.call("unequip_slot", "outfit")
    if int(game_state.call("get_risk", "social_suspicion")) != 0:
        _fail("unequipping a clipped negative item effect created suspicion")
        return
    if int(game_state.call("get_stat", "mask")) != mask_before:
        _fail("unequipping did not reverse the actually applied mask bonus")
        return

    var rumor_seed: Dictionary = data_manager.call("find_by_id", "rumors", "operations", "rumor_seed")
    var rival_before: Dictionary = game_state.call("get_relationship", "npc_rival_celina").duplicate(true)
    action_resolver.call("apply_operation_relationship_effects", rumor_seed, true)
    var rival_after: Dictionary = game_state.call("get_relationship", "npc_rival_celina")
    if int(rival_after.get("respect", 0)) != int(rival_before.get("respect", 0)) - 5:
        _fail("rumor target respect effect was not applied")
        return
    if int(rival_after.get("leverage", 0)) != int(rival_before.get("leverage", 0)) + 5:
        _fail("rumor target leverage effect was not applied")
        return

    game_state.set("age_years", 29)
    var prep_before_soft_limit := int(game_state.call("candidate_preparation_bonus", candidate))
    game_state.set("age_years", 30)
    var prep_at_soft_limit := int(game_state.call("candidate_preparation_bonus", candidate))
    if prep_at_soft_limit != prep_before_soft_limit - 3:
        _fail("candidate preparation bonus did not include the age penalty")
        return

    print("FLOW_INVARIANTS_OK")
    quit()
