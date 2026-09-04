extends RefCounted

func show(main: Control) -> void:
    main.current_screen = "free"
    main._prepare_screen("육성·생활 계획")
    main._add_text("행동을 마치면 짧은 생활 장면과 실제 변화가 표시됩니다. 현재 숙련과 컨디션에 따라 같은 훈련의 효율도 달라집니다.")
    _add_free_action_filters(main)
    var actions: Array = DataManager.get_table("free_actions").get("actions", [])
    for action in actions:
        if typeof(action) != TYPE_DICTIONARY:
            continue
        var action_dict: Dictionary = action
        if main.free_action_filter != "all" and String(action_dict.get("category", "")) != main.free_action_filter:
            continue
        var box: VBoxContainer = main._add_card()
        var title: Label = main._make_label("%s  %s" % [_category_icon(String(action_dict.get("category", ""))), action_dict.get("name_ko", action_dict.get("id", ""))], 17)
        title.add_theme_color_override("font_color", _category_color(String(action_dict.get("category", ""))))
        box.add_child(title)
        box.add_child(main._make_label("%d주 일정  ·  %s" % [int(action_dict.get("weeks", 1)), _category_scene_label(String(action_dict.get("category", "")))], 11))
        box.add_child(main._make_label(action_dict.get("summary_ko", ""), 13))
        main._add_chip_row(box, "현재 예상 효과", ActionResolver.adjusted_effects(action_dict), "effect")
        var evaluation: Dictionary = ActionResolver.evaluate_action(action_dict)
        var performance_text := _performance_text(evaluation)
        if performance_text != "":
            var performance: Label = main._make_label(performance_text, 12)
            performance.add_theme_color_override("font_color", _performance_color(evaluation))
            box.add_child(performance)
        var influence_text := ActionResolver.influence_summary(action_dict)
        if influence_text != "":
            box.add_child(main._make_label("능력 영향: " + influence_text, 12))
        var item_bonus_text := _item_bonus_text_for_action(action_dict)
        if item_bonus_text != "":
            box.add_child(main._make_label("장착 보정: " + item_bonus_text, 12))
        var button := Button.new()
        button.name = "FreeAction_" + String(action_dict.get("id", "unknown"))
        main._style_button(button)
        var opens_ui := String(action_dict.get("opens_ui", ""))
        var can_run := ActionResolver.can_run_action(action_dict)
        if can_run:
            button.text = "준비 후 상점으로" if opens_ui == "ShopScreen" else _action_button_text(String(action_dict.get("category", "")))
        else:
            button.text = "불가: " + ActionResolver.explain_blocker(action_dict)
        button.disabled = not can_run
        var action_copy: Dictionary = action_dict
        button.pressed.connect(func():
            if not ActionResolver.run_action(action_copy):
                return
            if String(action_copy.get("opens_ui", "")) == "ShopScreen":
                main.call_deferred("_show_shop")
            else:
                main.call_deferred("_show_free_actions")
        )
        box.add_child(button)


func _category_icon(category: String) -> String:
    match category:
        "self_improvement": return "✦"
        "economy": return "◆"
        "rumor": return "◈"
        "social": return "⚜"
        "recovery": return "☾"
        "shop": return "◇"
        _: return "·"


func _category_scene_label(category: String) -> String:
    match category:
        "self_improvement": return "성장의 시간"
        "economy": return "거리와 시장"
        "rumor": return "사람들의 뒷말"
        "social": return "사교의 무대"
        "recovery": return "고요한 생활실"
        "shop": return "거래와 준비"
        _: return "생활 기록"


func _category_color(category: String) -> Color:
    match category:
        "self_improvement": return Color(0.93, 0.72, 0.34, 1.0)
        "economy": return Color(0.82, 0.66, 0.40, 1.0)
        "rumor": return Color(0.67, 0.58, 0.92, 1.0)
        "social": return Color(0.90, 0.48, 0.64, 1.0)
        "recovery": return Color(0.42, 0.80, 0.68, 1.0)
        "shop": return Color(0.54, 0.72, 0.90, 1.0)
        _: return Color(0.90, 0.84, 0.72, 1.0)


func _performance_text(evaluation: Dictionary) -> String:
    if not bool(evaluation.get("enabled", false)):
        return "현재 수행감  ·  능력 영향 없음"
    var skill := roundi(float(evaluation.get("effective_skill", 0)))
    var reference := roundi(float(evaluation.get("reference_stat", 40)))
    var state := "수월" if skill >= reference + 15 else "안정" if skill >= reference else "버거움" if skill < reference - 12 else "도전"
    var condition := int(evaluation.get("condition_modifier", 0))
    var text := "현재 수행감  ·  %s  (효율 %d / 기준 %d)" % [state, skill, reference]
    if condition < 0:
        text += "  ·  피로·스트레스 %d" % condition
    return text


func _performance_color(evaluation: Dictionary) -> Color:
    if not bool(evaluation.get("enabled", false)):
        return Color(0.72, 0.70, 0.66, 1.0)
    var skill := float(evaluation.get("effective_skill", 0))
    var reference := float(evaluation.get("reference_stat", 40))
    if skill >= reference:
        return Color(0.46, 0.82, 0.60, 1.0)
    if skill < reference - 12:
        return Color(0.94, 0.46, 0.38, 1.0)
    return Color(0.94, 0.68, 0.30, 1.0)


func _action_button_text(category: String) -> String:
    match category:
        "self_improvement": return "훈련 시작  ▶"
        "economy": return "일하러 가기  ▶"
        "rumor": return "정보 활동 시작  ▶"
        "social": return "행사에 참석  ▶"
        "recovery": return "휴식하기  ▶"
        _: return "행동 시작  ▶"

func _add_free_action_filters(main: Control) -> void:
    var row := HFlowContainer.new()
    row.add_theme_constant_override("h_separation", 6)
    row.add_theme_constant_override("v_separation", 6)
    main.content.add_child(row)
    var categories := ["all", "economy", "self_improvement", "rumor", "social", "recovery", "shop"]
    for category in categories:
        var button := Button.new()
        main._style_button(button, main.free_action_filter == category)
        button.text = String(main.FREE_ACTION_CATEGORY_NAMES.get(category, category))
        var category_copy := String(category)
        button.pressed.connect(func():
            main.free_action_filter = category_copy
            main._show_free_actions()
        )
        row.add_child(button)

func _item_bonus_text_for_action(action: Dictionary) -> String:
    if String(action.get("id", "")) == "practice_etiquette":
        var bonus := GameState.equipped_effect_value("etiquette_training_bonus")
        if bonus > 0:
            return "예법 훈련 결과 예법/기품 +%d 추가" % bonus
    return ""
