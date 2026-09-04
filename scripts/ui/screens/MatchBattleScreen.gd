extends RefCounted

const OUTCOME_CALCULATOR := preload("res://scripts/systems/MatchOutcomeCalculator.gd")
const MOMENTUM_RIBBON := preload("res://scripts/ui/MatchMomentumRibbon.gd")
const PLAYER_PORTRAIT := "res://assets/art/protagonist_portrait.png"
const COLOR_TEXT := Color(0.95, 0.92, 0.84, 1.0)
const COLOR_INK := Color(0.20, 0.15, 0.10, 1.0)
const COLOR_PARCHMENT := Color(0.89, 0.80, 0.62, 0.98)
const COLOR_MUTED := Color(0.70, 0.68, 0.66, 1.0)
const COLOR_GOLD := Color(0.92, 0.68, 0.28, 1.0)
const COLOR_RED := Color(0.86, 0.20, 0.24, 1.0)
const COLOR_BLUE := Color(0.22, 0.48, 0.82, 1.0)
const AXES := ["favor", "interest", "trust", "comfort", "face", "political_value"]


func show(main: Control) -> void:
    main.current_screen = "match"
    main._prepare_match_screen()
    if GameState.current_match.is_empty():
        main._add_text("진행 중인 맞선이 없습니다.")
        return

    var state: Dictionary = GameState.current_match
    var candidate := DataManager.find_by_id("candidate_profiles", "candidate_profiles", String(state.get("candidate_id", "")))
    var npc := DataManager.find_by_id("npcs", "characters", String(candidate.get("character_id", "")))
    var shell := VBoxContainer.new()
    shell.name = "MatchBattleShell"
    shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    shell.add_theme_constant_override("separation", 8 if main._is_mobile_layout() else 10)
    main.content.add_child(shell)

    _add_phase_header(main, shell, state, candidate, npc)
    if String(state.get("result", "")) != "":
        _add_result_panel(main, shell, state, npc)
        _add_dialogue_box(main, shell, state, npc)
        _add_battlefield(main, shell, state, candidate, npc)
    else:
        _add_battlefield(main, shell, state, candidate, npc)
        _add_dialogue_box(main, shell, state, npc)
        _add_command_panel(main, shell, state, candidate)
    _animate_entry(main, shell)
    main._restore_pending_match_scroll()


func _add_phase_header(main: Control, parent: VBoxContainer, state: Dictionary, candidate: Dictionary, npc: Dictionary) -> void:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel_style(Color(0.075, 0.045, 0.028, 0.97), COLOR_GOLD, 2))
    parent.add_child(panel)
    var row := BoxContainer.new()
    row.vertical = main._is_mobile_layout()
    row.add_theme_constant_override("separation", 8)
    panel.add_child(row)

    var title: Label = main._make_label("◆  혼인 교섭  ◆", 18 if main._is_mobile_layout() else 22)
    title.add_theme_color_override("font_color", COLOR_GOLD)
    title.custom_minimum_size = Vector2(190, 0)
    row.add_child(title)

    var config: Dictionary = DataManager.get_table("match_config").get("default_match", {})
    var total := int(config.get("time_limit_turns", 8))
    var turns_left := int(state.get("turns_left", 0))
    var timeline := VBoxContainer.new()
    timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    timeline.add_theme_constant_override("separation", 2)
    row.add_child(timeline)
    var round_label: Label = main._make_label("대화 %d / %d   ·   %s   ·   %s %s" % [mini(total, total - turns_left + 1), total, TimeManager.calendar_text(GameState.week), main._rank_name(String(candidate.get("rank", ""))), npc.get("name_ko", "")], 14)
    round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    timeline.add_child(round_label)
    timeline.add_child(_make_turn_pips(main, total, turns_left))

    var turn_box := VBoxContainer.new()
    turn_box.custom_minimum_size = Vector2(150, 0)
    row.add_child(turn_box)
    var turn_value: Label = main._make_label("남은 대화  %02d" % turns_left, 17)
    turn_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if not main._is_mobile_layout() else HORIZONTAL_ALIGNMENT_LEFT
    turn_value.add_theme_color_override("font_color", COLOR_RED if turns_left <= 2 else COLOR_TEXT)
    turn_box.add_child(turn_value)
    var condition := _battle_condition(state, candidate)
    var condition_label: Label = main._make_label(String(condition.get("label", "")), 12)
    condition_label.horizontal_alignment = turn_value.horizontal_alignment
    condition_label.add_theme_color_override("font_color", Color(condition.get("color", COLOR_MUTED)))
    turn_box.add_child(condition_label)


func _make_turn_pips(main: Control, total: int, turns_left: int) -> Control:
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 5)
    var used := total - turns_left
    for i in range(total):
        var pip := ColorRect.new()
        pip.custom_minimum_size = Vector2(20 if not main._is_mobile_layout() else 14, 6)
        if i < used:
            pip.color = COLOR_GOLD
        elif i == used:
            pip.color = COLOR_RED
        else:
            pip.color = Color(0.30, 0.30, 0.34, 0.8)
        row.add_child(pip)
    return row


func _add_battlefield(main: Control, parent: VBoxContainer, state: Dictionary, candidate: Dictionary, npc: Dictionary) -> void:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel_style(Color(0.075, 0.045, 0.030, 0.88), Color(0.55, 0.42, 0.22, 0.75), 2))
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(panel)
    var field := BoxContainer.new()
    field.vertical = main._is_compact_layout()
    field.add_theme_constant_override("separation", 12)
    panel.add_child(field)

    if main._is_compact_layout():
        field.add_child(_make_fighter_panel(main, state, {}, candidate, true))
        field.add_child(_make_tactical_panel(main, state, candidate))
        field.add_child(_make_fighter_panel(main, state, npc, candidate, false))
    else:
        field.add_child(_make_fighter_panel(main, state, {}, candidate, true))
        field.add_child(_make_tactical_panel(main, state, candidate))
        field.add_child(_make_fighter_panel(main, state, npc, candidate, false))


func _make_fighter_panel(main: Control, state: Dictionary, npc: Dictionary, candidate: Dictionary, is_player: bool) -> Control:
    var reaction_accent := _turn_reaction_color(state)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(220, 0) if not main._is_compact_layout() else Vector2(0, 126)
    panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.075, 0.13, 0.94) if is_player else Color(0.20, 0.045, 0.06, 0.94), COLOR_GOLD if is_player or String(state.get("last_choice_name", "")) == "" else reaction_accent, 2))
    var box := BoxContainer.new()
    box.vertical = not main._is_compact_layout()
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)

    var portrait_size := Vector2(176, 205) if not main._is_compact_layout() else Vector2(92, 108)
    var match_expression := "neutral"
    var portrait: Control
    if is_player:
        portrait = main._make_portrait_from_path(PLAYER_PORTRAIT, portrait_size)
    else:
        match_expression = _match_expression_key(state)
        portrait = main._make_portrait_from_path(_match_portrait_path(npc, match_expression), portrait_size)
        portrait.set_meta("match_expression", match_expression)
    portrait.name = "MatchPlayerPortrait" if is_player else "MatchCandidatePortrait"
    if not is_player and String(state.get("last_choice_name", "")) != "":
        var match_portraits: Dictionary = npc.get("match_portraits", {})
        if not match_portraits.has(match_expression):
            portrait.modulate = _turn_portrait_tint(state)
    box.add_child(portrait)
    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.add_theme_constant_override("separation", 3)
    box.add_child(info)
    var side: Label = main._make_label("나의 입장" if is_player else "혼인 후보", 11)
    side.add_theme_color_override("font_color", Color(0.62, 0.78, 0.96, 1.0) if is_player else Color(0.94, 0.63, 0.56, 1.0))
    info.add_child(side)
    if String(state.get("last_choice_name", "")) != "":
        var cue: Label = main._make_label(_speaker_state_label(state, is_player), 11)
        cue.name = "MatchPlayerDeliveryState" if is_player else "MatchCandidateReactionState"
        cue.add_theme_color_override("font_color", _player_readiness_color(String(state.get("last_readiness_state", ""))) if is_player else reaction_accent)
        info.add_child(cue)
    var name := "당신" if is_player else String(npc.get("name_ko", candidate.get("id", "")))
    info.add_child(main._make_label(name, 19))
    if is_player:
        info.add_child(main._make_label("페르소나 · " + main._persona_display_name(), 12))
        info.add_child(main._make_label("화법 · " + main._voice_stage_display_name(), 12))
        var stats: Dictionary = GameState.player.get("stats", {})
        var fatigue := clampi(int(stats.get("fatigue", 0)), 0, 100)
        var vitality := 100 - fatigue
        var resources: Label = main._make_label("체력 %d / 100   ·   재화 %d" % [vitality, int(stats.get("cash", 0))], 14)
        resources.add_theme_color_override("font_color", Color(0.48, 0.88, 0.64, 1.0) if vitality >= 60 else Color(0.96, 0.66, 0.28, 1.0) if vitality >= 30 else Color(0.96, 0.34, 0.30, 1.0))
        info.add_child(resources)
        var vitality_bar := ProgressBar.new()
        vitality_bar.min_value = 0
        vitality_bar.max_value = 100
        vitality_bar.value = vitality
        vitality_bar.show_percentage = false
        vitality_bar.custom_minimum_size = Vector2(0, 7)
        info.add_child(vitality_bar)
        info.add_child(main._make_label("피로 %d   스트레스 %d" % [fatigue, int(stats.get("stress", 0))], 11))
    else:
        info.add_child(main._make_label("%s · 혼인 난도 %d" % [main._rank_name(String(candidate.get("rank", ""))), int(candidate.get("marriage_difficulty", 0))], 12))
        info.add_child(main._make_label(String(candidate.get("motivation_ko", "상대의 반응을 읽어야 한다.")), 11))
    return panel


func _make_tactical_panel(main: Control, state: Dictionary, candidate: Dictionary) -> Control:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PARCHMENT, Color(0.43, 0.29, 0.13, 0.95), 2))
    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 5)
    panel.add_child(box)
    var heading: Label = _ink_label(main, "교섭의 흐름", 16)
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(heading)
    var momentum_ribbon := MOMENTUM_RIBBON.new()
    momentum_ribbon.name = "MatchMomentumRibbon"
    momentum_ribbon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    momentum_ribbon.call("configure", state, main._is_compact_layout(), bool(ProjectSettings.get_setting("accessibility/reduce_motion", false)))
    box.add_child(momentum_ribbon)
    var gauges := VBoxContainer.new()
    gauges.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    gauges.add_theme_constant_override("separation", 4)
    box.add_child(gauges)
    var last_effects: Dictionary = state.get("last_effects", {})
    for axis_id in ["favor", "trust", "face", "political_value"]:
        _add_axis_gauge(main, gauges, String(axis_id), int(Dictionary(state.get("axes", {})).get(axis_id, 0)), int(last_effects.get(axis_id, 0)))

    var atmosphere := HBoxContainer.new()
    atmosphere.add_theme_constant_override("separation", 8)
    atmosphere.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_child(atmosphere)
    var axes: Dictionary = state.get("axes", {})
    var interest := _ink_label(main, "흥미 %d" % int(axes.get("interest", 0)), 11)
    interest.autowrap_mode = TextServer.AUTOWRAP_OFF
    interest.custom_minimum_size = Vector2(68, 0)
    interest.add_theme_color_override("font_color", Color(0.42, 0.22, 0.48, 1.0))
    atmosphere.add_child(interest)
    var divider := _ink_label(main, "·", 11)
    atmosphere.add_child(divider)
    var comfort := _ink_label(main, "안심 %d" % int(axes.get("comfort", 0)), 11)
    comfort.autowrap_mode = TextServer.AUTOWRAP_OFF
    comfort.custom_minimum_size = Vector2(68, 0)
    comfort.add_theme_color_override("font_color", Color(0.16, 0.38, 0.28, 1.0))
    atmosphere.add_child(comfort)

    var condition := _battle_condition(state, candidate)
    var forecast: Label = _ink_label(main, "예상 판정  %d / %d   ·   준비 보너스 %s" % [int(condition.get("score", 0)), int(condition.get("threshold", 0)), _signed_value(int(condition.get("prep", 0)))], 12)
    forecast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    forecast.add_theme_color_override("font_color", Color(condition.get("color", COLOR_TEXT)))
    box.add_child(forecast)
    var mood_text := _turn_reaction_label(state) if String(state.get("last_choice_name", "")) != "" else String(condition.get("label", "서로의 의중을 살피는 중입니다"))
    var mood: Label = _ink_label(main, "—  %s  —" % mood_text, 13)
    mood.name = "MatchAtmosphereSummary"
    mood.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    mood.add_theme_color_override("font_color", _turn_reaction_color(state) if String(state.get("last_choice_name", "")) != "" else Color(condition.get("color", COLOR_GOLD)))
    box.add_child(mood)
    return panel


func _add_axis_gauge(main: Control, parent: VBoxContainer, axis_id: String, value: int, turn_delta: int = 0) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 6)
    parent.add_child(row)
    var label: Label = _ink_label(main, main._name_for(axis_id), 11)
    label.custom_minimum_size = Vector2(62, 0)
    row.add_child(label)
    var bar := ProgressBar.new()
    bar.min_value = 0
    bar.max_value = 100
    bar.value = value
    bar.show_percentage = false
    bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bar.custom_minimum_size = Vector2(90, 11)
    bar.add_theme_stylebox_override("background", _flat_style(Color(0.25, 0.18, 0.10, 0.22), Color(0.43, 0.29, 0.13, 0.45), 1))
    var gauge_color := COLOR_RED if value < 10 else COLOR_GOLD if value < 50 else Color(0.25, 0.52, 0.35, 1.0)
    bar.add_theme_stylebox_override("fill", _flat_style(gauge_color, gauge_color, 0))
    row.add_child(bar)
    var number_text := "%02d" % value
    if turn_delta != 0:
        number_text += "  %s%d" % ["▲+" if turn_delta > 0 else "▼", turn_delta]
    var number: Label = _ink_label(main, number_text, 11)
    number.name = "MatchAxisDelta_" + axis_id
    number.custom_minimum_size = Vector2(58, 0)
    number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    number.add_theme_color_override("font_color", Color(0.22, 0.56, 0.34, 1.0) if turn_delta > 0 else COLOR_RED if turn_delta < 0 else gauge_color)
    row.add_child(number)


func _add_dialogue_box(main: Control, parent: VBoxContainer, state: Dictionary, npc: Dictionary) -> void:
    var panel := PanelContainer.new()
    var has_turn := String(state.get("last_choice_name", "")) != ""
    panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PARCHMENT, _turn_reaction_color(state) if has_turn else Color(0.43, 0.29, 0.13, 0.92), 3 if has_turn else 2))
    parent.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 3)
    panel.add_child(box)
    var last_choice := String(state.get("last_choice_name", ""))
    if last_choice == "":
        var opening: Label = _ink_label(main, "차가 식기 전, 어떤 인상을 남길지 결정해야 한다.", 15)
        box.add_child(opening)
        return
    var command_text := "이전 화제  ·  " + last_choice
    var readiness_state := String(state.get("last_readiness_state", ""))
    if readiness_state != "":
        command_text += "  ·  숙련 결과 " + _readiness_state_label(readiness_state)
    var command: Label = _ink_label(main, command_text, 11)
    command.add_theme_color_override("font_color", Color(0.45, 0.29, 0.12, 1.0))
    box.add_child(command)
    var net_effect := _last_turn_net(state)
    var flow: Label = _ink_label(main, "%s  ·  교섭 흐름 %s%d" % [_turn_reaction_label(state), "+" if net_effect > 0 else "", net_effect], 13)
    flow.name = "MatchTurnFlow"
    flow.add_theme_color_override("font_color", _turn_reaction_color(state))
    box.add_child(flow)
    var dialogue := String(state.get("last_dialogue", ""))
    if dialogue != "":
        box.add_child(_ink_label(main, "당신  “%s”" % dialogue, 15))
    var reaction := String(state.get("last_reaction", ""))
    if reaction != "":
        var response: Label = _ink_label(main, "%s  %s" % [npc.get("name_ko", "상대"), reaction], 13)
        response.add_theme_color_override("font_color", Color(0.46, 0.12, 0.14, 1.0))
        box.add_child(response)
    var effects: Dictionary = state.get("last_effects", {})
    if not effects.is_empty():
        main._add_chip_row(box, "이번 라운드", effects, "effect")


func _add_command_panel(main: Control, parent: VBoxContainer, state: Dictionary, candidate: Dictionary) -> void:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.040, 0.028, 0.98), COLOR_GOLD, 2))
    parent.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 7)
    panel.add_child(box)
    var heading: Label = main._make_label("다음 화제를 선택하십시오", 16)
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_color_override("font_color", Color(0.92, 0.76, 0.45, 1.0))
    box.add_child(heading)

    var grid := GridContainer.new()
    grid.columns = 1 if main._is_compact_layout() else 4
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 7)
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_child(grid)
    var choices: Array = main._all_match_choices(candidate)
    for i in range(choices.size()):
        var choice: Dictionary = choices[i]
        var effects: Dictionary = main._match_choice_effects(choice)
        var readiness: Dictionary = main._match_choice_soft_evaluation(choice)
        var button := Button.new()
        button.name = "MatchChoice_" + String(choice.get("id", i))
        button.custom_minimum_size = Vector2(0, 116 if main._is_mobile_layout() else 98)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.clip_text = true
        button.add_theme_font_size_override("font_size", 12)
        var title := String(choice.get("name_ko", choice.get("id", "")))
        if bool(choice.get("candidate_specific", false)):
            title += "  ◆전용"
        var affinity_hit := bool(main._match_choice_has_affinity(choice))
        if affinity_hit:
            title += "  ★취향 적중"
        var outcome_line := _effect_text(main, effects)
        var repeat_summary := String(main._match_choice_repeat_summary(choice))
        if repeat_summary != "":
            outcome_line = repeat_summary + "  ·  " + outcome_line
        var readiness_label := _choice_readiness_label(readiness)
        if readiness_label != "":
            outcome_line = readiness_label + "  ·  " + outcome_line
        var related: Array[String] = main.MATCH_CHOICE_CALCULATOR.related_stat_ids(choice, main._match_choice_tag_definitions(), GameState.player.get("stats", {}))
        var related_names: Array[String] = []
        for stat_id in related:
            related_names.append(main._name_for(stat_id))
        var skill := roundi(main.MATCH_CHOICE_CALCULATOR.choice_skill(choice, main._match_choice_tag_definitions(), GameState.player.get("stats", {})))
        var shortcut_hint := "[%d]  " % [i + 1] if i < 9 else ""
        button.text = "%s%s  %s\n%s" % [shortcut_hint, _choice_icon(choice.get("tags", [])), title, outcome_line]
        button.tooltip_text = "관련 능력: %s / 평균 %d" % [", ".join(related_names), skill]
        var requirement_summary: String = str(main._match_choice_requirement_summary(choice))
        if requirement_summary != "":
            button.tooltip_text += "\n권장 숙련: " + requirement_summary
        if main._is_mobile_layout():
            var skill_line := "관련 %s 평균 %d" % [", ".join(related_names), skill]
            if requirement_summary != "":
                skill_line += "  ·  권장 %s" % requirement_summary
            button.text += "\n" + skill_line
        match String(readiness.get("state", "stable")):
            "reduced":
                button.tooltip_text += "\n능력이 부족해 상승량이 줄거나 사라지고 부작용이 커집니다."
            "backfire":
                button.tooltip_text += "\n능력이 크게 부족해 긍정 효과가 하락으로 바뀔 수 있습니다."
        if affinity_hit:
            button.tooltip_text += "\n후보 취향 보너스: 좋은 효과 증가 · 부작용 감소"
        if repeat_summary != "":
            button.tooltip_text += "\n같은 화제를 되풀이하면 좋은 효과가 줄고 흥미·안심이 하락합니다."
        var accent := _choice_readiness_accent(_choice_accent(choice.get("tags", [])), readiness)
        _style_command_button(button, accent)
        main._bind_button_feedback(button)
        var can_run: bool = bool(main._match_choice_can_select(choice))
        button.disabled = not can_run
        if not can_run:
            button.text += "\n[서사 조건 잠김: %s]" % main._match_choice_blocker(choice)
        var choice_copy: Dictionary = choice
        button.pressed.connect(func(): main._apply_match_choice(choice_copy))
        grid.add_child(button)


func _add_result_panel(main: Control, parent: VBoxContainer, state: Dictionary, npc: Dictionary) -> void:
    var success := String(state.get("result", "")) == "success"
    var accent := Color(0.30, 0.78, 0.52, 1.0) if success else COLOR_RED
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PARCHMENT, accent, 3))
    parent.add_child(panel)
    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)
    var result_heading: Label = _ink_label(main, "교섭 성사" if success else "교섭 결렬", 24)
    result_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_heading.add_theme_color_override("font_color", accent)
    box.add_child(result_heading)
    var result_title := "%s의 결혼 의사를 얻었습니다" % npc.get("name_ko", "상대") if success else "혼인 협상이 결렬되었습니다"
    var title: Label = _ink_label(main, result_title, 17)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(title)
    var score: Label = _ink_label(main, "최종 판정  %d / %d   ·   준비 보너스 %s" % [int(state.get("final_score", 0)), int(state.get("result_threshold", 0)), _signed_value(int(state.get("prep_bonus", 0)))], 14)
    score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(score)
    var reason := String(state.get("failure_reason", ""))
    if reason != "":
        var reason_label: Label = _ink_label(main, reason, 12)
        reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        reason_label.add_theme_color_override("font_color", Color(0.95, 0.68, 0.62, 1.0))
        box.add_child(reason_label)
    var button := Button.new()
    button.text = "결혼식 준비로 이동  ▶" if success else "후보 목록으로 돌아가기  ▶"
    button.custom_minimum_size = Vector2(260, 44)
    button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    _style_command_button(button, accent)
    main._bind_button_feedback(button)
    button.pressed.connect(main._continue_match_result)
    box.add_child(button)


func _battle_condition(state: Dictionary, candidate: Dictionary) -> Dictionary:
    var axes: Dictionary = state.get("axes", {})
    var config := DataManager.get_table("match_config")
    var prep := GameState.candidate_preparation_bonus(candidate)
    var evaluation: Dictionary = OUTCOME_CALCULATOR.evaluate(axes, candidate, config, prep)
    var score := int(evaluation.get("score", 0))
    var threshold := int(evaluation.get("threshold", 62))
    if bool(evaluation.get("critical", false)):
        return {"label": "관계 균열 · 핵심 감정이 무너지고 있습니다", "color": COLOR_RED, "score": score, "threshold": threshold, "prep": prep}
    if score >= threshold:
        return {"label": "마음이 기울고 있습니다", "color": Color(0.25, 0.62, 0.40, 1.0), "score": score, "threshold": threshold, "prep": prep}
    return {"label": "서로의 의중을 살피는 중입니다", "color": COLOR_GOLD, "score": score, "threshold": threshold, "prep": prep}


func _signed_value(value: int) -> String:
    return "+%d" % value if value >= 0 else str(value)


func _effect_text(main: Control, effects: Dictionary) -> String:
    var parts: Array[String] = []
    for key in effects.keys():
        var value := int(effects[key])
        parts.append("%s %s%d" % [main._name_for(String(key)), "+" if value > 0 else "", value])
    return "   ".join(parts)


func _choice_accent(tags: Array) -> Color:
    if tags.has("wild") or tags.has("direct"):
        return Color(0.82, 0.20, 0.20, 1.0)
    if tags.has("etiquette") or tags.has("courtly"):
        return Color(0.28, 0.52, 0.88, 1.0)
    if tags.has("culture"):
        return Color(0.58, 0.36, 0.82, 1.0)
    if tags.has("mask") or tags.has("beauty"):
        return Color(0.82, 0.34, 0.58, 1.0)
    if tags.has("political"):
        return COLOR_GOLD
    return Color(0.40, 0.58, 0.72, 1.0)


func _choice_icon(tags: Array) -> String:
    if tags.has("political"):
        return "♞"
    if tags.has("culture") or tags.has("courtly"):
        return "✉"
    if tags.has("beauty") or tags.has("mask"):
        return "⚘"
    if tags.has("wild") or tags.has("direct"):
        return "◆"
    return "✦"


func _choice_readiness_label(evaluation: Dictionary) -> String:
    if not bool(evaluation.get("has_soft_requirements", false)):
        return ""
    match String(evaluation.get("state", "stable")):
        "backfire": return "역효과"
        "reduced": return "효과↓"
        _: return "충분"


func _readiness_state_label(state: String) -> String:
    match state:
        "backfire": return "역효과"
        "reduced": return "효과↓"
        _: return "충분"


func _choice_readiness_accent(base: Color, evaluation: Dictionary) -> Color:
    match String(evaluation.get("state", "stable")):
        "backfire": return Color(0.72, 0.12, 0.13, 1.0)
        "reduced": return Color(0.76, 0.48, 0.16, 1.0)
        _: return base


func _style_command_button(button: Button, accent: Color) -> void:
    button.add_theme_color_override("font_color", COLOR_INK)
    button.add_theme_color_override("font_hover_color", COLOR_INK)
    button.add_theme_color_override("font_disabled_color", Color(0.42, 0.38, 0.32, 1.0))
    button.add_theme_stylebox_override("normal", _panel_style(COLOR_PARCHMENT, Color(accent, 0.82), 2))
    button.add_theme_stylebox_override("hover", _panel_style(Color(0.96, 0.86, 0.65, 1.0), accent, 3))
    button.add_theme_stylebox_override("pressed", _panel_style(Color(0.76, 0.65, 0.46, 1.0), Color(0.43, 0.29, 0.13, 1.0), 2))
    button.add_theme_stylebox_override("disabled", _panel_style(Color(0.52, 0.48, 0.40, 0.88), Color(0.28, 0.25, 0.22, 1.0), 1))


func _animate_entry(main: Control, shell: Control) -> void:
    shell.modulate = Color(1, 1, 1, 0.35)
    shell.position.y += 8
    var tween := main.create_tween()
    tween.set_parallel(true)
    tween.tween_property(shell, "modulate", Color.WHITE, 0.18)
    tween.tween_property(shell, "position:y", shell.position.y - 8, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    var candidate_portrait := shell.find_child("MatchCandidatePortrait", true, false) as Control
    var player_portrait := shell.find_child("MatchPlayerPortrait", true, false) as Control
    if candidate_portrait == null or player_portrait == null or String(GameState.current_match.get("last_choice_name", "")) == "":
        return
    candidate_portrait.pivot_offset = candidate_portrait.size * 0.5
    player_portrait.pivot_offset = player_portrait.size * 0.5
    var target_modulate := candidate_portrait.modulate
    var net_effect := _last_turn_net(GameState.current_match)
    var readiness_state := String(GameState.current_match.get("last_readiness_state", ""))
    var is_negative := readiness_state == "backfire" or net_effect < 0
    var player_offset := 6.0 if is_negative else -6.0 if net_effect > 0 else 0.0
    var candidate_offset := -10.0 if is_negative else 10.0 if net_effect > 0 else 0.0
    player_portrait.position.x += player_offset
    candidate_portrait.position.x += candidate_offset
    candidate_portrait.scale = Vector2(0.98, 0.98) if is_negative else Vector2(0.965, 0.965) if net_effect > 0 else Vector2.ONE
    player_portrait.scale = Vector2(0.99, 0.99) if is_negative else Vector2(0.975, 0.975) if net_effect > 0 else Vector2.ONE
    candidate_portrait.modulate = Color(target_modulate.r, target_modulate.g, target_modulate.b, 0.62)
    var reaction_tween := main.create_tween()
    reaction_tween.set_parallel(true)
    reaction_tween.tween_property(candidate_portrait, "position:x", candidate_portrait.position.x - candidate_offset, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    reaction_tween.tween_property(player_portrait, "position:x", player_portrait.position.x - player_offset, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    reaction_tween.tween_property(candidate_portrait, "scale", Vector2.ONE, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    reaction_tween.tween_property(player_portrait, "scale", Vector2.ONE, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    reaction_tween.tween_property(candidate_portrait, "modulate", target_modulate, 0.30)


func _last_turn_net(state: Dictionary) -> int:
    var total := 0
    var effects: Dictionary = state.get("last_effects", {})
    for axis_id in AXES:
        total += int(effects.get(axis_id, 0))
    return total


func _turn_reaction_label(state: Dictionary) -> String:
    var readiness := String(state.get("last_readiness_state", ""))
    var net := _last_turn_net(state)
    if readiness == "backfire":
        return "실언이 공기를 얼렸습니다"
    if net >= 6:
        return "마음이 눈에 띄게 열렸습니다"
    if net > 0:
        return "호의가 조심스럽게 번집니다"
    if net < 0:
        return "상대의 경계가 짙어졌습니다"
    return "상대는 의중을 감춘 채 지켜봅니다"


func _speaker_state_label(state: Dictionary, is_player: bool) -> String:
    if is_player:
        match String(state.get("last_readiness_state", "")):
            "backfire": return "화법 · 실언의 여파"
            "reduced": return "화법 · 말끝의 흔들림"
            _: return "화법 · 자연스러운 주도"
    var net := _last_turn_net(state)
    if net >= 6:
        return "반응 · 마음이 열림"
    if net > 0:
        return "반응 · 호의"
    if net < 0:
        return "반응 · 경계"
    return "반응 · 관망"


func _player_readiness_color(readiness: String) -> Color:
    match readiness:
        "backfire": return COLOR_RED
        "reduced": return Color(0.96, 0.66, 0.28, 1.0)
        _: return Color(0.48, 0.82, 0.66, 1.0)


func _turn_reaction_color(state: Dictionary) -> Color:
    var readiness := String(state.get("last_readiness_state", ""))
    var net := _last_turn_net(state)
    if readiness == "backfire" or net < 0:
        return Color(0.78, 0.18, 0.20, 1.0)
    if net > 0:
        return Color(0.24, 0.58, 0.38, 1.0)
    return Color(0.70, 0.50, 0.20, 1.0)


func _match_expression_key(state: Dictionary) -> String:
    if String(state.get("last_choice_name", "")) == "":
        return "neutral"
    var readiness := String(state.get("last_readiness_state", ""))
    var net := _last_turn_net(state)
    if readiness == "backfire" or net < 0:
        return "wary"
    if net > 0:
        return "favorable"
    return "neutral"


func _match_portrait_path(npc: Dictionary, expression: String) -> String:
    var match_portraits: Dictionary = npc.get("match_portraits", {})
    var fallback := String(npc.get("portrait", ""))
    return String(match_portraits.get(expression, match_portraits.get("neutral", fallback)))


func _turn_portrait_tint(state: Dictionary) -> Color:
    var readiness := String(state.get("last_readiness_state", ""))
    var net := _last_turn_net(state)
    if readiness == "backfire" or net < 0:
        return Color(0.94, 0.76, 0.78, 1.0)
    if net > 0:
        return Color(1.0, 0.94, 0.82, 1.0)
    return Color(0.90, 0.90, 0.92, 1.0)


func _panel_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(4)
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    return style


func _flat_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(2)
    return style


func _ink_label(main: Control, text: String, size: int) -> Label:
    var label: Label = main._make_label(text, size)
    label.add_theme_color_override("font_color", COLOR_INK)
    return label
