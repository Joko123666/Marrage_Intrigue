extends RefCounted

const FILTER_NAMES := {
    "all": "전체",
    "contacts": "조력자",
    "candidates": "후보",
    "underworld": "뒷세계",
    "rumor": "소문",
}


func show(main: Control) -> void:
    main.current_screen = "characters"
    main._prepare_screen("인물")
    _add_filters(main)
    var characters: Array = DataManager.get_table("npcs").get("characters", [])
    var shown_count := 0
    for npc in characters:
        if typeof(npc) != TYPE_DICTIONARY:
            continue
        if int(npc.get("first_available_week", 1)) > GameState.week:
            continue
        if not _matches_filter(main.character_filter, npc):
            continue
        shown_count += 1
        _add_character_card(main, npc)
    if shown_count == 0:
        main._add_text("현재 필터에 표시할 인물이 없습니다.")


func _add_filters(main: Control) -> void:
    var row := HFlowContainer.new()
    row.add_theme_constant_override("h_separation", 6)
    row.add_theme_constant_override("v_separation", 6)
    main.content.add_child(row)
    for filter_id in ["all", "contacts", "candidates", "underworld", "rumor"]:
        var button := Button.new()
        main._style_button(button, main.character_filter == filter_id)
        button.text = String(FILTER_NAMES.get(filter_id, filter_id))
        var filter_copy := String(filter_id)
        button.pressed.connect(func():
            main.character_filter = filter_copy
            show(main)
        )
        row.add_child(button)


func _matches_filter(filter_id: String, npc: Dictionary) -> bool:
    if filter_id == "all":
        return true
    var role := String(npc.get("role", ""))
    var tags: Array = npc.get("interaction_tags", [])
    match filter_id:
        "candidates":
            return role.begins_with("candidate_") or npc.has("candidate_profile_id")
        "contacts":
            return not role.begins_with("candidate_")
        "underworld":
            return tags.has("underworld") or tags.has("removal_support") or role == "underworld_contact"
        "rumor":
            return tags.has("rumor") or tags.has("rumor_war") or tags.has("origin_attack") or tags.has("candidate_info")
    return true


func _add_character_card(main: Control, npc: Dictionary) -> void:
    var box: VBoxContainer = main._add_card()
    var row: BoxContainer = main._make_responsive_row(10)
    box.add_child(row)
    row.add_child(main._make_portrait(npc, Vector2(76, 96) if main._is_mobile_layout() else Vector2(92, 116)))

    var detail := VBoxContainer.new()
    detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    detail.add_theme_constant_override("separation", 5)
    row.add_child(detail)

    detail.add_child(main._make_label("%s  /  %s" % [npc.get("name_ko", npc.get("id", "")), main._role_name(String(npc.get("role", "")))], 16))
    detail.add_child(main._make_label(npc.get("public_summary_ko", ""), 13))
    if GameState.get_stat("information") >= 20:
        detail.add_child(main._make_label("비공개 단서: " + String(npc.get("private_summary_ko", "")), 12))
    main._add_chip_row(detail, "관계", GameState.get_relationship(String(npc.get("id", ""))), "relationship")
    _add_actions(main, detail, npc)


func _add_actions(main: Control, box: VBoxContainer, npc: Dictionary) -> void:
    var row := HFlowContainer.new()
    row.add_theme_constant_override("h_separation", 6)
    row.add_theme_constant_override("v_separation", 6)
    box.add_child(row)
    var npc_id := String(npc.get("id", ""))

    var talk_action := {
        "id": "character_talk",
        "name_ko": "대화",
        "target_npc_id": npc_id,
        "weeks": 1,
        "cost": {"fatigue": 1},
        "effects": {"fatigue": 1},
        "relationship_effects": {"favor": 2},
        "stat_influence": {
            "stats": {"social": 0.45, "grace": 0.3, "mask": 0.25},
            "reference_stat": 30,
            "fixed_effects": ["fatigue"],
        },
    }
    _add_action_button(main, row, talk_action, func():
        GameState.add_log(String(npc.get("name_ko", npc_id)) + "와 대화를 나눴습니다.")
    )

    var tags: Array = npc.get("interaction_tags", [])
    if tags.has("shop") or npc.has("inventory_pool"):
        var shop := Button.new()
        main._style_button(shop)
        shop.text = "거래"
        shop.tooltip_text = "상점을 엽니다. 상품 구매 전에는 시간과 관계가 변하지 않습니다."
        shop.pressed.connect(main._show_shop)
        row.add_child(shop)

    if tags.has("candidate_info") or npc.has("services"):
        var info_action := {
            "id": "character_buy_candidate_info",
            "name_ko": "후보 정보 구입",
            "target_npc_id": npc_id,
            "weeks": 1,
            "cost": {"cash": 2, "fatigue": 1},
            "effects": {"information": 4, "cash": -2, "fatigue": 1, "underworld_trace": 1},
            "relationship_effects": {"transaction_value": 5},
            "stat_influence": {
                "stats": {"information": 0.5, "social": 0.3, "mask": 0.2},
                "reference_stat": 35,
                "fixed_effects": ["cash", "fatigue"],
            },
        }
        _add_action_button(main, row, info_action, func():
            GameState.unlock_accessible_candidates(clampi(GameState.get_stat("information") * 4, 25, 90), 2)
        )

    if tags.has("origin_attack") or tags.has("rumor_war"):
        var placate_action := {
            "id": "character_placate_rival",
            "name_ko": "견제 완화",
            "target_npc_id": npc_id,
            "weeks": 1,
            "cost": {"information": 1, "fatigue": 2},
            "effects": {"information": -1, "fatigue": 2, "origin_rumor": -2},
            "relationship_effects": {"suspicion": -5},
            "stat_influence": {
                "stats": {"social": 0.4, "mask": 0.35, "information": 0.25},
                "reference_stat": 40,
                "fixed_effects": ["information", "fatigue"],
            },
        }
        var has_social_access := GameState.get_stat("social") >= 1 or GameState.get_stat("information") >= 8
        _add_action_button(main, row, placate_action, Callable(), has_social_access, "사교력 1 또는 정보력 8 필요")


func _add_action_button(
    main: Control,
    parent: Control,
    action: Dictionary,
    on_success: Callable = Callable(),
    additional_condition: bool = true,
    additional_blocker: String = ""
) -> void:
    var button := Button.new()
    main._style_button(button)
    var can_run := additional_condition and ActionResolver.can_run_action(action)
    button.text = "%s · 1주" % String(action.get("name_ko", "행동"))
    if not can_run:
        button.text = "불가: " + (additional_blocker if not additional_condition else ActionResolver.explain_blocker(action))
    button.disabled = not can_run
    var influence_text := ActionResolver.influence_summary(action)
    button.tooltip_text = ("능력 영향: " + influence_text + " / " if influence_text != "" else "") + "1주 소요"
    var action_copy := action.duplicate(true)
    button.pressed.connect(func():
        if ActionResolver.run_action(action_copy):
            if on_success.is_valid():
                on_success.call()
            show(main)
    )
    parent.add_child(button)
