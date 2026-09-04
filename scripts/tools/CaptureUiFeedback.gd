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
    var game_state := root.get_node("/root/GameState")
    game_state.call("apply_effects", {"information": 4, "grace": 3, "fatigue": 2})
    game_state.call("request_feedback", {
        "type": "outcome",
        "tone": "success",
        "title": "행동 완료",
        "detail": "사교 모임 참석 · 1주 경과",
    })
    await create_timer(0.35).timeout
    var image: Image = root.get_texture().get_image()
    var out_path := ProjectSettings.globalize_path("res://tmp/ui_capture_feedback.png")
    var err := image.save_png(out_path)
    print("FEEDBACK_CAPTURE path=", out_path, " err=", err)
    scene.queue_free()
    await process_frame
    quit()
