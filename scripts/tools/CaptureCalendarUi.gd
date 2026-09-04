extends SceneTree


func _init() -> void:
    call_deferred("_capture")


func _capture() -> void:
    DisplayServer.window_set_size(Vector2i(1280, 720))
    root.size = Vector2i(1280, 720)
    var packed: PackedScene = load("res://scenes/main/Main.tscn")
    var scene: Control = packed.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame
    await create_timer(0.2).timeout
    await _save("calendar")

    DisplayServer.window_set_size(Vector2i(640, 760))
    root.size = Vector2i(640, 760)
    await process_frame
    await process_frame
    scene.call("_show_dashboard")
    await process_frame
    await _save("calendar_mobile")
    DisplayServer.window_set_size(Vector2i(1280, 720))
    root.size = Vector2i(1280, 720)
    await process_frame
    await process_frame

    var game_state := root.get_node("/root/GameState")
    var time_manager := root.get_node("/root/TimeManager")
    game_state.set("week", 5)
    scene.call("_refresh_header")
    time_manager.call("advance_weeks", 1)
    await create_timer(0.30).timeout
    await _save("month_passage")

    await create_timer(1.5).timeout
    game_state.set("week", 52)
    game_state.set("age_years", 14)
    scene.call("_refresh_header")
    time_manager.call("advance_weeks", 1)
    await create_timer(0.30).timeout
    await _save("year_passage")

    scene.queue_free()
    await process_frame
    quit()


func _save(id: String) -> void:
    var image: Image = root.get_texture().get_image()
    var path := ProjectSettings.globalize_path("res://tmp/ui_capture_%s.png" % id)
    var err := image.save_png(path)
    print("CALENDAR_CAPTURE path=", path, " err=", err)
    await process_frame
