extends SceneTree


func _init() -> void:
    call_deferred("_run")


func _check(condition: bool, message: String) -> bool:
    if condition:
        return true
    push_error("UI feedback smoke failed: %s" % message)
    quit(1)
    return false


func _run() -> void:
    var packed: PackedScene = load("res://scenes/main/Main.tscn")
    var scene: Control = packed.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame

    var game_state := root.get_node("/root/GameState")
    var feedback: Control = scene.get("feedback_layer")
    if not _check(feedback != null, "feedback layer was not created"):
        return
    var toast_container: VBoxContainer = feedback.get("toast_container")
    var banner: PanelContainer = feedback.get("banner")
    var action_panel: PanelContainer = feedback.get("action_panel")
    var action_background: TextureRect = feedback.get("action_background")
    var passage_scrim: ColorRect = feedback.get("passage_scrim")
    var passage_panel: PanelContainer = feedback.get("passage_panel")
    var passage_flow: Control = feedback.get("passage_flow")
    if not _check(toast_container != null, "toast container was not created"):
        return
    if not _check(banner != null, "outcome banner was not created"):
        return
    if not _check(action_panel != null, "action result panel was not created"):
        return
    if not _check(action_background != null, "action result backdrop was not created"):
        return
    if not _check(passage_scrim != null and passage_scrim.mouse_filter == Control.MOUSE_FILTER_STOP, "result scrim did not block click-through input"):
        return
    if not _check(passage_panel != null and passage_flow != null, "generic time passage scene was not created"):
        return

    var before := toast_container.get_child_count()
    game_state.call("apply_effects", {"information": 3, "fatigue": 2})
    await process_frame
    if not _check(toast_container.get_child_count() == before + 1, "state effects did not create a toast"):
        return

    game_state.call("request_feedback", {
        "type": "outcome",
        "tone": "success",
        "title": "검증 성공",
        "detail": "결과 피드백 표시",
    })
    await process_frame
    if not _check(banner.visible, "outcome feedback did not show the banner"):
        return

    var data_manager := root.get_node("/root/DataManager")
    var action_resolver := root.get_node("/root/ActionResolver")
    for raw_action in data_manager.call("get_table", "free_actions").get("actions", []):
        var backdrop_path := String(Dictionary(raw_action).get("result_backdrop", ""))
        if not _check(not backdrop_path.is_empty() and ResourceLoader.exists(backdrop_path), "free action result backdrop was missing: " + backdrop_path):
            return
    var training: Dictionary = data_manager.call("find_by_id", "free_actions", "actions", "practice_mask")
    if not _check(bool(action_resolver.call("run_action", training)), "training action could not be executed"):
        return
    await process_frame
    if not _check(passage_panel.visible, "routine action did not show time passage before its result"):
        return
    var passage_snapshot: Dictionary = passage_flow.call("state_snapshot")
    if not _check(int(passage_snapshot.get("weeks", 0)) == int(training.get("weeks", 1)), "time passage did not receive elapsed weeks"):
        return
    if not _check(int(passage_snapshot.get("to_week", 0)) > int(passage_snapshot.get("from_week", 0)), "time passage did not receive a valid week range"):
        return
    var passage_footer: Label = feedback.find_child("TimePassageFooter", true, false)
    if not _check(passage_footer != null and passage_footer.text.contains("Enter"), "time passage did not expose manual continuation"):
        return
    feedback.call("_dismiss_active_sequence")
    await process_frame
    if not _check(action_panel.visible, "training action did not show the result scene"):
        return
    var action_title: Label = feedback.find_child("ActionResultTitle", true, false)
    var action_effects: HFlowContainer = feedback.find_child("ActionResultEffects", true, false)
    if not _check(action_title != null and action_title.text == "가면 연습", "action result title was not populated"):
        return
    if not _check(action_effects != null and action_effects.get_child_count() >= 2, "action result effects were not populated"):
        return
    if not _check(action_background.texture != null, "training action backdrop was not loaded"):
        return
    var action_footer: Label = feedback.find_child("ActionResultFooter", true, false)
    if not _check(action_footer != null and action_footer.text.contains("클릭 또는 Enter"), "action result did not expose manual continuation"):
        return

    # 실제 자유행동 화면의 버튼 경로에서도 화면 재구성 뒤 결과 장면이 유지되어야 한다.
    feedback.call("_dismiss_active_sequence")
    await process_frame
    scene.call("_show_free_actions")
    await process_frame
    var action_button: Button = scene.find_child("FreeAction_practice_mask", true, false)
    if not _check(action_button != null and not action_button.disabled, "free action button was not available"):
        return
    action_button.emit_signal("pressed")
    await process_frame
    await process_frame
    if not _check(passage_panel.visible, "real free action button path lost the time passage scene"):
        return
    feedback.call("_dismiss_active_sequence")
    await process_frame
    if not _check(action_panel.visible, "real free action button path lost the result scene"):
        return
    if not _check(action_title.text == "가면 연습", "real free action result title was not preserved"):
        return
    feedback.call("_dismiss_active_sequence")
    await process_frame

    var main_scroll: ScrollContainer = scene.get("main_scroll")
    main_scroll.scroll_vertical = 420
    scene.call("_show_personas")
    await process_frame
    if not _check(main_scroll.scroll_vertical == 0, "general screen transition retained the previous scroll position"):
        return

    scene.set_meta("confirmation_accepted", false)
    feedback.call("request_confirmation", "확인 테스트", "아래 UI 입력을 차단합니다.", "확인", func(): scene.set_meta("confirmation_accepted", true))
    await process_frame
    var confirmation_scrim: ColorRect = feedback.get("confirmation_scrim")
    var confirmation_accept: Button = feedback.get("confirmation_confirm_button")
    if not _check(confirmation_scrim != null and confirmation_scrim.visible and confirmation_scrim.mouse_filter == Control.MOUSE_FILTER_STOP, "confirmation did not block the underlying UI"):
        return
    confirmation_accept.emit_signal("pressed")
    await process_frame
    if not _check(bool(scene.get_meta("confirmation_accepted", false)) and not confirmation_scrim.visible, "confirmation callback did not run"):
        return

    var test_button := Button.new()
    feedback.call("bind_button", test_button)
    if not _check(test_button.has_meta("feedback_bound"), "button feedback was not bound"):
        return
    test_button.emit_signal("button_down")
    if not _check(test_button.modulate != Color.WHITE, "button press feedback was not applied"):
        return
    test_button.emit_signal("button_up")
    test_button.free()

    for index in range(6):
        feedback.call("show_toast", "연속 알림 %d" % index, "토스트 수명 주기 검증", "info")
    await create_timer(2.4).timeout
    var active_toasts: Array = feedback.get("active_toasts")
    if not _check(active_toasts.is_empty(), "expired rapid toasts remained active"):
        return

    print("UI_FEEDBACK_SMOKE_OK")
    scene.queue_free()
    await process_frame
    await process_frame
    quit()
