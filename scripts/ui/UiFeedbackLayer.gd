extends Control

const TIME_PASSAGE_FLOW := preload("res://scripts/ui/TimePassageFlow.gd")

const COLOR_GOOD := Color(0.30, 0.78, 0.52, 1.0)
const COLOR_BAD := Color(0.90, 0.25, 0.25, 1.0)
const COLOR_WARN := Color(0.95, 0.64, 0.24, 1.0)
const COLOR_INFO := Color(0.32, 0.58, 0.90, 1.0)
const COLOR_TEXT := Color(0.96, 0.93, 0.87, 1.0)
const LOWER_IS_BETTER := {
    "fatigue": true, "stress": true, "social_suspicion": true,
    "origin_rumor": true, "notoriety": true, "underworld_trace": true,
    "direct_suspicion": true, "threat_alert": true,
    "investigation_progress": true, "rumor_spread": true, "evidence_risk": true,
    "suspicion": true,
}

var owner_main: Control
var flash: ColorRect
var passage_scrim: ColorRect
var passage_panel: PanelContainer
var passage_kicker: Label
var passage_date: Label
var passage_detail: Label
var passage_flow: Control
var passage_footer: Label
var passage_tween: Tween
var action_panel: PanelContainer
var action_background: TextureRect
var action_background_shade: ColorRect
var action_kicker: Label
var action_title: Label
var action_detail: Label
var action_effects: HFlowContainer
var action_footer: Label
var action_tween: Tween
var action_background_tween: Tween
var toast_container: VBoxContainer
var banner: PanelContainer
var banner_title: Label
var banner_subtitle: Label
var banner_tween: Tween
var active_toasts: Array[Control] = []
var banner_queue: Array[Dictionary] = []
var passage_queue: Array[Dictionary] = []
var action_queue: Array[Dictionary] = []
var overlay_input_enabled_at: int = 0
var confirmation_scrim: ColorRect
var confirmation_panel: PanelContainer
var confirmation_title: Label
var confirmation_detail: Label
var confirmation_confirm_button: Button
var confirmation_callback: Callable


func setup(main: Control) -> void:
    owner_main = main
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    flash = ColorRect.new()
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    flash.modulate.a = 0.0
    add_child(flash)

    passage_scrim = ColorRect.new()
    passage_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    passage_scrim.color = Color(0.01, 0.008, 0.012, 0.62)
    passage_scrim.modulate.a = 0.0
    passage_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
    passage_scrim.visible = false
    passage_scrim.gui_input.connect(_on_passage_scrim_input)
    add_child(passage_scrim)

    passage_panel = PanelContainer.new()
    passage_panel.name = "TimePassagePanel"
    passage_panel.set_anchors_preset(Control.PRESET_CENTER)
    passage_panel.offset_left = -280
    passage_panel.offset_top = -126
    passage_panel.offset_right = 280
    passage_panel.offset_bottom = 126
    passage_panel.mouse_filter = Control.MOUSE_FILTER_PASS
    passage_panel.visible = false
    add_child(passage_panel)
    var passage_box := VBoxContainer.new()
    passage_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    passage_box.alignment = BoxContainer.ALIGNMENT_CENTER
    passage_box.add_theme_constant_override("separation", 5)
    passage_panel.add_child(passage_box)
    passage_kicker = _label("", 15)
    passage_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    passage_box.add_child(passage_kicker)
    passage_date = _label("", 27)
    passage_date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    passage_box.add_child(passage_date)
    passage_flow = TIME_PASSAGE_FLOW.new()
    passage_flow.name = "TimePassageFlow"
    passage_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    passage_box.add_child(passage_flow)
    passage_detail = _label("", 13)
    passage_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    passage_box.add_child(passage_detail)
    passage_footer = _label("클릭 또는 Enter로 계속", 11)
    passage_footer.name = "TimePassageFooter"
    passage_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    passage_footer.add_theme_color_override("font_color", Color(0.66, 0.65, 0.66, 1.0))
    passage_box.add_child(passage_footer)

    action_panel = PanelContainer.new()
    action_panel.name = "ActionResultPanel"
    action_panel.set_anchors_preset(Control.PRESET_CENTER)
    action_panel.offset_left = -292
    action_panel.offset_top = -154
    action_panel.offset_right = 292
    action_panel.offset_bottom = 154
    action_panel.clip_contents = true
    action_panel.mouse_filter = Control.MOUSE_FILTER_PASS
    action_panel.visible = false
    add_child(action_panel)
    action_background = TextureRect.new()
    action_background.name = "ActionResultBackdrop"
    action_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    action_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    action_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    action_panel.add_child(action_background)
    action_background_shade = ColorRect.new()
    action_background_shade.color = Color(0.006, 0.005, 0.008, 0.48)
    action_background_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    action_panel.add_child(action_background_shade)
    var action_box := VBoxContainer.new()
    action_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    action_box.alignment = BoxContainer.ALIGNMENT_CENTER
    action_box.add_theme_constant_override("separation", 8)
    action_panel.add_child(action_box)
    action_kicker = _label("", 13)
    action_kicker.name = "ActionResultKicker"
    action_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    action_box.add_child(action_kicker)
    action_title = _label("", 27)
    action_title.name = "ActionResultTitle"
    action_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    action_box.add_child(action_title)
    var rule := ColorRect.new()
    rule.color = Color(0.76, 0.56, 0.24, 0.82)
    rule.custom_minimum_size = Vector2(0, 2)
    rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
    action_box.add_child(rule)
    action_detail = _label("", 14)
    action_detail.name = "ActionResultDetail"
    action_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    action_detail.custom_minimum_size = Vector2(0, 54)
    action_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    action_box.add_child(action_detail)
    action_effects = HFlowContainer.new()
    action_effects.name = "ActionResultEffects"
    action_effects.alignment = FlowContainer.ALIGNMENT_CENTER
    action_effects.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    action_effects.custom_minimum_size = Vector2(520, 42)
    action_effects.add_theme_constant_override("h_separation", 7)
    action_effects.add_theme_constant_override("v_separation", 6)
    action_effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
    action_box.add_child(action_effects)
    action_footer = _label("", 12)
    action_footer.name = "ActionResultFooter"
    action_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    action_box.add_child(action_footer)

    toast_container = VBoxContainer.new()
    toast_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    toast_container.offset_left = -360
    toast_container.offset_top = 14
    toast_container.offset_right = -14
    toast_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
    toast_container.add_theme_constant_override("separation", 6)
    toast_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(toast_container)

    banner = PanelContainer.new()
    banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
    banner.offset_left = -260
    banner.offset_top = 78
    banner.offset_right = 260
    banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
    banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    banner.visible = false
    add_child(banner)
    var banner_box := VBoxContainer.new()
    banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    banner_box.alignment = BoxContainer.ALIGNMENT_CENTER
    banner_box.add_theme_constant_override("separation", 2)
    banner.add_child(banner_box)
    banner_title = _label("", 19)
    banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner_box.add_child(banner_title)
    banner_subtitle = _label("", 12)
    banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner_box.add_child(banner_subtitle)

    _build_confirmation_ui()

    GameState.feedback_event.connect(_on_feedback_event)


func _build_confirmation_ui() -> void:
    confirmation_scrim = ColorRect.new()
    confirmation_scrim.name = "ConfirmationScrim"
    confirmation_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    confirmation_scrim.color = Color(0.005, 0.004, 0.006, 0.76)
    confirmation_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
    confirmation_scrim.visible = false
    add_child(confirmation_scrim)

    confirmation_panel = PanelContainer.new()
    confirmation_panel.name = "ConfirmationPanel"
    confirmation_panel.set_anchors_preset(Control.PRESET_CENTER)
    confirmation_panel.offset_left = -260
    confirmation_panel.offset_top = -118
    confirmation_panel.offset_right = 260
    confirmation_panel.offset_bottom = 118
    confirmation_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    confirmation_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.025, 0.03, 0.99), COLOR_WARN, 3))
    confirmation_scrim.add_child(confirmation_panel)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    confirmation_panel.add_child(box)
    confirmation_title = _label("", 20)
    confirmation_title.name = "ConfirmationTitle"
    confirmation_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    confirmation_title.add_theme_color_override("font_color", COLOR_WARN)
    box.add_child(confirmation_title)
    confirmation_detail = _label("", 13)
    confirmation_detail.name = "ConfirmationDetail"
    confirmation_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    confirmation_detail.custom_minimum_size = Vector2(0, 72)
    confirmation_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    box.add_child(confirmation_detail)

    var controls := HBoxContainer.new()
    controls.alignment = BoxContainer.ALIGNMENT_CENTER
    controls.add_theme_constant_override("separation", 10)
    box.add_child(controls)
    var cancel_button := Button.new()
    cancel_button.name = "ConfirmationCancel"
    cancel_button.text = "취소"
    cancel_button.custom_minimum_size = Vector2(150, 42)
    _style_confirmation_button(cancel_button, COLOR_INFO)
    cancel_button.pressed.connect(_close_confirmation)
    controls.add_child(cancel_button)
    confirmation_confirm_button = Button.new()
    confirmation_confirm_button.name = "ConfirmationAccept"
    confirmation_confirm_button.custom_minimum_size = Vector2(190, 42)
    _style_confirmation_button(confirmation_confirm_button, COLOR_BAD)
    confirmation_confirm_button.pressed.connect(_accept_confirmation)
    controls.add_child(confirmation_confirm_button)


func request_confirmation(title: String, detail: String, confirm_label: String, callback: Callable) -> void:
    if confirmation_scrim == null:
        return
    confirmation_callback = callback
    confirmation_title.text = title
    confirmation_detail.text = detail
    confirmation_confirm_button.text = confirm_label
    confirmation_scrim.visible = true
    confirmation_panel.modulate = Color(1, 1, 1, 0)
    confirmation_panel.scale = Vector2(0.96, 0.96)
    confirmation_panel.pivot_offset = Vector2(260, 118)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(confirmation_panel, "modulate", Color.WHITE, 0.16)
    tween.tween_property(confirmation_panel, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close_confirmation() -> void:
    confirmation_callback = Callable()
    if confirmation_scrim != null:
        confirmation_scrim.visible = false


func _accept_confirmation() -> void:
    var callback := confirmation_callback
    _close_confirmation()
    if callback.is_valid():
        callback.call()


func _on_feedback_event(event: Dictionary) -> void:
    var type := String(event.get("type", "info"))
    match type:
        "time_passage":
            show_time_passage(event)
        "effects":
            _show_effect_changes(event.get("changes", {}))
        "action_result":
            show_action_result(event)
        "relationship":
            var delta := int(event.get("delta", 0))
            var tone := _change_tone(String(event.get("axis", "")), delta)
            show_toast(String(event.get("title", "관계 변화")), String(event.get("detail", "")), tone)
            play_flash(_tone_color(tone), 0.09)
        "outcome", "milestone", "discovery", "reward":
            var tone := String(event.get("tone", "info"))
            show_banner(String(event.get("title", "결과")), String(event.get("detail", "")), tone)
            play_flash(_tone_color(tone), 0.15 if type == "outcome" else 0.10)
        "match_turn":
            if owner_main != null and owner_main.has_method("_play_match_turn_feedback"):
                owner_main.call("_play_match_turn_feedback", event)
            else:
                play_flash(_tone_color(String(event.get("tone", "info"))), 0.08)
        _:
            show_toast(String(event.get("title", "알림")), String(event.get("detail", "")), String(event.get("tone", "info")))


func show_time_passage(event: Dictionary) -> void:
    if passage_panel == null:
        return
    if (passage_panel.visible and passage_tween != null and passage_tween.is_valid()) or (action_panel.visible and action_tween != null and action_tween.is_valid()):
        passage_queue.append(event.duplicate(true))
        return
    _show_time_passage_now(event)


func _show_time_passage_now(event: Dictionary) -> void:
    var crossed_year := bool(event.get("crossed_year", false))
    var crossed_month := bool(event.get("crossed_month", false)) or crossed_year
    var accent := Color(0.96, 0.73, 0.31, 1.0) if crossed_year else Color(0.66, 0.78, 0.94, 1.0) if crossed_month else Color(0.88, 0.66, 0.34, 1.0)
    var compact_mode := get_viewport_rect().size.x < 700.0
    var half_width := minf(280.0, get_viewport_rect().size.x * 0.45)
    var half_height := 118.0 if compact_mode else 126.0
    passage_panel.offset_left = -half_width
    passage_panel.offset_top = -half_height
    passage_panel.offset_right = half_width
    passage_panel.offset_bottom = half_height
    passage_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.022, 0.035, 0.98), accent, 3))
    passage_kicker.text = "새로운 해가 밝습니다" if crossed_year else "달이 바뀝니다" if crossed_month else "일상이 흐릅니다"
    passage_kicker.add_theme_color_override("font_color", accent)
    var from_date := "제%d년 %d월" % [int(event.get("from_year", event.get("year", 1))), int(event.get("from_month", event.get("month", 1)))]
    var to_date := "제%d년 %d월" % [int(event.get("year", 1)), int(event.get("month", 1))]
    passage_date.text = "%s  →  %s" % [from_date, to_date] if crossed_month else to_date
    passage_date.add_theme_font_size_override("font_size", 21 if compact_mode and crossed_month else 24 if compact_mode else 27)
    passage_date.add_theme_color_override("font_color", COLOR_TEXT)
    var from_week := int(event.get("from_week", maxi(1, int(event.get("to_week", GameState.week)) - int(event.get("weeks", 1)))))
    var to_week := int(event.get("to_week", GameState.week))
    passage_detail.text = "생활 제%d주  →  제%d주  ·  %d주 경과" % [from_week, to_week, int(event.get("weeks", 1))]
    if crossed_year:
        passage_detail.text += "  ·  현재 %d세" % int(event.get("age", GameState.age_years))
    passage_flow.call("configure", event, compact_mode, bool(ProjectSettings.get_setting("accessibility/reduce_motion", false)))
    passage_scrim.visible = true
    passage_panel.visible = true
    passage_flow.call("play")
    overlay_input_enabled_at = Time.get_ticks_msec() + 140
    passage_scrim.modulate.a = 0.0
    passage_panel.modulate = Color(1, 1, 1, 0)
    passage_panel.scale = Vector2(0.94, 0.94)
    passage_panel.pivot_offset = Vector2(half_width, half_height)
    passage_tween = create_tween()
    passage_tween.set_parallel(true)
    passage_tween.tween_property(passage_scrim, "modulate:a", 1.0, 0.18)
    passage_tween.tween_property(passage_panel, "modulate", Color.WHITE, 0.18)
    passage_tween.tween_property(passage_panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    passage_tween.chain().tween_interval(1.25 if crossed_year else 0.98 if crossed_month else 0.78)
    passage_tween.chain().set_parallel(true)
    passage_tween.tween_property(passage_scrim, "modulate:a", 0.0, 0.26)
    passage_tween.tween_property(passage_panel, "modulate:a", 0.0, 0.24)
    passage_tween.tween_property(passage_panel, "scale", Vector2(1.025, 1.025), 0.24)
    passage_tween.chain().tween_callback(_finish_time_passage)


func _finish_time_passage() -> void:
    passage_scrim.visible = false
    passage_panel.visible = false
    if not action_queue.is_empty():
        var next_action: Dictionary = action_queue.pop_front()
        _show_action_result_now(next_action)
        return
    if passage_queue.is_empty():
        overlay_input_enabled_at = 0
        return
    var next_passage: Dictionary = passage_queue.pop_front()
    _show_time_passage_now(next_passage)


func show_action_result(event: Dictionary) -> void:
    if action_panel == null:
        return
    if (passage_panel.visible and passage_tween != null and passage_tween.is_valid()) or (action_panel.visible and action_tween != null and action_tween.is_valid()):
        action_queue.append(event.duplicate(true))
        return
    _show_action_result_now(event)


func _show_action_result_now(event: Dictionary) -> void:
    var accent := _action_category_color(String(event.get("category", "")))
    action_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.016, 0.018, 0.92), accent, 3))
    var backdrop_path := String(event.get("backdrop", ""))
    var backdrop_resource := ResourceLoader.load(backdrop_path) if not backdrop_path.is_empty() else null
    action_background.texture = backdrop_resource as Texture2D
    action_background.visible = action_background.texture != null
    action_background_shade.visible = action_background.visible
    action_kicker.text = "◆  %s  ◆" % String(event.get("kicker", "행동 기록"))
    action_kicker.add_theme_color_override("font_color", accent)
    action_title.text = String(event.get("title", "행동 완료"))
    action_title.add_theme_color_override("font_color", COLOR_TEXT)
    action_detail.text = String(event.get("detail", "계획한 일을 마쳤습니다."))
    action_footer.text = "%d주가 흘렀습니다  ·  클릭 또는 Enter로 계속" % int(event.get("weeks", 1))
    action_footer.add_theme_color_override("font_color", Color(0.72, 0.70, 0.68, 1.0))
    for child in action_effects.get_children():
        child.queue_free()
    var effects: Dictionary = event.get("effects", {})
    for raw_id in effects.keys():
        var id := String(raw_id)
        var delta := int(effects[raw_id])
        if delta == 0:
            continue
        var tone := _change_tone(id, delta)
        var pill := PanelContainer.new()
        pill.custom_minimum_size = Vector2(112, 0)
        pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
        pill.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.07, 0.07, 0.96), _tone_color(tone), 1))
        var label := _label("%s  %s%d" % [String(GameState.call("_value_name", id)), "+" if delta > 0 else "", delta], 13)
        label.autowrap_mode = TextServer.AUTOWRAP_OFF
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.add_theme_color_override("font_color", _tone_color(tone))
        pill.add_child(label)
        action_effects.add_child(pill)
    if action_effects.get_child_count() == 0:
        var no_change := _label("수치 변화 없음", 13)
        no_change.add_theme_color_override("font_color", Color(0.72, 0.70, 0.68, 1.0))
        action_effects.add_child(no_change)
    passage_scrim.visible = true
    action_panel.visible = true
    overlay_input_enabled_at = Time.get_ticks_msec() + 180
    passage_scrim.modulate.a = 0.0
    action_panel.modulate = Color(1, 1, 1, 0)
    action_panel.scale = Vector2(0.92, 0.92)
    action_panel.pivot_offset = Vector2(292, 154)
    action_background.scale = Vector2(1.035, 1.035)
    action_background.pivot_offset = Vector2(292, 154)
    action_background.modulate = Color(0.76, 0.76, 0.76, 1.0)
    if action_background_tween != null and action_background_tween.is_valid():
        action_background_tween.kill()
    action_background_tween = create_tween()
    action_background_tween.set_parallel(true)
    action_background_tween.tween_property(action_background, "scale", Vector2.ONE, 1.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    action_background_tween.tween_property(action_background, "modulate", Color.WHITE, 0.55)
    action_tween = create_tween()
    action_tween.set_parallel(true)
    action_tween.tween_property(passage_scrim, "modulate:a", 1.0, 0.20)
    action_tween.tween_property(action_panel, "modulate", Color.WHITE, 0.22)
    action_tween.tween_property(action_panel, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    action_tween.chain().tween_interval(3.2)
    action_tween.chain().set_parallel(true)
    action_tween.tween_property(passage_scrim, "modulate:a", 0.0, 0.32)
    action_tween.tween_property(action_panel, "modulate:a", 0.0, 0.28)
    action_tween.tween_property(action_panel, "scale", Vector2(1.025, 1.025), 0.28)
    action_tween.chain().tween_callback(_finish_action_result)


func _finish_action_result() -> void:
    passage_scrim.visible = false
    action_panel.visible = false
    if not passage_queue.is_empty():
        var next_passage: Dictionary = passage_queue.pop_front()
        _show_time_passage_now(next_passage)
        return
    if action_queue.is_empty():
        overlay_input_enabled_at = 0
        return
    var next_action: Dictionary = action_queue.pop_front()
    _show_action_result_now(next_action)


func _on_passage_scrim_input(event: InputEvent) -> void:
    if confirmation_scrim != null and confirmation_scrim.visible:
        return
    if event is InputEventMouseButton and event.pressed and Time.get_ticks_msec() >= overlay_input_enabled_at:
        passage_scrim.accept_event()
        _dismiss_active_sequence()


func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    var key_event := event as InputEventKey
    if confirmation_scrim != null and confirmation_scrim.visible:
        if key_event.keycode == KEY_ESCAPE:
            _close_confirmation()
            get_viewport().set_input_as_handled()
        elif key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
            _accept_confirmation()
            get_viewport().set_input_as_handled()
        return
    if not passage_scrim.visible or Time.get_ticks_msec() < overlay_input_enabled_at:
        return
    if key_event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
        _dismiss_active_sequence()
        get_viewport().set_input_as_handled()


func _dismiss_active_sequence() -> void:
    if action_panel.visible:
        if action_tween != null and action_tween.is_valid():
            action_tween.kill()
        if action_background_tween != null and action_background_tween.is_valid():
            action_background_tween.kill()
        _finish_action_result()
        return
    if passage_panel.visible:
        if passage_tween != null and passage_tween.is_valid():
            passage_tween.kill()
        _finish_time_passage()


func _show_effect_changes(changes: Dictionary) -> void:
    if changes.is_empty():
        return
    var parts: Array[String] = []
    var good := 0
    var bad := 0
    for path in changes.keys():
        var change: Dictionary = changes[path]
        var delta := int(change.get("delta", 0))
        if delta == 0:
            continue
        var id := String(change.get("id", ""))
        parts.append("%s %s%d" % [String(change.get("name", id)), "+" if delta > 0 else "", delta])
        var tone := _change_tone(id, delta)
        if tone == "good":
            good += 1
        elif tone == "bad":
            bad += 1
    if parts.is_empty():
        return
    var tone := "good" if good > 0 and bad == 0 else "bad" if bad > 0 and good == 0 else "warn"
    show_toast("상태 변화", "  ·  ".join(parts), tone)
    play_flash(_tone_color(tone), 0.07)


func show_toast(title: String, detail: String, tone: String = "info") -> void:
    if toast_container == null:
        return
    while active_toasts.size() >= 4:
        var oldest: Control = active_toasts.pop_front()
        if is_instance_valid(oldest):
            oldest.queue_free()
    var accent := _tone_color(tone)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(320, 0)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.028, 0.04, 0.96), accent, 2))
    toast_container.add_child(panel)
    active_toasts.append(panel)
    var row := HBoxContainer.new()
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_theme_constant_override("separation", 8)
    panel.add_child(row)
    var marker := ColorRect.new()
    marker.color = accent
    marker.custom_minimum_size = Vector2(5, 0)
    marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(marker)
    var box := VBoxContainer.new()
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_theme_constant_override("separation", 1)
    row.add_child(box)
    var title_label := _label(title, 14)
    title_label.add_theme_color_override("font_color", accent)
    box.add_child(title_label)
    var detail_label := _label(detail, 12)
    box.add_child(detail_label)
    panel.modulate = Color(1, 1, 1, 0)
    panel.position.x += 24
    var target_x := panel.position.x - 24
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(panel, "modulate", Color.WHITE, 0.16)
    tween.tween_property(panel, "position:x", target_x, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.chain().tween_interval(1.7)
    tween.chain().set_parallel(true)
    tween.tween_property(panel, "modulate:a", 0.0, 0.28)
    tween.tween_property(panel, "position:x", panel.position.x + 18, 0.28)
    var panel_ref: WeakRef = weakref(panel)
    tween.chain().tween_callback(func():
        var target: Control = panel_ref.get_ref() as Control
        if target != null:
            _remove_toast(target)
    )


func show_banner(title: String, subtitle: String, tone: String = "info") -> void:
    if banner == null:
        return
    if banner.visible and banner_tween != null and banner_tween.is_valid():
        banner_queue.append({"title": title, "subtitle": subtitle, "tone": tone})
        return
    _show_banner_now(title, subtitle, tone)


func clear_transient_banners() -> void:
    banner_queue.clear()
    if banner_tween != null and banner_tween.is_valid():
        banner_tween.kill()
    if banner != null:
        banner.visible = false


func _show_banner_now(title: String, subtitle: String, tone: String) -> void:
    var accent := _tone_color(tone)
    banner.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.025, 0.04, 0.97), accent, 3))
    banner_title.text = title
    banner_title.add_theme_color_override("font_color", accent)
    banner_subtitle.text = subtitle
    banner.visible = true
    banner.modulate = Color(1, 1, 1, 0)
    banner.scale = Vector2(0.96, 0.96)
    banner.pivot_offset = banner.size * 0.5
    banner_tween = create_tween()
    banner_tween.set_parallel(true)
    banner_tween.tween_property(banner, "modulate", Color.WHITE, 0.16)
    banner_tween.tween_property(banner, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    banner_tween.chain().tween_interval(1.15)
    banner_tween.chain().tween_property(banner, "modulate:a", 0.0, 0.30)
    banner_tween.chain().tween_callback(_finish_banner)


func _finish_banner() -> void:
    banner.visible = false
    if banner_queue.is_empty():
        return
    var next_banner: Dictionary = banner_queue.pop_front()
    _show_banner_now(
        String(next_banner.get("title", "")),
        String(next_banner.get("subtitle", "")),
        String(next_banner.get("tone", "info"))
    )


func play_flash(color: Color, strength: float = 0.1) -> void:
    if flash == null:
        return
    flash.color = Color(color.r, color.g, color.b, strength)
    flash.modulate.a = 1.0
    var tween := create_tween()
    tween.tween_property(flash, "modulate:a", 0.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func animate_screen(target: Control) -> void:
    if not is_instance_valid(target) or String(owner_main.get("current_screen")) == "match":
        return
    target.modulate = Color(1, 1, 1, 0.42)
    target.position.y += 7
    var end_y := target.position.y - 7
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(target, "modulate", Color.WHITE, 0.18)
    tween.tween_property(target, "position:y", end_y, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func bind_button(button: Button) -> void:
    if button.has_meta("feedback_bound"):
        return
    button.set_meta("feedback_bound", true)
    button.button_down.connect(func():
        if is_instance_valid(button):
            button.modulate = Color(0.82, 0.86, 0.94, 1.0)
            Input.vibrate_handheld(18)
    )
    button.button_up.connect(func():
        if not is_instance_valid(button):
            return
        var tween := create_tween()
        tween.tween_property(button, "modulate", Color.WHITE, 0.12)
    )


func _remove_toast(panel: Control) -> void:
    active_toasts.erase(panel)
    if is_instance_valid(panel):
        panel.queue_free()


func _change_tone(id: String, delta: int) -> String:
    var improvement := delta < 0 if LOWER_IS_BETTER.has(id) else delta > 0
    return "good" if improvement else "bad"


func _tone_color(tone: String) -> Color:
    match tone:
        "success", "good": return COLOR_GOOD
        "failure", "bad": return COLOR_BAD
        "warning", "warn": return COLOR_WARN
        _: return COLOR_INFO


func _action_category_color(category: String) -> Color:
    match category:
        "self_improvement": return Color(0.86, 0.64, 0.26, 1.0)
        "economy": return Color(0.72, 0.56, 0.30, 1.0)
        "rumor": return Color(0.54, 0.46, 0.82, 1.0)
        "social": return Color(0.76, 0.36, 0.52, 1.0)
        "recovery": return Color(0.30, 0.68, 0.58, 1.0)
        "shop": return Color(0.42, 0.62, 0.78, 1.0)
        _: return COLOR_INFO


func _label(text: String, font_size: int) -> Label:
    var label := Label.new()
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", COLOR_TEXT)
    return label


func _style_confirmation_button(button: Button, accent: Color) -> void:
    button.add_theme_color_override("font_color", COLOR_TEXT)
    button.add_theme_color_override("font_hover_color", COLOR_TEXT)
    button.add_theme_stylebox_override("normal", _panel_style(Color(0.09, 0.065, 0.07, 0.98), Color(accent, 0.82), 2))
    button.add_theme_stylebox_override("hover", _panel_style(Color(0.16, 0.085, 0.09, 1.0), accent, 3))
    button.add_theme_stylebox_override("pressed", _panel_style(Color(0.055, 0.04, 0.045, 1.0), accent, 2))


func _panel_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(5)
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 7
    style.content_margin_bottom = 7
    return style
