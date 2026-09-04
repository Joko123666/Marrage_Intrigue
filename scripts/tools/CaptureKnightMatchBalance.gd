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
    await create_timer(0.25).timeout

    var data_manager := root.get_node("/root/DataManager")
    var candidate: Dictionary = data_manager.call("find_by_id", "candidate_profiles", "candidate_profiles", "candidate_knight_tutorial_adrien")
    var config: Dictionary = data_manager.call("get_table", "match_config")
    var raw_honesty: Dictionary = config.get("choice_examples", [])[0]
    scene.call("_start_match", candidate)
    await process_frame
    await process_frame
    await _save("knight_tutorial_match")

    for _turn in range(8):
        scene.call("_apply_match_choice", raw_honesty)
    await process_frame
    await create_timer(0.25).timeout
    await _save("knight_tutorial_success")

    scene.queue_free()
    await process_frame
    quit()


func _save(id: String) -> void:
    var tmp_dir := ProjectSettings.globalize_path("res://tmp")
    DirAccess.make_dir_recursive_absolute(tmp_dir)
    var path := ProjectSettings.globalize_path("res://tmp/ui_capture_%s.png" % id)
    var image: Image = root.get_texture().get_image()
    var err := image.save_png(path)
    print("KNIGHT_MATCH_CAPTURE path=", path, " err=", err)
    await process_frame
