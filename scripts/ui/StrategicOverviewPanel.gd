extends PanelContainer

const COLOR_GOLD := Color(0.92, 0.68, 0.28, 1.0)
const COLOR_BLUE := Color(0.38, 0.64, 0.88, 1.0)
const COLOR_GREEN := Color(0.38, 0.78, 0.54, 1.0)
const COLOR_RED := Color(0.88, 0.30, 0.32, 1.0)
const COLOR_MUTED := Color(0.70, 0.68, 0.66, 1.0)

var _main: Control
var _grid: GridContainer
var _header_row: BoxContainer
var _cards: Array[PanelContainer] = []

func setup(main: Control, progression: Dictionary) -> void:
    _main = main
    name = "StrategicOverviewPanel"
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_theme_stylebox_override("panel", _overview_style())

    var root_box := VBoxContainer.new()
    root_box.add_theme_constant_override("separation", 10)
    add_child(root_box)
    _add_header(root_box)

    _grid = GridContainer.new()
    _grid.name = "OverviewCardGrid"
    _grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _grid.add_theme_constant_override("h_separation", 9)
    _grid.add_theme_constant_override("v_separation", 9)
    root_box.add_child(_grid)

    _add_status_card(_grid)
    _add_goal_card(_grid, progression)
    _add_information_card(_grid)
    _add_alert_strip(root_box)
    resized.connect(update_responsive_layout)
    update_responsive_layout()

func _add_header(parent: VBoxContainer) -> void:
    _header_row = BoxContainer.new()
    _header_row.add_theme_constant_override("separation", 8)
    _header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(_header_row)
    var title_box := VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_box.add_theme_constant_override("separation", 2)
    _header_row.add_child(title_box)
    var title: Label = _main._make_label("전략 현황판", 20)
    title.add_theme_color_override("font_color", COLOR_GOLD)
    title_box.add_child(title)
    var subtitle: Label = _main._make_label("상태, 다음 목표, 확보한 정보를 한곳에서 확인합니다.", 12)
    subtitle.add_theme_color_override("font_color", COLOR_MUTED)
    title_box.add_child(subtitle)

    var condition := _overall_condition()
    var badge := Label.new()
    badge.name = "OverviewConditionBadge"
    badge.text = String(condition.get("label", "안정"))
    badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    badge.custom_minimum_size = Vector2(96, 34)
    badge.add_theme_font_size_override("font_size", 13)
    badge.add_theme_color_override("font_color", Color(condition.get("color", COLOR_GREEN)))
    badge.add_theme_stylebox_override("normal", _badge_style(Color(condition.get("color", COLOR_GREEN))))
    _header_row.add_child(badge)

func _add_status_card(parent: GridContainer) -> void:
    var box := _make_card(parent, "OverviewStatusCard", "현재 상태", COLOR_BLUE)
    _add_value_line(box, "진행 단계", _phase_text(), COLOR_BLUE)
    _add_value_line(box, "사회적 지위", _main._rank_name(GameState.current_social_rank()), COLOR_GOLD)
    _add_value_line(box, "시간", "%s · %d세" % [TimeManager.calendar_text(GameState.week), GameState.age_years], COLOR_MUTED)
    _add_value_line(box, "대사 단계", _main._voice_stage_display_name(), COLOR_MUTED)
    _add_value_line(box, "페르소나", _main._persona_display_name(), COLOR_MUTED)
    var age_penalty := GameState.marriage_market_age_penalty()
    if age_penalty > 0:
        _add_value_line(box, "혼인 압박", "준비 보너스 -%d" % age_penalty, COLOR_RED)

func _add_goal_card(parent: GridContainer, progression: Dictionary) -> void:
    var box := _make_card(parent, "OverviewGoalCard", "현재 목표", COLOR_GOLD)
    var objective := String(progression.get("objective", "핵심 루프를 완료했습니다."))
    var objective_label: Label = _main._make_label(objective, 13)
    objective_label.name = "OverviewGoalText"
    objective_label.add_theme_color_override("font_color", Color(0.96, 0.90, 0.78, 1.0))
    box.add_child(objective_label)

    var completed_steps := int(progression.get("completed_steps", 0))
    var total_steps := int(progression.get("total_steps", 0))
    var progress_label: Label = _main._make_label("튜토리얼 진행  %d / %d" % [mini(completed_steps, total_steps), total_steps], 11)
    progress_label.add_theme_color_override("font_color", COLOR_MUTED)
    box.add_child(progress_label)
    var progress := ProgressBar.new()
    progress.name = "OverviewGoalProgress"
    progress.min_value = 0
    progress.max_value = maxi(1, total_steps)
    progress.value = mini(completed_steps, total_steps)
    progress.show_percentage = false
    progress.custom_minimum_size = Vector2(0, 10)
    progress.add_theme_stylebox_override("background", _meter_style(Color(0.025, 0.026, 0.032, 0.95)))
    progress.add_theme_stylebox_override("fill", _meter_style(COLOR_GOLD))
    box.add_child(progress)

    var hint: Label = _main._make_label(String(progression.get("hint", "")), 11)
    hint.add_theme_color_override("font_color", COLOR_MUTED)
    box.add_child(hint)

    var action := _goal_action(String(progression.get("action_id", "free")))
    var button := Button.new()
    button.name = "OverviewGoalButton"
    button.text = String(progression.get("action_label", "확인")) + "  ▶"
    button.custom_minimum_size = Vector2(0, 38)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _main._style_button(button, true)
    _main._bind_button_feedback(button)
    var callback: Callable = action.get("callback", Callable())
    button.disabled = not callback.is_valid()
    if callback.is_valid():
        button.pressed.connect(callback)
    box.add_child(button)

func _add_information_card(parent: GridContainer) -> void:
    var box := _make_card(parent, "OverviewInformationCard", "확보 정보", COLOR_GREEN)
    var stats: Dictionary = GameState.player.get("stats", {})
    _add_value_line(box, "정보력", str(int(stats.get("information", 0))), COLOR_GREEN)
    _add_value_line(box, "혼인 후보", _candidate_information_text(), COLOR_MUTED)
    _add_value_line(box, "접근 인맥", "%d명" % _available_contact_count(), COLOR_MUTED, "OverviewContactCount")
    _add_value_line(box, "보유품", "%d개 · 장착 %d개" % [GameState.inventory.size(), GameState.equipped.size()], COLOR_MUTED)
    var threat := _highest_threat()
    _add_value_line(box, "최대 위험", "%s %d" % [_main._name_for(String(threat.get("id", "없음"))), int(threat.get("value", 0))], Color(threat.get("color", COLOR_GREEN)))
    if not GameState.active_case.is_empty():
        _add_value_line(box, "사건 파일", String(GameState.active_case.get("result_name", "진행 중")), COLOR_RED)

func _add_alert_strip(parent: VBoxContainer) -> void:
    var threat := _highest_threat()
    var text := "정보 브리핑: 즉시 대응이 필요한 위험은 낮습니다."
    var color := COLOR_GREEN
    if not GameState.active_case.is_empty():
        text = "긴급 브리핑: 사건 파일이 열려 있습니다. 조사·소문·증거 위험을 낮추십시오."
        color = COLOR_RED
    elif int(threat.get("value", 0)) >= 50:
        text = "주의 브리핑: %s 수치가 높습니다. 다음 행동 전에 위험 완화를 권장합니다." % _main._name_for(String(threat.get("id", "")))
        color = COLOR_RED
    elif int(threat.get("value", 0)) >= 30:
        text = "주의 브리핑: %s 수치가 상승 중입니다." % _main._name_for(String(threat.get("id", "")))
        color = COLOR_GOLD
    var panel := PanelContainer.new()
    panel.name = "OverviewAlertPanel"
    panel.add_theme_stylebox_override("panel", _alert_style(color))
    parent.add_child(panel)
    var label: Label = _main._make_label(text, 12)
    label.name = "OverviewAlertText"
    label.add_theme_color_override("font_color", color)
    panel.add_child(label)

func _make_card(parent: GridContainer, node_name: String, title_text: String, accent: Color) -> VBoxContainer:
    var panel := PanelContainer.new()
    panel.name = node_name
    panel.custom_minimum_size = Vector2(0, 208 if _main._is_mobile_layout() else 218 if _main._is_compact_layout() else 210)
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _card_style(accent))
    parent.add_child(panel)
    _cards.append(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 6)
    panel.add_child(box)
    var title_row := HBoxContainer.new()
    title_row.add_theme_constant_override("separation", 8)
    box.add_child(title_row)
    var marker := ColorRect.new()
    marker.color = accent
    marker.custom_minimum_size = Vector2(4, 18)
    marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
    title_row.add_child(marker)
    var title: Label = _main._make_label(title_text, 15)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_color_override("font_color", accent)
    title_row.add_child(title)
    return box

func _add_value_line(parent: VBoxContainer, label_text: String, value_text: String, color: Color, value_node_name: String = "") -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 6)
    row.custom_minimum_size.y = 21
    parent.add_child(row)
    var label: Label = _main._make_label(label_text, 11)
    label.custom_minimum_size = Vector2(72, 0)
    label.add_theme_color_override("font_color", COLOR_MUTED)
    row.add_child(label)
    var value: Label = _main._make_label(value_text, 12)
    if not value_node_name.is_empty():
        value.name = value_node_name
    value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    value.add_theme_color_override("font_color", color)
    row.add_child(value)

func _overall_condition() -> Dictionary:
    if not GameState.active_case.is_empty():
        var case_threat := _highest_threat()
        if int(case_threat.get("value", 0)) >= 70:
            return {"label": "위기", "color": COLOR_RED}
        return {"label": "사건 진행", "color": COLOR_GOLD}
    var stats: Dictionary = GameState.player.get("stats", {})
    var threat := _highest_threat()
    if int(stats.get("fatigue", 0)) >= 70 or int(stats.get("stress", 0)) >= 70 or int(threat.get("value", 0)) >= 60:
        return {"label": "위험", "color": COLOR_RED}
    if int(stats.get("fatigue", 0)) >= 45 or int(stats.get("stress", 0)) >= 50 or int(threat.get("value", 0)) >= 35:
        return {"label": "주의", "color": COLOR_GOLD}
    return {"label": "안정", "color": COLOR_GREEN}

func _phase_text() -> String:
    if not GameState.active_case.is_empty():
        return "사건 은폐"
    if bool(GameState.flags.get("married", false)):
        return "결혼 생활"
    if bool(GameState.flags.get("match_success_pending", false)):
        return "결혼식 준비"
    if not GameState.current_match.is_empty():
        return "맞선 진행"
    if bool(GameState.flags.get("case_resolved", false)):
        return "사건 종결"
    if not GameState.known_candidates.is_empty():
        return "혼인 준비"
    return "기반 구축"

func _goal_action(action_id: String) -> Dictionary:
    var methods := {
        "shop": "_show_shop",
        "rumors": "_show_rumors",
        "free": "_show_free_actions",
        "candidates": "_show_candidates",
        "match": "_show_match",
        "wedding": "_show_wedding",
        "spouse": "_show_spouse",
        "removal": "_show_removal",
        "coverup": "_show_coverup",
        "complete": "_show_vertical_slice_complete",
    }
    var method_name := String(methods.get(action_id, ""))
    return {"callback": Callable(_main, method_name) if not method_name.is_empty() else Callable()}

func _available_contact_count() -> int:
    var count := 0
    for npc in DataManager.get_table("npcs").get("characters", []):
        if typeof(npc) == TYPE_DICTIONARY and int(npc.get("first_available_week", 1)) <= GameState.week:
            count += 1
    return count

func update_responsive_layout() -> void:
    if _main == null or _grid == null or _header_row == null:
        return
    var mobile: bool = _main._is_mobile_layout()
    var compact: bool = _main._is_compact_layout()
    _grid.columns = 1 if mobile else 2 if compact else 3
    _header_row.vertical = mobile
    for card in _cards:
        if is_instance_valid(card):
            card.custom_minimum_size.y = 208 if mobile else 218 if compact else 210

func _overview_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.022, 0.034, 0.96)
    style.border_color = Color(0.72, 0.50, 0.22, 0.78)
    style.set_border_width_all(1)
    style.set_corner_radius_all(8)
    style.content_margin_left = 13
    style.content_margin_right = 13
    style.content_margin_top = 11
    style.content_margin_bottom = 11
    return style

func _card_style(accent: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(accent.r * 0.075, accent.g * 0.075, accent.b * 0.075, 0.94)
    style.border_color = Color(accent.r, accent.g, accent.b, 0.48)
    style.set_border_width_all(1)
    style.border_width_left = 3
    style.set_corner_radius_all(6)
    style.content_margin_left = 11
    style.content_margin_right = 11
    style.content_margin_top = 9
    style.content_margin_bottom = 9
    return style

func _badge_style(accent: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(accent.r * 0.12, accent.g * 0.12, accent.b * 0.12, 0.90)
    style.border_color = Color(accent.r, accent.g, accent.b, 0.58)
    style.set_border_width_all(1)
    style.set_corner_radius_all(12)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 5
    style.content_margin_bottom = 5
    return style

func _alert_style(accent: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(accent.r * 0.08, accent.g * 0.08, accent.b * 0.08, 0.78)
    style.border_color = Color(accent.r, accent.g, accent.b, 0.36)
    style.border_width_left = 3
    style.set_corner_radius_all(4)
    style.content_margin_left = 9
    style.content_margin_right = 9
    style.content_margin_top = 6
    style.content_margin_bottom = 6
    return style

func _meter_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(4)
    return style

func _candidate_information_text() -> String:
    if GameState.known_candidates.is_empty():
        return "미확보"
    var best_id := ""
    var best_quality := -1
    for candidate_id in GameState.known_candidates.keys():
        var quality := int(GameState.known_candidates.get(candidate_id, 0))
        if quality > best_quality:
            best_quality = quality
            best_id = String(candidate_id)
    var candidate := DataManager.find_by_id("candidate_profiles", "candidate_profiles", best_id)
    var npc := DataManager.find_by_id("npcs", "characters", String(candidate.get("character_id", "")))
    return "%d명 · 최고 %s %d" % [GameState.known_candidates.size(), String(npc.get("name_ko", best_id)), best_quality]

func _highest_threat() -> Dictionary:
    var highest := {"id": "social_suspicion", "value": 0, "color": COLOR_GREEN}
    var sources: Array[Dictionary] = [GameState.player.get("global_risks", {})]
    if not GameState.active_case.is_empty():
        sources.append(GameState.active_case)
    for source in sources:
        for risk_id in ["social_suspicion", "origin_rumor", "notoriety", "underworld_trace", "investigation_progress", "rumor_spread", "evidence_risk"]:
            if not source.has(risk_id):
                continue
            var value := int(source.get(risk_id, 0))
            if value > int(highest.get("value", 0)):
                highest = {"id": risk_id, "value": value, "color": COLOR_RED if value >= 50 else COLOR_GOLD if value >= 30 else COLOR_GREEN}
    return highest
