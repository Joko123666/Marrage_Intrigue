extends SceneTree


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var time_manager := root.get_node("/root/TimeManager")
    assert(int(time_manager.call("calendar_year", 1)) == 1)
    assert(int(time_manager.call("calendar_month", 1)) == 1)
    assert(int(time_manager.call("calendar_month", 52)) == 12)
    assert(int(time_manager.call("calendar_year", 53)) == 2)
    assert(int(time_manager.call("calendar_month", 53)) == 1)

    var packed: PackedScene = load("res://scenes/main/Main.tscn")
    var scene: Control = packed.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame

    var game_state := root.get_node("/root/GameState")
    var calendar_date: Label = scene.get("calendar_date_label")
    var calendar_week: Label = scene.get("calendar_week_label")
    assert(calendar_date != null and calendar_date.text == "제1년 1월")
    assert(calendar_week != null and calendar_week.text.contains("W001"))

    game_state.set("week", 52)
    game_state.set("age_years", 14)
    scene.call("_refresh_header")
    time_manager.call("advance_weeks", 1)
    await process_frame
    assert(int(game_state.get("week")) == 53)
    assert(int(game_state.get("age_years")) == 15)
    assert(calendar_date.text == "제2년 1월")
    assert(calendar_week.text.contains("W053"))

    var feedback: Control = scene.get("feedback_layer")
    var passage_panel: PanelContainer = feedback.get("passage_panel")
    var passage_date: Label = feedback.get("passage_date")
    assert(passage_panel.visible)
    assert(passage_date.text.contains("제1년 12월") and passage_date.text.contains("제2년 1월"))
    feedback.call("_dismiss_active_sequence")
    await process_frame

    time_manager.call("advance_weeks", 1)
    await process_frame
    assert(int(game_state.get("week")) == 54)
    assert(passage_panel.visible)
    assert(passage_date.text == "제2년 1월")
    var passage_flow: Control = feedback.get("passage_flow")
    var passage_snapshot: Dictionary = passage_flow.call("state_snapshot")
    assert(int(passage_snapshot.get("from_week", 0)) == 53)
    assert(int(passage_snapshot.get("to_week", 0)) == 54)
    assert(not bool(passage_snapshot.get("crossed_month", true)))

    print("CALENDAR_UI_SMOKE_OK")
    scene.queue_free()
    await process_frame
    await process_frame
    quit()
