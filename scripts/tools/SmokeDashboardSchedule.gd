extends SceneTree


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    DisplayServer.window_set_size(Vector2i(1280, 720))
    root.size = Vector2i(1280, 720)
    var packed: PackedScene = load("res://scenes/main/Main.tscn")
    var scene: Control = packed.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame

    assert(scene.find_child("DashboardManagementRow", true, false) != null)
    assert(scene.find_child("DashboardScheduleSlots", true, false) != null)
    assert(scene.find_child("DashboardStatBook", true, false) != null)
    assert(not bool(scene.get("nav_bar").visible))
    assert(not bool(scene.get("log_frame").visible))

    var initial_week := int(root.get_node("/root/GameState").get("week"))
    scene.call("_queue_dashboard_action", "street_errands")
    scene.call("_queue_dashboard_action", "rest_and_recover")
    assert(Array(scene.get("dashboard_schedule")).size() == 2)
    assert(_has_button_text(scene, "일정 취소"))
    scene.call("_confirm_dashboard_schedule")
    await process_frame
    await process_frame

    assert(int(root.get_node("/root/GameState").get("week")) == initial_week + 2)
    assert(Array(scene.get("dashboard_schedule")).is_empty())
    assert(String(scene.get("current_screen")) == "dashboard")
    scene.call("_set_dashboard_book_tab", "risk")
    await process_frame
    assert(String(scene.get("dashboard_book_tab")) == "risk")

    print("DASHBOARD_SCHEDULE_SMOKE_OK")
    scene.queue_free()
    await process_frame
    quit()


func _has_button_text(root_node: Node, expected_text: String) -> bool:
    for node in root_node.find_children("*", "Button", true, false):
        if String(node.text) == expected_text:
            return true
    return false
