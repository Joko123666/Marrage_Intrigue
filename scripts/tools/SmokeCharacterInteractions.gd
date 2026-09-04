extends SceneTree


func _init() -> void:
    call_deferred("_run")


func _find_button(root_node: Node, button_text: String) -> Button:
    for node in root_node.find_children("*", "Button", true, false):
        var button := node as Button
        if button != null and button.text == button_text:
            return button
    return null


func _run() -> void:
    var packed: PackedScene = load("res://scenes/main/Main.tscn")
    var scene: Control = packed.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame

    var game_state := root.get_node("/root/GameState")
    scene.call("_show_characters")
    await process_frame

    var week_before := int(game_state.get("week"))
    var fatigue_before := int(game_state.call("get_stat", "fatigue"))
    var relation_before: Dictionary = game_state.call("get_relationship", "npc_tailor_mirelle").duplicate(true)
    var talk := _find_button(scene.get("content"), "대화 · 1주")
    assert(talk != null and not talk.disabled)
    talk.pressed.emit()
    await process_frame
    await process_frame

    var relation_after: Dictionary = game_state.call("get_relationship", "npc_tailor_mirelle")
    assert(int(game_state.get("week")) == week_before + 1)
    assert(int(game_state.call("get_stat", "fatigue")) == fatigue_before + 1)
    assert(int(relation_after.get("favor", 0)) > int(relation_before.get("favor", 0)))

    var transaction_before := int(relation_after.get("transaction_value", 0))
    var trade_week_before := int(game_state.get("week"))
    var trade := _find_button(scene.get("content"), "거래")
    assert(trade != null)
    trade.pressed.emit()
    await process_frame
    assert(scene.get("current_screen") == "shop")
    assert(int(game_state.get("week")) == trade_week_before)
    assert(int(game_state.call("get_relationship", "npc_tailor_mirelle").get("transaction_value", 0)) == transaction_before)

    print("CHARACTER_INTERACTIONS_SMOKE_OK")
    quit()
