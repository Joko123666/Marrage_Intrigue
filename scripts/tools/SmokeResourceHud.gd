extends SceneTree


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var packed: PackedScene = load("res://scenes/main/Main.tscn")
    var scene: Control = packed.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame

    var game_state := root.get_node("/root/GameState")
    var cash_card: Control = scene.get("cash_card")
    var vitality_card: Control = scene.get("vitality_card")
    var resource_row: Control = scene.get("resource_row")
    assert(cash_card != null and vitality_card != null)
    assert(resource_row.visible)
    assert(int(cash_card.get("current_value")) == 8)
    assert(int(vitality_card.get("current_value")) == 90)

    game_state.call("change_stat", "cash", 3)
    game_state.call("change_stat", "fatigue", 5)
    await process_frame
    assert(int(cash_card.get("current_value")) == 11)
    assert(int(vitality_card.get("current_value")) == 85)
    var cash_delta: Label = cash_card.get("delta_label")
    var vitality_delta: Label = vitality_card.get("delta_label")
    assert(cash_delta.text == "+3")
    assert(vitality_delta.text == "-5")

    var data_manager := root.get_node("/root/DataManager")
    var candidate: Dictionary = data_manager.call("find_by_id", "candidate_profiles", "candidate_profiles", "candidate_knight_tutorial_adrien")
    scene.call("_start_match", candidate)
    await process_frame
    assert(not resource_row.visible)
    assert(scene.get("content").find_child("MatchBattleShell", true, false) != null)

    print("RESOURCE_HUD_SMOKE_OK")
    scene.queue_free()
    await process_frame
    await process_frame
    quit()
