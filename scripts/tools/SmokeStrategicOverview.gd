extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
    if condition:
        return true
    push_error(message)
    quit(1)
    return false

func _run() -> void:
    DisplayServer.window_set_size(Vector2i(1280, 720))
    root.size = Vector2i(1280, 720)
    var packed: PackedScene = load("res://scenes/main/Main.tscn")
    var scene: Control = packed.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame

    var overview: Control = scene.find_child("StrategicOverviewPanel", true, false)
    if not _check(overview != null, "strategic overview was not created"): return
    if not _check(overview.find_child("OverviewStatusCard", true, false) != null, "status card was not created"): return
    if not _check(overview.find_child("OverviewGoalCard", true, false) != null, "goal card was not created"): return
    if not _check(overview.find_child("OverviewInformationCard", true, false) != null, "information card was not created"): return
    var grid: GridContainer = overview.find_child("OverviewCardGrid", true, false)
    if not _check(grid.columns == 3, "desktop overview should use three columns"): return
    var goal_button: Button = overview.find_child("OverviewGoalButton", true, false)
    var goal_text: Label = overview.find_child("OverviewGoalText", true, false)
    var contact_count: Label = overview.find_child("OverviewContactCount", true, false)
    if not _check(goal_text.text.contains("상인"), "initial objective should introduce the merchant"): return
    if not _check(goal_button.text.contains("상점 방문"), "initial objective action should open the shop"): return
    if not _check(contact_count.text == "2명", "week-one contact count should include only accessible NPCs"): return
    if not _check(String(ProjectSettings.get_setting("display/window/stretch/mode")) == "disabled", "responsive UI should use real window pixels instead of scaling the 1280 canvas"): return
    var hero_row: BoxContainer = scene.find_child("DashboardHeroRow", true, false)
    if not _check(hero_row != null and not hero_row.vertical, "desktop dashboard hero should use a horizontal layout"): return

    DisplayServer.window_set_size(Vector2i(820, 720))
    root.size = Vector2i(820, 720)
    await process_frame
    await process_frame
    if not _check(grid.columns == 2, "compact overview should update to two columns without rebuilding"): return
    if not _check(not hero_row.vertical, "compact dashboard hero should remain horizontal to preserve vertical space"): return

    DisplayServer.window_set_size(Vector2i(640, 760))
    root.size = Vector2i(640, 760)
    await process_frame
    await process_frame
    if not _check(grid.columns == 1, "mobile overview should update to one column without rebuilding"): return
    if not _check(not hero_row.vertical, "640px dashboard hero should remain horizontal and readable"): return

    var game_state: Node = root.get_node("/root/GameState")
    var data_manager: Node = root.get_node("/root/DataManager")
    var candidate: Dictionary = data_manager.call("find_by_id", "candidate_profiles", "candidate_profiles", "candidate_knight_tutorial_adrien")
    game_state.call("create_spouse_from_candidate", candidate)
    scene.call("_show_dashboard")
    await process_frame
    overview = scene.find_child("StrategicOverviewPanel", true, false)
    goal_button = overview.find_child("OverviewGoalButton", true, false)
    if not _check(goal_button.text.contains("배우자 확인"), "new marriage should direct the player to the spouse dashboard"): return
    scene.call("_show_spouse")
    await process_frame
    scene.call("_show_dashboard")
    await process_frame
    overview = scene.find_child("StrategicOverviewPanel", true, false)
    goal_button = overview.find_child("OverviewGoalButton", true, false)
    if not _check(goal_button.text.contains("처리 방식 비교"), "viewing the spouse dashboard should advance to the removal decision"): return

    game_state.set("active_case", {
        "result_name": "테스트 사건",
        "investigation_progress": 76,
        "rumor_spread": 34,
        "evidence_risk": 25,
    })
    scene.call("_show_dashboard")
    await process_frame
    overview = scene.find_child("StrategicOverviewPanel", true, false)
    goal_button = overview.find_child("OverviewGoalButton", true, false)
    var alert: Label = overview.find_child("OverviewAlertText", true, false)
    if not _check(goal_button.text.contains("은폐로 이동"), "active case action should open coverup"): return
    if not _check(alert.text.contains("사건 파일"), "active case should show an urgent briefing"): return

    print("STRATEGIC_OVERVIEW_SMOKE_OK")
    scene.queue_free()
    await process_frame
    quit()
