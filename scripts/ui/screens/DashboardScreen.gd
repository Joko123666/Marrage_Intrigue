extends RefCounted

const PLAYER_PORTRAIT := "res://assets/art/protagonist_portrait.png"
const STRATEGIC_OVERVIEW_PANEL := preload("res://scripts/ui/StrategicOverviewPanel.gd")
const PROGRESSION_OVERVIEW := preload("res://scripts/systems/ProgressionOverview.gd")
const COLOR_PARCHMENT := Color(0.89, 0.80, 0.62, 0.98)
const COLOR_PARCHMENT_DARK := Color(0.78, 0.66, 0.46, 0.98)
const COLOR_INK := Color(0.20, 0.15, 0.10, 1.0)
const COLOR_GOLD := Color(0.74, 0.52, 0.22, 1.0)
const COLOR_NAVY := Color(0.075, 0.12, 0.19, 0.96)
const COLOR_WINE := Color(0.28, 0.075, 0.10, 0.96)
const COLOR_GREEN := Color(0.25, 0.49, 0.34, 1.0)
const COLOR_MUTED := Color(0.68, 0.63, 0.56, 1.0)
const SCHEDULE_ACTION_IDS := [
    "street_errands",
    "train_beauty",
    "study_culture",
    "practice_etiquette",
    "gather_rumor",
    "rest_and_recover",
]


func show(main: Control) -> void:
    if GameState.flags.get("game_over", false):
        main._show_game_over()
        return
    main.current_screen = "dashboard"
    main._prepare_dashboard_screen()
    var progression: Dictionary = PROGRESSION_OVERVIEW.new().snapshot()
    _add_management_dashboard(main, progression)

    main._add_section("상세 전략 현황")
    _add_strategic_overview(main, progression)
    if GameState.flags.has("last_case_resolution"):
        main._add_text("최근 사건 종결: " + String(GameState.flags.get("last_case_resolution", "")))
    main._add_rank_event_summary()
    main._add_section("성장 여정")
    _add_tutorial_progress(main, int(progression.get("completed_steps", 0)))
    main._add_section("전체 수치")
    main._add_key_values(GameState.player.get("stats", {}), ["beauty", "culture", "grace", "etiquette", "wildness", "mask", "impulse_control", "cash", "information", "social", "influence", "status", "fatigue", "stress", "ambition"])
    main._add_section("저장")
    main._add_save_controls()


func _add_management_dashboard(main: Control, progression: Dictionary) -> void:
    var shell := VBoxContainer.new()
    shell.name = "DashboardHomeShell"
    shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    shell.add_theme_constant_override("separation", 8)
    main.content.add_child(shell)

    var row := BoxContainer.new()
    row.name = "DashboardManagementRow"
    row.vertical = main._is_compact_layout()
    row.set_meta("responsive_stack_width", main.COMPACT_WIDTH)
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 9)
    shell.add_child(row)

    row.add_child(_make_hero_panel(main, progression))
    row.add_child(_make_planning_panel(main, progression))
    row.add_child(_make_stat_book(main))
    shell.add_child(_make_action_ribbon(main))


func _make_hero_panel(main: Control, progression: Dictionary) -> Control:
    var panel := PanelContainer.new()
    panel.name = "DashboardHeroPanel"
    panel.custom_minimum_size = Vector2(292, 0)
    panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.055, 0.08, 0.94), COLOR_GOLD, 2))

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 6)
    panel.add_child(box)

    var hero_row := BoxContainer.new()
    hero_row.name = "DashboardHeroRow"
    hero_row.vertical = false
    hero_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_child(hero_row)

    var portrait := TextureRect.new()
    portrait.name = "DashboardHeroPortrait"
    portrait.texture = main._load_texture(PLAYER_PORTRAIT)
    portrait.custom_minimum_size = Vector2(270, 270) if not main._is_compact_layout() else Vector2(190, 210)
    portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if main._is_mobile_layout() else TextureRect.STRETCH_KEEP_ASPECT_COVERED
    hero_row.add_child(portrait)

    var eyebrow: Label = main._make_label("현재 생활 · 성장과 신분 상승", 11)
    eyebrow.name = "DashboardHeroEyebrow"
    eyebrow.add_theme_color_override("font_color", Color(0.55, 0.78, 0.66, 1.0))
    box.add_child(eyebrow)
    var title: Label = main._make_label("골목에서 궁정으로", 21)
    title.name = "DashboardHeroTitle"
    title.add_theme_color_override("font_color", Color(0.96, 0.78, 0.42, 1.0))
    box.add_child(title)
    var summary: Label = main._make_label("%d세 · %s" % [GameState.age_years, main._voice_stage_display_name()], 13)
    summary.name = "DashboardHeroSummary"
    box.add_child(summary)
    var persona: Label = main._make_label("현재 페르소나 · " + main._persona_display_name(), 12)
    persona.name = "DashboardHeroPersona"
    persona.add_theme_color_override("font_color", COLOR_MUTED)
    box.add_child(persona)
    var direction: Label = main._make_label("“%s”" % String(progression.get("objective", "다음 기회를 준비한다.")), 12)
    direction.add_theme_color_override("font_color", Color(0.84, 0.76, 0.62, 1.0))
    box.add_child(direction)
    return panel


func _make_planning_panel(main: Control, progression: Dictionary) -> Control:
    var panel := PanelContainer.new()
    panel.name = "DashboardPlanningPanel"
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.045, 0.035, 0.94), COLOR_GOLD, 2))

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 7)
    panel.add_child(box)
    box.add_child(_make_objective_card(main, progression))

    var schedule_title: Label = main._make_label("주간 일정 · 최대 3개 행동 예약", 16)
    schedule_title.add_theme_color_override("font_color", Color(0.96, 0.78, 0.42, 1.0))
    box.add_child(schedule_title)

    var slots := BoxContainer.new()
    slots.name = "DashboardScheduleSlots"
    slots.vertical = main._is_mobile_layout()
    slots.add_theme_constant_override("separation", 6)
    slots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_child(slots)
    for index in range(main.DASHBOARD_SCHEDULE_MAX):
        slots.add_child(_make_schedule_slot(main, index))

    var schedule_preview := _schedule_preview(main)
    if not schedule_preview.is_empty():
        main._add_chip_row(
            box,
            "현재 기준 일정 합계 · %d주" % int(schedule_preview.get("weeks", 0)),
            schedule_preview.get("effects", {}),
            "effect"
        )

    var palette := HFlowContainer.new()
    palette.name = "DashboardSchedulePalette"
    palette.add_theme_constant_override("h_separation", 5)
    palette.add_theme_constant_override("v_separation", 5)
    box.add_child(palette)
    for action_id in SCHEDULE_ACTION_IDS:
        var action: Dictionary = main._free_action_by_id(action_id)
        if action.is_empty():
            continue
        var button := Button.new()
        main._style_button(button)
        button.text = "+ %s · %d주" % [action.get("name_ko", action_id), int(action.get("weeks", 1))]
        button.disabled = main.dashboard_schedule.size() >= main.DASHBOARD_SCHEDULE_MAX or not ActionResolver.can_run_action(action)
        if button.disabled and not ActionResolver.can_run_action(action):
            button.tooltip_text = ActionResolver.explain_blocker(action)
        var action_copy := String(action_id)
        button.pressed.connect(func(): main._queue_dashboard_action(action_copy))
        palette.add_child(button)

    var controls := HBoxContainer.new()
    controls.add_theme_constant_override("separation", 7)
    box.add_child(controls)
    var clear_button := Button.new()
    main._style_button(clear_button)
    clear_button.text = "일정 비우기"
    clear_button.disabled = main.dashboard_schedule.is_empty()
    clear_button.pressed.connect(main._clear_dashboard_schedule)
    controls.add_child(clear_button)
    var confirm_button := Button.new()
    confirm_button.name = "DashboardScheduleConfirm"
    confirm_button.text = "일정 확정 · 실행"
    confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    confirm_button.custom_minimum_size = Vector2(0, 42)
    _style_primary_button(confirm_button)
    main._bind_button_feedback(confirm_button)
    confirm_button.disabled = main.dashboard_schedule.is_empty()
    confirm_button.pressed.connect(main._confirm_dashboard_schedule)
    controls.add_child(confirm_button)

    var adviser := PanelContainer.new()
    adviser.add_theme_stylebox_override("panel", _panel_style(Color(0.10, 0.075, 0.055, 0.96), Color(0.46, 0.34, 0.20, 1.0), 1))
    box.add_child(adviser)
    var advice: Label = main._make_label("조언 · " + String(progression.get("hint", "다음 목표에 필요한 능력을 집중해서 준비하십시오.")), 11)
    advice.add_theme_color_override("font_color", Color(0.86, 0.79, 0.68, 1.0))
    adviser.add_child(advice)
    return panel


func _make_objective_card(main: Control, progression: Dictionary) -> Control:
    var card := PanelContainer.new()
    card.name = "DashboardMonthlyGoal"
    card.add_theme_stylebox_override("panel", _panel_style(COLOR_PARCHMENT, Color(0.43, 0.29, 0.13, 1.0), 2))
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 5)
    card.add_child(box)
    box.add_child(_ink_label(main, "이번 달의 목표", 17))
    box.add_child(_ink_label(main, String(progression.get("objective", "다음 목표를 준비합니다.")), 13))
    var total := maxi(1, int(progression.get("total_steps", 1)))
    var completed := int(progression.get("completed_steps", 0))
    var progress := ProgressBar.new()
    progress.name = "DashboardGoalProgress"
    progress.max_value = total
    progress.value = completed
    progress.show_percentage = false
    progress.custom_minimum_size = Vector2(0, 8)
    progress.add_theme_stylebox_override("background", _bar_style(Color(0.25, 0.18, 0.10, 0.28)))
    progress.add_theme_stylebox_override("fill", _bar_style(COLOR_GOLD))
    box.add_child(progress)
    var row := HBoxContainer.new()
    box.add_child(row)
    var count := _ink_label(main, "성장 여정 %d / %d" % [completed, total], 11)
    count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(count)
    var button := Button.new()
    main._style_button(button)
    button.text = String(progression.get("action_label", "바로가기"))
    var action_id := String(progression.get("action_id", "free"))
    button.pressed.connect(func(): main._open_progression_action(action_id))
    row.add_child(button)
    return card


func _make_schedule_slot(main: Control, index: int) -> Control:
    var card := PanelContainer.new()
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.custom_minimum_size = Vector2(0, 66)
    card.add_theme_stylebox_override("panel", _panel_style(Color(0.82, 0.73, 0.56, 0.98), Color(0.43, 0.29, 0.13, 0.92), 1))
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 2)
    card.add_child(box)
    box.add_child(_ink_label(main, "%d번째 일정" % [index + 1], 10))
    if index >= main.dashboard_schedule.size():
        var empty := _ink_label(main, "비어 있음", 13)
        empty.add_theme_color_override("font_color", Color(0.43, 0.36, 0.28, 0.72))
        box.add_child(empty)
        return card
    var action: Dictionary = main._free_action_by_id(String(main.dashboard_schedule[index]))
    box.add_child(_ink_label(main, String(action.get("name_ko", main.dashboard_schedule[index])), 13))
    var remove := Button.new()
    remove.text = "일정 취소"
    remove.flat = true
    remove.add_theme_color_override("font_color", Color(0.42, 0.15, 0.12, 1.0))
    var index_copy := index
    remove.pressed.connect(func(): main._remove_dashboard_schedule_action(index_copy))
    box.add_child(remove)
    return card


func _make_stat_book(main: Control) -> Control:
    var panel := PanelContainer.new()
    panel.name = "DashboardStatBook"
    panel.custom_minimum_size = Vector2(282, 0)
    panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PARCHMENT, Color(0.43, 0.29, 0.13, 1.0), 2))
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 6)
    panel.add_child(box)

    var tabs := HBoxContainer.new()
    tabs.add_theme_constant_override("separation", 3)
    box.add_child(tabs)
    var tab_defs := {"ability": "능력", "reputation": "평판", "risk": "위험"}
    for tab_id in tab_defs.keys():
        var button := Button.new()
        main._style_button(button, main.dashboard_book_tab == tab_id)
        button.text = String(tab_defs[tab_id])
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var tab_copy := String(tab_id)
        button.pressed.connect(func(): main._set_dashboard_book_tab(tab_copy))
        tabs.add_child(button)

    var source: Dictionary = GameState.player.get("stats", {})
    var keys := ["beauty", "culture", "grace", "etiquette", "wildness", "mask", "impulse_control"]
    if main.dashboard_book_tab == "reputation":
        keys = ["cash", "information", "social", "influence", "status", "ambition"]
    elif main.dashboard_book_tab == "risk":
        source = GameState.player.get("global_risks", {}).duplicate(true)
        source["fatigue"] = GameState.get_stat("fatigue")
        source["stress"] = GameState.get_stat("stress")
        keys = ["social_suspicion", "origin_rumor", "notoriety", "underworld_trace", "fatigue", "stress"]
    for key in keys:
        _add_book_meter(main, box, String(key), int(source.get(key, 0)), main.dashboard_book_tab == "risk")
    return panel


func _add_book_meter(main: Control, parent: VBoxContainer, stat_id: String, value: int, danger: bool) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 5)
    parent.add_child(row)
    var label := _ink_label(main, main._name_for(stat_id), 11)
    label.custom_minimum_size = Vector2(65, 0)
    row.add_child(label)
    var bar := ProgressBar.new()
    bar.max_value = 100
    bar.value = clampi(value, 0, 100)
    bar.show_percentage = false
    bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bar.custom_minimum_size = Vector2(82, 9)
    bar.add_theme_stylebox_override("background", _bar_style(Color(0.25, 0.18, 0.10, 0.25)))
    var fill := Color(0.55, 0.15, 0.16, 1.0) if danger and value >= 35 else COLOR_GREEN if danger else Color(0.18, 0.34, 0.54, 1.0)
    bar.add_theme_stylebox_override("fill", _bar_style(fill))
    row.add_child(bar)
    var number := _ink_label(main, "%02d" % value, 11)
    number.custom_minimum_size = Vector2(27, 0)
    number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    row.add_child(number)


func _make_action_ribbon(main: Control) -> Control:
    var panel := PanelContainer.new()
    panel.name = "DashboardActionRibbon"
    panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.045, 0.035, 0.97), COLOR_GOLD, 2))
    var row := HFlowContainer.new()
    row.add_theme_constant_override("h_separation", 6)
    row.add_theme_constant_override("v_separation", 6)
    panel.add_child(row)
    var actions := [
        ["자유행동", main._show_free_actions],
        ["인물", main._show_characters],
        ["소문", main._show_rumors],
        ["후보", main._show_candidates],
        ["상점", main._show_shop],
        ["페르소나", main._show_personas],
    ]
    for entry in actions:
        var button := Button.new()
        main._style_button(button)
        button.text = String(entry[0])
        button.custom_minimum_size = Vector2(118, 42)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var callback: Callable = entry[1]
        button.pressed.connect(callback)
        row.add_child(button)
    return panel


func _add_strategic_overview(main: Control, progression: Dictionary) -> void:
    var overview: PanelContainer = STRATEGIC_OVERVIEW_PANEL.new()
    overview.setup(main, progression)
    main.content.add_child(overview)


func _add_tutorial_progress(main: Control, completed_count: int) -> void:
    var tutorial := DataManager.get_table("tutorial_flow")
    var steps: Array = tutorial.get("steps", [])
    if steps.is_empty():
        return
    var box: VBoxContainer = main._add_card()
    box.add_child(main._make_label(String(tutorial.get("goal_ko", "기사 튜토리얼 흐름")), 13))
    for i in range(steps.size()):
        var step: Dictionary = steps[i]
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        box.add_child(row)
        var state := "대기"
        var state_color := COLOR_MUTED
        if i < completed_count:
            state = "완료"
            state_color = Color(0.58, 0.82, 0.48, 1.0)
        elif i == completed_count:
            state = "진행"
            state_color = COLOR_GOLD
        var badge: Label = main._make_label(state, 12)
        badge.custom_minimum_size = Vector2(44, 0)
        badge.add_theme_color_override("font_color", state_color)
        row.add_child(badge)
        var objective: Label = main._make_label(String(step.get("objective_ko", step.get("id", ""))), 12)
        objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        if i > completed_count:
            objective.add_theme_color_override("font_color", COLOR_MUTED)
        row.add_child(objective)


func _schedule_preview(main: Control) -> Dictionary:
    if main.dashboard_schedule.is_empty():
        return {}
    var weeks := 0
    var effects: Dictionary = {}
    for action_id in main.dashboard_schedule:
        var action: Dictionary = main._free_action_by_id(String(action_id))
        if action.is_empty():
            continue
        weeks += int(action.get("weeks", 1))
        var adjusted: Dictionary = ActionResolver.adjusted_effects(action)
        for raw_id in adjusted.keys():
            var id := String(raw_id)
            effects[id] = int(effects.get(id, 0)) + int(adjusted[raw_id])
    return {"weeks": weeks, "effects": effects}


func _ink_label(main: Control, text: String, size: int) -> Label:
    var label: Label = main._make_label(text, size)
    label.add_theme_color_override("font_color", COLOR_INK)
    return label


func _style_primary_button(button: Button) -> void:
    button.add_theme_color_override("font_color", Color(0.98, 0.91, 0.76, 1.0))
    button.add_theme_color_override("font_disabled_color", Color(0.55, 0.48, 0.39, 1.0))
    button.add_theme_stylebox_override("normal", _panel_style(COLOR_WINE, COLOR_GOLD, 2))
    button.add_theme_stylebox_override("hover", _panel_style(Color(0.43, 0.10, 0.12, 1.0), Color(0.95, 0.75, 0.35, 1.0), 3))
    button.add_theme_stylebox_override("pressed", _panel_style(Color(0.20, 0.045, 0.06, 1.0), COLOR_GOLD, 2))
    button.add_theme_stylebox_override("disabled", _panel_style(Color(0.13, 0.11, 0.09, 0.88), Color(0.29, 0.24, 0.18, 1.0), 1))


func _panel_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(5)
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    return style


func _bar_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(2)
    return style
