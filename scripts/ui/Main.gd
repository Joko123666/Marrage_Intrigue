extends Control

var root: VBoxContainer
var header_row: BoxContainer
var header_title_panel: PanelContainer
var header_label: Label
var calendar_panel: PanelContainer
var calendar_box: BoxContainer
var calendar_date_label: Label
var calendar_week_label: Label
var resource_row: BoxContainer
var cash_card: Control
var vitality_card: Control
var page_margin: MarginContainer
var nav_bar: HFlowContainer
var body: BoxContainer
var main_scroll: ScrollContainer
var log_frame: PanelContainer
var log_panel: VBoxContainer
var log_title: Label
var log_toggle_button: Button
var content: VBoxContainer
var log_list: ItemList
var dashboard_screen: RefCounted
var free_actions_screen: RefCounted
var shop_screen: RefCounted
var characters_screen: RefCounted
var match_battle_screen: RefCounted
var match_backdrop: Control
var feedback_layer: Control
var current_screen: String = "dashboard"
var texture_cache: Dictionary = {}
var free_action_filter: String = "all"
var character_filter: String = "all"
var candidate_rank_filter: String = "all"
var candidate_sort_mode: String = "rank"
var pending_removal_confirmation_id: String = ""
var dashboard_schedule: Array[String] = []
var dashboard_book_tab: String = "ability"
var schedule_execution_in_progress: bool = false
var match_stat_refresh_pending: bool = false
var compact_log_expanded: bool = false
var pending_match_scroll_restore: int = -1
const DASHBOARD_SCHEDULE_MAX := 3
const COMPACT_WIDTH := 980
const MOBILE_WIDTH := 700

const BG_IMAGE := "res://assets/art/manor_corridor_bg.png"
const PLAYER_PORTRAIT := "res://assets/art/protagonist_portrait.png"
const UI_DIVIDER := "res://assets/art/ui/medieval_divider.png"
const UI_CARD_TRIM := "res://assets/art/ui/medieval_card_trim.png"
const UI_PANEL_TEXTURE := "res://assets/art/ui/medieval_panel_texture.png"
const DASHBOARD_SCREEN := preload("res://scripts/ui/screens/DashboardScreen.gd")
const FREE_ACTIONS_SCREEN := preload("res://scripts/ui/screens/FreeActionsScreen.gd")
const SHOP_SCREEN := preload("res://scripts/ui/screens/ShopScreen.gd")
const CHARACTERS_SCREEN := preload("res://scripts/ui/screens/CharactersScreen.gd")
const MATCH_BATTLE_SCREEN := preload("res://scripts/ui/screens/MatchBattleScreen.gd")
const MATCH_BATTLE_BACKDROP := preload("res://scripts/ui/MatchBattleBackdrop.gd")
const UI_FEEDBACK_LAYER := preload("res://scripts/ui/UiFeedbackLayer.gd")
const RESOURCE_HUD_CARD := preload("res://scripts/ui/ResourceHudCard.gd")
const MATCH_RADAR_CHART := preload("res://scripts/ui/MatchRadarChart.gd")
const MATCH_CHOICE_CALCULATOR := preload("res://scripts/systems/MatchChoiceCalculator.gd")
const MATCH_OUTCOME_CALCULATOR := preload("res://scripts/systems/MatchOutcomeCalculator.gd")
const MATCH_DIALOGUE_CONTEXT_ALIASES := {
    "honest_interest": "match_interest",
    "polite_listen": "match_interest",
    "culture_quote": "match_interest",
    "masked_affection": "match_interest",
    "political_value_offer": "match_interest",
}
const COLOR_PANEL := Color(0.055, 0.045, 0.04, 0.82)
const COLOR_PANEL_LIGHT := Color(0.13, 0.105, 0.085, 0.88)
const COLOR_STROKE := Color(0.68, 0.48, 0.22, 0.55)
const COLOR_TEXT := Color(0.92, 0.88, 0.8, 1.0)
const COLOR_MUTED := Color(0.68, 0.63, 0.56, 1.0)
const COLOR_RED := Color(0.52, 0.1, 0.12, 1.0)
const COLOR_GOLD := Color(0.74, 0.52, 0.22, 1.0)
const RISK_VALUE_IDS := {
    "social_suspicion": true,
    "origin_rumor": true,
    "notoriety": true,
    "underworld_trace": true,
    "fatigue": true,
    "stress": true,
    "direct_suspicion": true,
    "threat_alert": true,
    "investigation_progress": true,
    "rumor_spread": true,
    "evidence_risk": true,
    "risk_score": true,
}

const STAT_NAMES := {
    "beauty": "외모",
    "culture": "교양",
    "grace": "기품",
    "etiquette": "예법",
    "wildness": "야성",
    "mask": "가면술",
    "impulse_control": "충동제어",
    "cash": "자금",
    "funds_power": "배경자금",
    "information": "정보력",
    "social": "사교력",
    "influence": "영향력",
    "status": "신분",
    "fatigue": "피로",
    "stress": "스트레스",
    "ambition": "야망",
    "social_suspicion": "사회적 의심",
    "origin_rumor": "출신 소문",
    "notoriety": "악명",
    "underworld_trace": "뒷세계 흔적",
    "favor": "호감",
    "interest": "흥미",
    "trust": "신뢰",
    "comfort": "안심",
    "face": "체면",
    "political_value": "정략 가치",
    "health": "건강",
    "affection": "애정",
    "direct_suspicion": "직접 의심",
    "threat_alert": "경계도",
    "public_harmony": "공개 금슬",
    "investigation_progress": "조사",
    "rumor_spread": "소문",
    "evidence_risk": "증거",
    "alibi_strength": "알리바이",
    "public_grief": "공개 서사",
    "respect": "존중",
    "transaction_value": "거래 가치",
    "fear": "공포",
    "loyalty": "충성",
    "suspicion": "의심",
    "debt": "빚",
    "leverage": "약점",
    "etiquette_training_bonus": "예법 훈련 보너스",
    "public_mourning": "공개 애도",
    "family_scrutiny": "가문 감시",
    "security_level": "보안 수준",
    "success_modifier": "성공률",
    "case_type": "후폭풍 유형",
    "risk_score": "위험도",
}

const SLOT_NAMES := {
    "outfit": "의상",
    "accessory": "장신구",
    "tool": "도구",
    "misc": "기타",
}

const FREE_ACTION_CATEGORY_NAMES := {
    "all": "전체",
    "economy": "자금",
    "self_improvement": "성장",
    "rumor": "소문",
    "social": "사교",
    "recovery": "회복",
    "shop": "상점",
}

const CANDIDATE_SORT_NAMES := {
    "rank": "작위순",
    "quality": "정보순",
    "difficulty": "난도순",
    "security": "보안순",
}

const ROLE_NAMES := {
    "merchant_tailor": "재단사",
    "information_broker": "정보상",
    "underworld_contact": "뒷세계 중개인",
    "candidate_knight_tutorial": "기사 후보",
    "candidate_knight": "기사 후보",
    "candidate_baron": "남작 후보",
    "candidate_viscount": "자작 후보",
    "candidate_count": "백작 후보",
    "candidate_marquis": "후작 후보",
    "candidate_duke": "공작 후보",
    "servant_maid": "하녀",
    "social_rival": "사교 라이벌",
}

const RANK_NAMES := {
    "knight": "기사",
    "baron": "남작",
    "viscount": "자작",
    "count": "백작",
    "marquis": "후작",
    "duke": "공작",
    "royal": "왕족",
}

const FACTION_NAMES := {
    "minor_knightly_house": "몰락한 기사 가문",
    "rural_baron_house": "지방 남작가",
    "border_knightly_house": "국경 기사 가문",
    "tournament_circuit": "마상시합 후원권",
    "orchard_baron_house": "과수원 남작가",
    "old_chapel_estate": "옛 예배당 영지",
    "court_records_office": "궁정 기록원 가문",
    "river_trade_house": "강변 무역가",
    "academy_patronage": "학술 후원 가문",
    "old_count_house": "오래된 백작가",
    "military_supply_house": "군수 계약 가문",
    "salon_patron_house": "살롱 후원 가문",
    "western_march": "서부 변경 파벌",
    "court_faction_red": "붉은 궁정 파벌",
    "eastern_grain_league": "동부 곡물 동맹",
    "northern_duchy": "북부 공작가",
    "southern_diplomatic_house": "남부 외교 가문",
    "capital_guard_duchy": "수도 방위 공작가",
}

const TRAIT_NAMES := {
    "honor_bound": "명예 중시",
    "drawn_to_wildness": "야성에 끌림",
    "physically_resilient": "신체적으로 강인함",
    "vain": "허영심",
    "rural_power": "지방 기반",
    "hidden_money": "숨은 자금",
    "debt_pressure": "채무 압박",
    "wary_household": "저택 경계",
    "tournament_pride": "마상시합 자부심",
    "ledger_sensitive": "장부에 민감함",
    "pious_reputation": "신앙 평판",
    "household_watch": "하인 감시",
    "widower": "홀아비",
    "archive_power": "기록 권한",
    "procedural_mind": "절차주의",
    "secretive": "비밀주의",
    "trade_network": "무역망",
    "bribe_rumor": "뇌물 소문",
    "salon_taste": "살롱 취향",
    "uncle_regency": "숙부 섭정",
    "idealistic": "이상주의",
    "bloodline_pride": "혈통 자부심",
    "succession_dispute": "후계 다툼",
    "war_contracts": "군수 계약",
    "blackmail_tolerant": "협박 거래 허용",
    "dangerous_pragmatist": "위험한 실리주의",
    "salon_patron": "살롱 후원자",
    "reputation_sensitive": "평판에 민감함",
    "public_harmony_focused": "공개 금슬 중시",
    "marcher_army": "변경군 지휘",
    "royal_watch": "왕실 감시",
    "faction_leader": "파벌 수장",
    "court_intriguer": "궁정 모략가",
    "blackmail_network": "협박망",
    "grain_league": "곡물 동맹",
    "famine_blame": "기근 책임",
    "ducal_house": "공작가",
    "near_royal_protocol": "준왕족 의전",
    "foreign_ties": "외교 연줄",
    "diplomatic_web": "외교망",
    "capital_guard": "수도 방위권",
}

func _ready() -> void:
    randomize()
    dashboard_screen = DASHBOARD_SCREEN.new()
    free_actions_screen = FREE_ACTIONS_SCREEN.new()
    shop_screen = SHOP_SCREEN.new()
    characters_screen = CHARACTERS_SCREEN.new()
    match_battle_screen = MATCH_BATTLE_SCREEN.new()
    DataManager.load_all()
    GameState.start_new_game(DataManager.get_table("player_initial_state"))
    GameState.state_changed.connect(_on_state_changed)
    GameState.log_changed.connect(_refresh_log)
    TimeManager.week_advanced.connect(_on_week_advanced)
    _build_layout()
    _show_dashboard()

func _build_layout() -> void:
    var bg := TextureRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.texture = _load_texture(BG_IMAGE)
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.02, 0.018, 0.016, 0.58)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)

    var texture_overlay := TextureRect.new()
    texture_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    texture_overlay.texture = _load_texture(UI_PANEL_TEXTURE)
    texture_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    texture_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    texture_overlay.modulate = Color(1, 1, 1, 0.16)
    texture_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(texture_overlay)

    match_backdrop = MATCH_BATTLE_BACKDROP.new()
    match_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    match_backdrop.visible = false
    add_child(match_backdrop)

    page_margin = MarginContainer.new()
    page_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    page_margin.add_theme_constant_override("margin_left", 16)
    page_margin.add_theme_constant_override("margin_right", 16)
    page_margin.add_theme_constant_override("margin_top", 14)
    page_margin.add_theme_constant_override("margin_bottom", 14)
    add_child(page_margin)

    root = VBoxContainer.new()
    root.add_theme_constant_override("separation", 10)
    page_margin.add_child(root)

    header_row = BoxContainer.new()
    header_row.vertical = false
    header_row.add_theme_constant_override("separation", 10)
    root.add_child(header_row)

    header_title_panel = PanelContainer.new()
    header_title_panel.custom_minimum_size = Vector2(250, 0)
    header_title_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header_title_panel.add_theme_stylebox_override("panel", _ledger_style())
    header_row.add_child(header_title_panel)

    header_label = Label.new()
    header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    header_label.add_theme_font_size_override("font_size", 22)
    header_label.add_theme_color_override("font_color", Color(0.20, 0.15, 0.10, 1.0))
    header_title_panel.add_child(header_label)

    calendar_panel = PanelContainer.new()
    calendar_panel.custom_minimum_size = Vector2(170, 0)
    calendar_panel.add_theme_stylebox_override("panel", _ledger_style())
    header_row.add_child(calendar_panel)
    calendar_box = BoxContainer.new()
    calendar_box.vertical = true
    calendar_box.alignment = BoxContainer.ALIGNMENT_CENTER
    calendar_box.add_theme_constant_override("separation", 1)
    calendar_panel.add_child(calendar_box)
    calendar_date_label = _make_label("", 18)
    calendar_date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    calendar_date_label.add_theme_color_override("font_color", Color(0.27, 0.18, 0.10, 1.0))
    calendar_box.add_child(calendar_date_label)
    calendar_week_label = _make_label("", 11)
    calendar_week_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    calendar_week_label.add_theme_color_override("font_color", Color(0.42, 0.32, 0.22, 1.0))
    calendar_box.add_child(calendar_week_label)

    resource_row = BoxContainer.new()
    resource_row.vertical = false
    resource_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    resource_row.add_theme_constant_override("separation", 8)
    header_row.add_child(resource_row)
    cash_card = RESOURCE_HUD_CARD.new()
    cash_card.call("setup", "cash", "자금", COLOR_GOLD, false)
    resource_row.add_child(cash_card)
    vitality_card = RESOURCE_HUD_CARD.new()
    vitality_card.call("setup", "vitality", "체력", Color(0.34, 0.58, 0.34, 1.0), true)
    resource_row.add_child(vitality_card)

    nav_bar = HFlowContainer.new()
    nav_bar.add_theme_constant_override("h_separation", 6)
    nav_bar.add_theme_constant_override("v_separation", 6)
    root.add_child(nav_bar)

    body = BoxContainer.new()
    body.vertical = false
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 12)
    root.add_child(body)

    main_scroll = ScrollContainer.new()
    main_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(main_scroll)

    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 10)
    main_scroll.add_child(content)

    log_frame = PanelContainer.new()
    log_frame.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL))
    log_frame.custom_minimum_size = Vector2(350, 0)
    log_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(log_frame)

    log_panel = VBoxContainer.new()
    log_panel.add_theme_constant_override("separation", 8)
    log_panel.custom_minimum_size = Vector2(330, 0)
    log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    log_frame.add_child(log_panel)

    var log_header := HBoxContainer.new()
    log_header.add_theme_constant_override("separation", 8)
    log_panel.add_child(log_header)
    log_title = Label.new()
    log_title.text = "행동 로그"
    log_title.add_theme_font_size_override("font_size", 16)
    log_title.add_theme_color_override("font_color", COLOR_TEXT)
    log_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    log_header.add_child(log_title)
    log_toggle_button = Button.new()
    log_toggle_button.text = "펼치기"
    log_toggle_button.visible = false
    _style_button(log_toggle_button)
    log_toggle_button.pressed.connect(_toggle_compact_log)
    log_header.add_child(log_toggle_button)

    log_list = ItemList.new()
    log_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    log_list.add_theme_color_override("font_color", COLOR_TEXT)
    log_list.add_theme_color_override("font_selected_color", COLOR_TEXT)
    log_list.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.03, 0.028, 0.82)))
    log_panel.add_child(log_list)
    feedback_layer = UI_FEEDBACK_LAYER.new()
    add_child(feedback_layer)
    feedback_layer.call("setup", self)
    _bind_button_feedback(log_toggle_button)
    resized.connect(_update_responsive_layout)
    _update_responsive_layout()

func _on_state_changed(_path: String, _value) -> void:
    _refresh_header()
    if current_screen == "match" and _path.begins_with("stats/") and not match_stat_refresh_pending:
        match_stat_refresh_pending = true
        call_deferred("_refresh_match_after_stat_change")

func _refresh_match_after_stat_change() -> void:
    match_stat_refresh_pending = false
    if current_screen == "match" and not GameState.current_match.is_empty():
        pending_match_scroll_restore = main_scroll.scroll_vertical
        _show_match()

func _on_week_advanced(_week: int) -> void:
    if schedule_execution_in_progress:
        return
    _refresh_current_screen()

func _update_responsive_layout() -> void:
    if body == null or log_frame == null or log_panel == null or main_scroll == null:
        return
    var match_mode := current_screen == "match"
    var dashboard_mode := current_screen == "dashboard"
    var compact := _layout_width() < COMPACT_WIDTH
    var mobile := _is_mobile_layout()
    body.vertical = compact and not match_mode
    body.add_theme_constant_override("separation", 6 if mobile else 8 if compact else 12)
    root.add_theme_constant_override("separation", 7 if mobile else 10)
    if page_margin != null:
        var side_margin := 5 if match_mode and mobile else 8 if match_mode else 8 if mobile else 12 if compact else 16
        var top_margin := 5 if match_mode else 8 if mobile else 12 if compact else 14
        page_margin.add_theme_constant_override("margin_left", side_margin)
        page_margin.add_theme_constant_override("margin_right", side_margin)
        page_margin.add_theme_constant_override("margin_top", top_margin)
        page_margin.add_theme_constant_override("margin_bottom", top_margin)
    if header_label != null:
        header_label.add_theme_font_size_override("font_size", 17 if mobile else 19 if compact else 22)
    if header_title_panel != null:
        header_title_panel.custom_minimum_size = Vector2(0, 42) if mobile else Vector2(220, 0) if compact else Vector2(250, 0)
    if header_row != null:
        header_row.vertical = mobile
        header_row.add_theme_constant_override("separation", 5 if mobile else 8 if compact else 10)
    if calendar_panel != null:
        calendar_panel.custom_minimum_size = Vector2(0, 42) if mobile else Vector2(145, 0) if compact else Vector2(170, 0)
    if calendar_box != null:
        calendar_box.vertical = true
    if calendar_date_label != null:
        calendar_date_label.add_theme_font_size_override("font_size", 16 if mobile else 17 if compact else 18)
    if resource_row != null:
        resource_row.vertical = false
        resource_row.add_theme_constant_override("separation", 5 if mobile else 7 if compact else 8)
    if cash_card != null:
        cash_card.custom_minimum_size.y = 62 if mobile else 66 if compact else 70
    if vitality_card != null:
        vitality_card.custom_minimum_size.y = 62 if mobile else 66 if compact else 70
    if nav_bar != null:
        nav_bar.add_theme_constant_override("h_separation", 4 if mobile else 6)
        nav_bar.add_theme_constant_override("v_separation", 4 if mobile else 6)
    main_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    log_frame.visible = not match_mode and not dashboard_mode
    if header_row != null:
        header_row.visible = not match_mode
    if resource_row != null:
        resource_row.visible = not match_mode
    header_label.visible = not match_mode
    nav_bar.visible = not match_mode and not dashboard_mode
    log_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else 0
    log_frame.size_flags_vertical = 0 if compact else Control.SIZE_EXPAND_FILL
    if log_toggle_button != null:
        log_toggle_button.visible = compact and not match_mode and not dashboard_mode
        log_toggle_button.text = "접기" if compact_log_expanded else "펼치기"
    if log_list != null:
        log_list.visible = not compact or compact_log_expanded
    var compact_log_height := 104 if mobile else 132
    if compact and not compact_log_expanded:
        compact_log_height = 44
    log_frame.custom_minimum_size = Vector2(0, compact_log_height) if compact else Vector2(350, 0)
    log_panel.custom_minimum_size = Vector2(0, 0) if compact else Vector2(330, 0)
    if log_list != null:
        log_list.custom_minimum_size = Vector2(0, 48) if mobile and compact_log_expanded else Vector2(0, 64) if compact and compact_log_expanded else Vector2(0, 0)
    if content != null:
        for responsive_node in content.find_children("*", "BoxContainer", true, false):
            var responsive_row := responsive_node as BoxContainer
            if responsive_row != null and responsive_row.has_meta("responsive_stack_width"):
                responsive_row.vertical = _layout_width() < float(responsive_row.get_meta("responsive_stack_width"))
        for responsive_node in content.find_children("*", "GridContainer", true, false):
            var responsive_grid := responsive_node as GridContainer
            if responsive_grid != null and responsive_grid.has_meta("responsive_wide_columns"):
                responsive_grid.columns = int(responsive_grid.get_meta("responsive_compact_columns")) if compact else int(responsive_grid.get_meta("responsive_wide_columns"))
        var hero_row := content.find_child("DashboardHeroRow", true, false) as BoxContainer
        if hero_row != null:
            hero_row.vertical = false
            hero_row.add_theme_constant_override("separation", 8 if mobile else 10 if compact else 12)
        var hero_portrait := content.find_child("DashboardHeroPortrait", true, false) as TextureRect
        if hero_portrait != null:
            hero_portrait.custom_minimum_size = Vector2(170, 190) if mobile else Vector2(190, 210) if compact else Vector2(270, 270)
            hero_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if mobile else TextureRect.STRETCH_KEEP_ASPECT_COVERED
        var hero_title := content.find_child("DashboardHeroTitle", true, false) as Label
        if hero_title != null:
            hero_title.add_theme_font_size_override("font_size", 18 if mobile else 20 if compact else 22)
        var hero_summary := content.find_child("DashboardHeroSummary", true, false) as Label
        if hero_summary != null:
            hero_summary.add_theme_font_size_override("font_size", 12 if mobile else 13 if compact else 14)
        var overview := content.find_child("StrategicOverviewPanel", true, false)
        if overview != null and overview.has_method("update_responsive_layout"):
            overview.call("update_responsive_layout")
    _refresh_header()

func _layout_width() -> float:
    var layout_width := float(DisplayServer.window_get_size().x)
    if layout_width <= 0.0:
        layout_width = 1280.0
    if size.x > 0.0:
        layout_width = minf(layout_width, size.x)
    if get_viewport() != null and get_viewport().get_visible_rect().size.x > 0.0:
        layout_width = minf(layout_width, get_viewport().get_visible_rect().size.x)
    if get_tree() != null and get_tree().root != null and get_tree().root.size.x > 0:
        layout_width = minf(layout_width, float(get_tree().root.size.x))
    return layout_width

func _is_compact_layout() -> bool:
    return _layout_width() < COMPACT_WIDTH

func _is_mobile_layout() -> bool:
    return _layout_width() < MOBILE_WIDTH

func _make_responsive_row(separation: int = 10) -> BoxContainer:
    var row := BoxContainer.new()
    row.vertical = _is_compact_layout()
    row.set_meta("responsive_stack_width", COMPACT_WIDTH)
    row.add_theme_constant_override("separation", separation)
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return row

func _toggle_compact_log() -> void:
    compact_log_expanded = not compact_log_expanded
    _update_responsive_layout()

func _refresh_current_screen() -> void:
    match current_screen:
        "dashboard":
            _show_dashboard()
        "free":
            _show_free_actions()
        "shop":
            _show_shop()
        "characters":
            _show_characters()
        "personas":
            _show_personas()
        "rumors":
            _show_rumors()
        "candidates":
            _show_candidates()
        "match":
            _show_match()
        "wedding":
            _show_wedding()
        "spouse":
            _show_spouse()
        "removal":
            _show_removal()
        "coverup":
            _show_coverup()
        "game_over":
            _show_game_over()
        "complete":
            _show_vertical_slice_complete()
        _:
            _show_dashboard()

func _unhandled_key_input(event: InputEvent) -> void:
    if current_screen != "match" or GameState.current_match.is_empty() or String(GameState.current_match.get("result", "")) != "":
        return
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    var key_event := event as InputEventKey
    var index := -1
    if key_event.keycode >= KEY_1 and key_event.keycode <= KEY_9:
        index = int(key_event.keycode - KEY_1)
    if index < 0:
        return
    var candidate := DataManager.find_by_id("candidate_profiles", "candidate_profiles", String(GameState.current_match.get("candidate_id", "")))
    var choices := _all_match_choices(candidate)
    if index >= choices.size():
        return
    var choice: Dictionary = choices[index]
    if _match_choice_can_select(choice):
        _apply_match_choice(choice)
        get_viewport().set_input_as_handled()

func _refresh_header() -> void:
    if header_label == null:
        return
    if calendar_date_label != null:
        calendar_date_label.text = TimeManager.calendar_text(GameState.week)
    if calendar_week_label != null:
        calendar_week_label.text = "W%03d · %d세" % [GameState.week, GameState.age_years]
    var stats: Dictionary = GameState.player.get("stats", {})
    var risks: Dictionary = GameState.player.get("global_risks", {})
    _refresh_resource_hud(stats)
    if _is_mobile_layout():
        header_label.text = "혼인 모략\n신분 %d  의심 %d  출신소문 %d" % [
            int(stats.get("status", 0)),
            int(risks.get("social_suspicion", 0)),
            int(risks.get("origin_rumor", 0)),
        ]
    elif _is_compact_layout():
        header_label.text = "혼인 모략 · 성장 장부\n신분 %d  의심 %d  출신소문 %d" % [
            int(stats.get("status", 0)),
            int(risks.get("social_suspicion", 0)),
            int(risks.get("origin_rumor", 0)),
        ]
    else:
        header_label.text = "혼인 모략 · 성장 장부\n신분 %d  ·  의심 %d  ·  출신소문 %d" % [
            int(stats.get("status", 0)),
            int(risks.get("social_suspicion", 0)),
            int(risks.get("origin_rumor", 0)),
        ]

func _refresh_resource_hud(stats: Dictionary) -> void:
    var cash := int(stats.get("cash", 0))
    var fatigue := clampi(int(stats.get("fatigue", 0)), 0, 100)
    var vitality := 100 - fatigue
    if cash_card != null:
        var cash_accent := Color(0.94, 0.33, 0.28, 1.0) if cash < 4 else Color(0.94, 0.64, 0.24, 1.0) if cash < 10 else COLOR_GOLD
        var cash_status := "부족 · 주요 행동 제한 가능" if cash < 4 else "주의 · 지출 전 확인" if cash < 10 else "사용 가능한 자금"
        cash_card.call("update_value", cash, cash_status, cash_accent)
    if vitality_card != null:
        var vitality_accent := Color(0.34, 0.78, 0.50, 1.0) if vitality >= 60 else Color(0.94, 0.64, 0.24, 1.0) if vitality >= 30 else Color(0.94, 0.33, 0.28, 1.0)
        var vitality_status := "양호 · 피로 %d" % fatigue if vitality >= 60 else "주의 · 피로 %d" % fatigue if vitality >= 30 else "위험 · 피로 %d" % fatigue
        vitality_card.call("update_value", vitality, vitality_status, vitality_accent, " / 100")

func _refresh_nav() -> void:
    _clear(nav_bar)
    if GameState.flags.get("game_over", false):
        _add_nav_button("게임오버", _show_game_over, "game_over")
        _add_nav_button("새 게임", _request_new_game, "")
        return
    _add_nav_button("대시보드", _show_dashboard, "dashboard")
    _add_nav_button("자유행동", _show_free_actions, "free")
    _add_nav_button("상점", _show_shop, "shop")
    _add_nav_button("인물", _show_characters, "characters")
    _add_nav_button("페르소나", _show_personas, "personas")
    _add_nav_button("소문", _show_rumors, "rumors")
    _add_nav_button("후보", _show_candidates, "candidates")
    if not GameState.current_match.is_empty():
        _add_nav_button("맞선", _show_match, "match")
    if GameState.flags.get("match_success_pending", false):
        _add_nav_button("결혼식", _show_wedding, "wedding")
    if GameState.flags.get("married", false):
        _add_nav_button("배우자", _show_spouse, "spouse")
        _add_nav_button("처리", _show_removal, "removal")
    if not GameState.active_case.is_empty():
        _add_nav_button("은폐", _show_coverup, "coverup")
    if GameState.flags.get("case_resolved", false):
        _add_nav_button("완료", _show_vertical_slice_complete, "complete")
    _add_nav_button("새 게임", _request_new_game, "")

func _refresh_log() -> void:
    if log_list == null:
        return
    log_list.clear()
    var start := maxi(0, GameState.log.size() - 80)
    for i in range(start, GameState.log.size()):
        log_list.add_item(GameState.log[i])
        log_list.set_item_custom_fg_color(log_list.get_item_count() - 1, _log_color(GameState.log[i]))
    if log_list.get_item_count() > 0:
        log_list.select(log_list.get_item_count() - 1)

func _log_color(entry: String) -> Color:
    if entry.contains("게임오버") or entry.contains("치명") or entry.contains("실패"):
        return Color(0.95, 0.42, 0.36, 1.0)
    if entry.contains("위험") or entry.contains("의심") or entry.contains("범인 지목"):
        return Color(0.96, 0.66, 0.30, 1.0)
    if entry.contains("성공") or entry.contains("완료") or entry.contains("종결"):
        return Color(0.55, 0.86, 0.58, 1.0)
    if entry.contains("저장") or entry.contains("불러오기"):
        return Color(0.62, 0.76, 0.96, 1.0)
    if entry.contains("자금") or entry.contains("배경자금"):
        return Color(0.96, 0.78, 0.42, 1.0)
    return COLOR_TEXT

func _new_game() -> void:
    dashboard_schedule.clear()
    dashboard_book_tab = "ability"
    pending_match_scroll_restore = -1
    GameState.start_new_game(DataManager.get_table("player_initial_state"))
    _show_dashboard()

func _request_new_game() -> void:
    if GameState.flags.get("game_over", false):
        _new_game()
        return
    _request_confirmation(
        "새 게임을 시작하시겠습니까?",
        "현재 진행 상황이 초기화됩니다. 저장하지 않은 진행은 자동 저장에서만 복구할 수 있습니다.",
        "초기화하고 시작",
        _new_game
    )

func _request_confirmation(title: String, detail: String, confirm_label: String, callback: Callable) -> void:
    if feedback_layer == null:
        return
    feedback_layer.call("request_confirmation", title, detail, confirm_label, callback)

func _show_dashboard() -> void:
    dashboard_screen.show(self)

func _free_action_by_id(action_id: String) -> Dictionary:
    for entry in DataManager.get_table("free_actions").get("actions", []):
        if typeof(entry) == TYPE_DICTIONARY and String(entry.get("id", "")) == action_id:
            return Dictionary(entry)
    return {}

func _queue_dashboard_action(action_id: String) -> void:
    if dashboard_schedule.size() >= DASHBOARD_SCHEDULE_MAX:
        GameState.request_feedback({"type": "outcome", "tone": "warning", "title": "일정이 가득 찼습니다", "detail": "기존 일정을 제거한 뒤 추가하십시오."})
        return
    var action := _free_action_by_id(action_id)
    if action.is_empty() or String(action.get("opens_ui", "")) != "":
        return
    if not ActionResolver.can_run_action(action):
        GameState.request_feedback({"type": "outcome", "tone": "warning", "title": "예약할 수 없음", "detail": ActionResolver.explain_blocker(action)})
        return
    dashboard_schedule.append(action_id)
    _show_dashboard()

func _remove_dashboard_schedule_action(index: int) -> void:
    if index >= 0 and index < dashboard_schedule.size():
        dashboard_schedule.remove_at(index)
    _show_dashboard()

func _clear_dashboard_schedule() -> void:
    dashboard_schedule.clear()
    _show_dashboard()

func _confirm_dashboard_schedule() -> void:
    if dashboard_schedule.is_empty():
        GameState.request_feedback({"type": "outcome", "tone": "warning", "title": "일정이 비어 있습니다", "detail": "아래 행동에서 먼저 일정을 선택하십시오."})
        return
    var queued := dashboard_schedule.duplicate()
    var completed := 0
    var halted_index := -1
    schedule_execution_in_progress = true
    for index in range(queued.size()):
        var action_id: String = String(queued[index])
        var action := _free_action_by_id(String(action_id))
        if action.is_empty():
            continue
        if not ActionResolver.can_run_action(action):
            GameState.add_log("일정 중단: %s / %s" % [action.get("name_ko", action_id), ActionResolver.explain_blocker(action)])
            halted_index = index
            break
        if ActionResolver.run_action(action):
            completed += 1
        else:
            halted_index = index
            break
    schedule_execution_in_progress = false
    dashboard_schedule.clear()
    if halted_index >= 0:
        for index in range(halted_index, queued.size()):
            dashboard_schedule.append(String(queued[index]))
    var remaining := dashboard_schedule.size()
    var detail := "%d / %d개 행동을 마쳤습니다." % [completed, queued.size()]
    if remaining > 0:
        detail += " 실행하지 못한 %d개 일정은 남겨 두었습니다." % remaining
    GameState.request_feedback({"type": "outcome", "tone": "success" if remaining == 0 else "warning", "title": "일정 실행 완료" if remaining == 0 else "일정 실행 중단", "detail": detail})
    _show_dashboard()

func _set_dashboard_book_tab(tab_id: String) -> void:
    dashboard_book_tab = tab_id
    _show_dashboard()

func _open_progression_action(action_id: String) -> void:
    var methods := {
        "shop": _show_shop,
        "rumors": _show_rumors,
        "free": _show_free_actions,
        "candidates": _show_candidates,
        "match": _show_match,
        "wedding": _show_wedding,
        "spouse": _show_spouse,
        "removal": _show_removal,
        "coverup": _show_coverup,
        "complete": _show_vertical_slice_complete,
    }
    var callback: Callable = methods.get(action_id, Callable())
    if callback.is_valid():
        callback.call()

func _show_free_actions() -> void:
    free_actions_screen.show(self)

func _show_shop() -> void:
    shop_screen.show(self)

func _show_characters() -> void:
    characters_screen.show(self)

func _show_rumors() -> void:
    current_screen = "rumors"
    _prepare_screen("소문 작전")
    _add_text("소문 작전은 방식마다 정보력·사교·가면·영향력을 서로 다른 비율로 사용하며, 피로와 스트레스도 판정에 반영됩니다.")

    _add_section("주제")
    var topics: Array = DataManager.get_table("rumors").get("rumor_topics", [])
    for topic in topics:
        if typeof(topic) != TYPE_DICTIONARY:
            continue
        var box := _add_card()
        box.add_child(_make_label("%s  /  위험도 %s" % [topic.get("name_ko", topic.get("id", "")), topic.get("danger", "")], 15))
        box.add_child(_make_label(topic.get("summary_ko", ""), 12))

    _add_section("작전")
    var operations: Array = DataManager.get_table("rumors").get("operations", [])
    for operation in operations:
        if typeof(operation) != TYPE_DICTIONARY:
            continue
        var box := _add_card()
        var operation_evaluation := ActionResolver.evaluate_action(operation)
        box.add_child(_make_label("%s  /  %d주  /  현재 성공률 %d" % [operation.get("name_ko", operation.get("id", "")), int(operation.get("weeks", 1)), int(operation_evaluation.get("chance", 0))], 16))
        var operation_influence := ActionResolver.influence_summary(operation)
        if operation_influence != "":
            box.add_child(_make_label("능력 영향: " + operation_influence, 12))
        var target_npc_id := String(operation.get("target_npc_id", ""))
        if not target_npc_id.is_empty():
            var target_npc := DataManager.find_by_id("npcs", "characters", target_npc_id)
            box.add_child(_make_label("대상: " + String(target_npc.get("name_ko", target_npc_id)), 12))
        _add_chip_row(box, "비용", operation.get("cost", {}), "requirement")
        _add_chip_row(box, "성공", ActionResolver.adjusted_effects(operation, operation.get("effects_on_success", {}), operation_evaluation), "effect")
        _add_chip_row(box, "성공 관계", operation.get("relationship_effects_on_success", {}), "effect")
        _add_chip_row(box, "실패", ActionResolver.adjusted_effects(operation, operation.get("effects_on_fail", {}), operation_evaluation), "effect")
        _add_chip_row(box, "실패 관계", operation.get("relationship_effects_on_fail", {}), "effect")
        var button := Button.new()
        _style_button(button)
        var can_run := ActionResolver.can_run_action(operation)
        button.text = "실행" if can_run else "불가: " + ActionResolver.explain_blocker(operation)
        button.disabled = not can_run
        var operation_copy: Dictionary = operation
        button.pressed.connect(func():
            _run_rumor_operation(operation_copy)
        )
        box.add_child(button)

func _show_personas() -> void:
    current_screen = "personas"
    _prepare_screen("페르소나")
    _add_text("페르소나는 사회에 보여주는 공개 이미지입니다. 맞선 축과 일부 행동 판정에 보정으로 작동합니다.")
    var personas: Array = DataManager.get_table("personas").get("personas", [])
    for persona in personas:
        if typeof(persona) != TYPE_DICTIONARY:
            continue
        var persona_id := String(persona.get("id", ""))
        var unlocked := _persona_unlocked(persona)
        var box := _add_card()
        box.add_child(_make_label("%s%s" % [persona.get("name_ko", persona_id), "  [현재]" if GameState.player.get("current_persona", "") == persona_id else ""], 16))
        box.add_child(_make_label(persona.get("summary_ko", ""), 13))
        var maintenance: Dictionary = persona.get("maintenance", {})
        var weekly_cash := int(maintenance.get("weekly_funds", 0))
        var weekly_fatigue := int(maintenance.get("weekly_fatigue", 0))
        box.add_child(_make_label("주간 유지: 자금 %d / 피로 +%d" % [weekly_cash, weekly_fatigue], 12))
        var modifiers: Dictionary = persona.get("modifiers", {})
        _add_chip_row(box, "맞선 보정", modifiers.get("match_axes", {}), "effect")
        var button := Button.new()
        _style_button(button)
        button.text = "선택" if unlocked else "잠김"
        button.disabled = not unlocked or GameState.player.get("current_persona", "") == persona_id
        var persona_copy: Dictionary = persona
        button.pressed.connect(func():
            _set_persona(persona_copy)
        )
        box.add_child(button)

func _show_candidates() -> void:
    current_screen = "candidates"
    _prepare_screen("결혼 후보")
    if GameState.flags.has("last_match_failure_reason"):
        _add_text("최근 맞선 실패: " + String(GameState.flags.get("last_match_failure_reason", "")))
    var age_penalty := GameState.marriage_market_age_penalty()
    if age_penalty > 0:
        _add_text("연령 압박: 현재 맞선 준비 보너스에 -%d가 적용됩니다." % age_penalty)
    var match_blocker := GameState.match_start_blocker()
    if not match_blocker.is_empty():
        _add_text("맞선 시작 불가: " + match_blocker)
    var minimum_wedding_cash := _minimum_wedding_cash()
    if minimum_wedding_cash > 0:
        var current_cash := GameState.get_stat("cash")
        var reserve_state := "준비 완료" if current_cash >= minimum_wedding_cash else "부족 %d" % [minimum_wedding_cash - current_cash]
        _add_text("결혼식 최소 준비금 %d · 현재 자금 %d (%s). 맞선 성공 뒤에도 생활 행동으로 마련할 수 있습니다." % [minimum_wedding_cash, current_cash, reserve_state])
    if GameState.known_candidates.is_empty():
        _add_text("아직 발견한 후보가 없습니다. 자유행동의 소문 조사를 통해 기사 후보를 찾을 수 있습니다.")
    _add_candidate_filters()
    var candidates := _filtered_sorted_candidates()
    var shown_count := 0
    for candidate in candidates:
        if typeof(candidate) != TYPE_DICTIONARY:
            continue
        shown_count += 1
        var candidate_id := String(candidate.get("id", ""))
        var quality := int(GameState.known_candidates.get(candidate_id, 0))
        var npc := DataManager.find_by_id("npcs", "characters", String(candidate.get("character_id", "")))
        var box := _add_card()
        var row := _make_responsive_row(10)
        box.add_child(row)
        row.add_child(_make_portrait(npc, Vector2(76, 96) if _is_mobile_layout() else Vector2(92, 116)))

        var detail := VBoxContainer.new()
        detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        detail.add_theme_constant_override("separation", 5)
        row.add_child(detail)

        detail.add_child(_make_label("%s  /  %s  /  정보 품질 %d" % [npc.get("name_ko", candidate_id), _rank_name(String(candidate.get("rank", ""))), quality], 16))
        detail.add_child(_make_label(npc.get("public_summary_ko", ""), 13))
        if String(candidate.get("rank", "")) == "knight":
            var knight_hint := _make_label("기사 맞선 · 외모와 핵심 취향 2개 중심 · 사교/정치 능력 부담 낮음", 12)
            knight_hint.add_theme_color_override("font_color", Color(0.45, 0.82, 0.58, 1.0))
            detail.add_child(knight_hint)
        if quality >= 30:
            _add_candidate_lore(detail, "혼인 동기", candidate, "motivation_ko")
            _add_chip_row(detail, "선호 스탯", candidate.get("preferred_stats", {}), "requirement")
            _add_chip_row(detail, "최소 조건", candidate.get("minimums", {}), "requirement")
        if quality >= 60:
            detail.add_child(_make_label("보안/특성: 보안 %d / %s" % [int(candidate.get("security_level", 0)), _trait_list_text(candidate.get("special_traits", []))], 12))
            _add_candidate_lore(detail, "내부 압박", candidate, "pressure_ko")
            _add_candidate_lore(detail, "결혼 후 긴장", candidate, "spouse_dynamic_ko")
        if quality >= 85:
            var private_summary := String(npc.get("private_summary_ko", ""))
            if private_summary != "":
                detail.add_child(_make_label("비공개 단서: " + private_summary, 12))
            _add_candidate_lore(detail, "약점 단서", candidate, "weakness_hint_ko")
        var button := Button.new()
        _style_button(button)
        var minimums_met := _candidate_minimums_met(candidate)
        button.text = "맞선 시작" if minimums_met and match_blocker.is_empty() else "맞선 불가: %s" % (match_blocker if not match_blocker.is_empty() else "최소 조건 미충족")
        button.disabled = not minimums_met or not match_blocker.is_empty()
        var candidate_copy: Dictionary = candidate
        button.pressed.connect(func():
            _start_match(candidate_copy)
        )
        detail.add_child(button)
    if shown_count == 0 and not GameState.known_candidates.is_empty():
        _add_text("현재 필터에 표시할 후보가 없습니다.")

func _add_candidate_filters() -> void:
    var rank_row := HFlowContainer.new()
    rank_row.add_theme_constant_override("h_separation", 6)
    rank_row.add_theme_constant_override("v_separation", 6)
    content.add_child(rank_row)
    for rank_id in ["all", "knight", "baron", "viscount", "count", "marquis", "duke"]:
        var button := Button.new()
        _style_button(button, candidate_rank_filter == rank_id)
        button.text = "전체 작위" if rank_id == "all" else _rank_name(rank_id)
        var rank_copy := String(rank_id)
        button.pressed.connect(func():
            candidate_rank_filter = rank_copy
            _show_candidates()
        )
        rank_row.add_child(button)

    var sort_row := HFlowContainer.new()
    sort_row.add_theme_constant_override("h_separation", 6)
    sort_row.add_theme_constant_override("v_separation", 6)
    content.add_child(sort_row)
    for sort_id in ["rank", "quality", "difficulty", "security"]:
        var button := Button.new()
        _style_button(button, candidate_sort_mode == sort_id)
        button.text = String(CANDIDATE_SORT_NAMES.get(sort_id, sort_id))
        var sort_copy := String(sort_id)
        button.pressed.connect(func():
            candidate_sort_mode = sort_copy
            _show_candidates()
        )
        sort_row.add_child(button)

func _filtered_sorted_candidates() -> Array:
    var result: Array = []
    var candidates: Array = DataManager.get_table("candidate_profiles").get("candidate_profiles", [])
    for candidate in candidates:
        if typeof(candidate) != TYPE_DICTIONARY:
            continue
        var candidate_id := String(candidate.get("id", ""))
        if not GameState.known_candidates.has(candidate_id):
            continue
        if candidate_rank_filter != "all" and String(candidate.get("rank", "")) != candidate_rank_filter:
            continue
        result.append(candidate)
    result.sort_custom(_compare_candidates)
    return result

func _compare_candidates(a: Dictionary, b: Dictionary) -> bool:
    var a_id := String(a.get("id", ""))
    var b_id := String(b.get("id", ""))
    match candidate_sort_mode:
        "quality":
            var quality_diff := int(GameState.known_candidates.get(b_id, 0)) - int(GameState.known_candidates.get(a_id, 0))
            if quality_diff != 0:
                return quality_diff < 0
        "difficulty":
            var difficulty_diff := int(a.get("marriage_difficulty", 0)) - int(b.get("marriage_difficulty", 0))
            if difficulty_diff != 0:
                return difficulty_diff < 0
        "security":
            var security_diff := int(a.get("security_level", 0)) - int(b.get("security_level", 0))
            if security_diff != 0:
                return security_diff < 0
    var rank_diff := _rank_order(String(a.get("rank", ""))) - _rank_order(String(b.get("rank", "")))
    if rank_diff != 0:
        return rank_diff < 0
    return a_id < b_id

func _add_candidate_lore(parent: VBoxContainer, label_text: String, candidate: Dictionary, field_name: String) -> void:
    var value := String(candidate.get(field_name, ""))
    if value == "":
        return
    parent.add_child(_make_label(label_text + ": " + value, 12))

func _show_match() -> void:
    match_battle_screen.show(self)

func _all_match_choices(candidate: Dictionary) -> Array:
    var choices: Array = []
    for unique_choice in candidate.get("unique_match_choices", []):
        if typeof(unique_choice) == TYPE_DICTIONARY:
            choices.append(unique_choice)
    for base_choice in DataManager.get_table("match_config").get("choice_examples", []):
        if typeof(base_choice) == TYPE_DICTIONARY:
            choices.append(base_choice)
    return choices

func _minimum_wedding_cash() -> int:
    var minimum_cost := 0
    for option in DataManager.get_table("marriage_config").get("wedding_options", []):
        if typeof(option) != TYPE_DICTIONARY:
            continue
        var cost := int(Dictionary(option).get("cash_cost", 0))
        if minimum_cost == 0 or cost < minimum_cost:
            minimum_cost = cost
    return minimum_cost

func _show_wedding() -> void:
    current_screen = "wedding"
    _prepare_screen("결혼식")
    if not GameState.flags.get("match_success_pending", false):
        _add_text("결혼식 대기 상태가 아닙니다.")
        return
    var candidate := DataManager.find_by_id("candidate_profiles", "candidate_profiles", String(GameState.flags.get("pending_spouse_candidate", "")))
    var options: Array = DataManager.get_table("marriage_config").get("wedding_options", [])
    for option in options:
        if typeof(option) != TYPE_DICTIONARY:
            continue
        var option_dict: Dictionary = option
        var box := _add_card()
        box.add_child(_make_label("%s  /  %d주  /  비용 %d" % [option_dict.get("name_ko", option_dict.get("id", "")), int(option_dict.get("weeks", 1)), int(option_dict.get("cash_cost", 0))], 16))
        _add_chip_row(box, "효과", option_dict.get("effects", {}), "effect")
        var preview_event := GameState.select_wedding_result_event(option_dict, candidate)
        if not preview_event.is_empty():
            box.add_child(_make_label("예상 결과: " + String(preview_event.get("name_ko", preview_event.get("id", ""))), 12))
            box.add_child(_make_label(String(preview_event.get("summary_ko", "")), 12))
            _add_chip_row(box, "결과 효과", preview_event.get("effects", {}), "effect")
        var button := Button.new()
        _style_button(button)
        button.text = "진행"
        button.disabled = GameState.get_stat("cash") < int(option_dict.get("cash_cost", 0))
        var option_copy: Dictionary = option_dict
        button.pressed.connect(func():
            _run_wedding(option_copy)
        )
        box.add_child(button)

func _run_wedding(option: Dictionary) -> void:
    var candidate := DataManager.find_by_id("candidate_profiles", "candidate_profiles", String(GameState.flags.get("pending_spouse_candidate", "")))
    if candidate.is_empty():
        GameState.add_log("결혼식 진행 실패: 대기 중인 후보를 찾을 수 없습니다.")
        _show_wedding()
        return
    TimeManager.advance_weeks(int(option.get("weeks", 1)))
    GameState.create_spouse_from_candidate(candidate)
    GameState.apply_effects(option.get("effects", {}))
    GameState.apply_wedding_result_event(option, candidate)
    GameState.complete_wedding_transition()
    GameState.request_feedback({
        "type": "milestone",
        "tone": "success",
        "title": "혼인 성립",
        "detail": _candidate_display_name(candidate) + "와 새로운 관계가 시작됩니다.",
    })
    _show_spouse()

func _show_spouse() -> void:
    current_screen = "spouse"
    _prepare_screen("배우자 대시보드")
    if GameState.spouse.is_empty():
        _add_text("아직 배우자가 없습니다.")
        return
    if not bool(GameState.flags.get("spouse_dashboard_seen", false)):
        GameState.set_flag("spouse_dashboard_seen", true)
    var candidate := DataManager.find_by_id("candidate_profiles", "candidate_profiles", String(GameState.spouse.get("candidate_id", "")))
    var npc := DataManager.find_by_id("npcs", "characters", String(candidate.get("character_id", "")))
    var spouse_card := _add_card()
    var row := _make_responsive_row(10)
    spouse_card.add_child(row)
    row.add_child(_make_spouse_portrait(npc, Vector2(88, 112) if _is_mobile_layout() else Vector2(112, 142)))

    var detail := VBoxContainer.new()
    detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    detail.add_theme_constant_override("separation", 6)
    row.add_child(detail)
    detail.add_child(_make_label("%s  /  %s" % [npc.get("name_ko", GameState.spouse.get("candidate_id", "")), _rank_name(String(GameState.spouse.get("rank", "")))], 18))
    detail.add_child(_make_label(npc.get("public_summary_ko", ""), 13))
    detail.add_child(_make_label("현재 상태: " + _spouse_portrait_state_name(), 12))
    if String(candidate.get("spouse_dynamic_ko", "")) != "":
        detail.add_child(_make_label("배우자 성향: " + String(candidate.get("spouse_dynamic_ko", "")), 12))
    detail.add_child(_make_label("특성: " + _trait_list_text(candidate.get("special_traits", [])), 12))
    detail.add_child(_make_label("결혼 이후 배우자의 상태와 의심, 공개 금슬을 관리합니다.", 12))
    _add_key_values(GameState.spouse, ["health", "affection", "direct_suspicion", "threat_alert", "public_harmony"])
    _add_wedding_result_summary()
    _add_rank_event_summary()
    _add_spouse_household_info(candidate, npc)
    _add_text("다음 단계: 처리 화면에서 제거/정치처리 방식을 비교하거나, 자유행동으로 추가 준비를 할 수 있습니다.")
    _add_spouse_actions()

func _candidate_display_name(candidate: Dictionary) -> String:
    var npc := DataManager.find_by_id("npcs", "characters", String(candidate.get("character_id", "")))
    return String(npc.get("name_ko", candidate.get("id", "후보")))

func _add_wedding_result_summary() -> void:
    if not GameState.flags.has("last_wedding_event_title"):
        return
    _add_section("결혼식 결과")
    var box := _add_card()
    box.add_child(_make_label(String(GameState.flags.get("last_wedding_event_title", "")), 16))
    box.add_child(_make_label(String(GameState.flags.get("last_wedding_event_text", "")), 12))

func _add_rank_event_summary() -> void:
    if not GameState.flags.has("last_rank_event_title"):
        return
    _add_section("최근 작위 압박")
    var box := _add_card()
    box.add_child(_make_label("%s  /  W%03d" % [String(GameState.flags.get("last_rank_event_title", "")), int(GameState.flags.get("last_rank_event_week", 0))], 16))
    box.add_child(_make_label(String(GameState.flags.get("last_rank_event_text", "")), 12))
    var effects = GameState.flags.get("last_rank_event_effects", {})
    if typeof(effects) == TYPE_DICTIONARY:
        _add_chip_row(box, "영향", effects, "effect")

func _add_spouse_household_info(candidate: Dictionary, npc: Dictionary) -> void:
    _add_section("가문과 주변 세력")
    var box := _add_card()
    box.add_child(_make_label("%s / %s" % [_faction_name(String(npc.get("faction", ""))), _rank_name(String(candidate.get("rank", "")))], 16))
    if String(candidate.get("pressure_ko", "")) != "":
        box.add_child(_make_label("가문 압박: " + String(candidate.get("pressure_ko", "")), 12))
    if String(candidate.get("weakness_hint_ko", "")) != "":
        box.add_child(_make_label("관리 단서: " + String(candidate.get("weakness_hint_ko", "")), 12))
    _add_chip_row(box, "가문 수치", {
        "family_scrutiny": int(candidate.get("family_scrutiny", 0)),
        "security_level": int(candidate.get("security_level", 0)),
    }, "requirement")
    var household_lines := _spouse_household_lines(candidate)
    for line in household_lines:
        box.add_child(_make_label(line, 12))

func _spouse_household_lines(candidate: Dictionary) -> Array[String]:
    var traits: Array = candidate.get("special_traits", [])
    var lines: Array[String] = []
    _add_household_line(traits, ["wary_household", "household_watch"], lines, "저택 하인: 주인의 눈치를 보며 낯선 움직임을 오래 기억한다.")
    _add_household_line(traits, ["uncle_regency"], lines, "섭정 친족: 혼인 이후에도 배우자의 결정을 대신 검열하려 한다.")
    _add_household_line(traits, ["succession_dispute"], lines, "후계 경쟁자: 배우자의 선택을 계승 분쟁의 증거로 이용할 수 있다.")
    _add_household_line(traits, ["trade_network", "grain_league", "war_contracts"], lines, "거래망: 장부와 계약을 통해 자금과 정보가 오가지만 흔적도 남긴다.")
    _add_household_line(traits, ["archive_power", "procedural_mind"], lines, "기록 담당자: 말보다 문서와 절차를 우선하며 실수를 오래 보관한다.")
    _add_household_line(traits, ["court_intriguer", "blackmail_network"], lines, "궁정 정보망: 친절한 대화 뒤에서도 약점과 소문을 수집한다.")
    _add_household_line(traits, ["marcher_army", "capital_guard"], lines, "무장 수행원: 위협에는 빠르게 반응하지만 경계도도 쉽게 오른다.")
    _add_household_line(traits, ["foreign_ties", "diplomatic_web"], lines, "외교 사절단: 말실수와 방문 기록이 정치적 자산 또는 약점이 된다.")
    _add_household_line(traits, ["salon_patron", "salon_taste"], lines, "살롱 인맥: 공개 금슬과 세련된 화제가 평판을 크게 움직인다.")
    _add_household_line(traits, ["near_royal_protocol", "ducal_house", "faction_leader"], lines, "상위 의전단: 체면을 지키면 강한 방패가 되지만 부담과 감시도 크다.")
    if lines.is_empty():
        lines.append("주변 세력: 아직 두드러진 감시자는 없지만 가문 평판은 계속 관계에 영향을 준다.")
    return lines

func _add_household_line(traits: Array, trait_ids: Array, lines: Array[String], line: String) -> void:
    for trait_id in trait_ids:
        if traits.has(String(trait_id)):
            if not lines.has(line):
                lines.append(line)
            return

func _add_spouse_actions() -> void:
    _add_section("결혼 생활 행동")
    var candidate := _current_spouse_candidate()
    var actions := [
        {
            "id": "spouse_devoted_attention",
            "name_ko": "헌신적인 동행",
            "weeks": 1,
            "requirements": {},
            "stat_influence": {"stats": {"social": 0.4, "grace": 0.3, "etiquette": 0.2, "mask": 0.1}, "reference_stat": 40},
            "effects": {"affection": 6, "public_harmony": 4, "direct_suspicion": -3, "fatigue": 3},
            "summary_ko": "배우자와 공개적으로 시간을 보내 금슬과 안심을 올린다."
        },
        {
            "id": "spouse_household_probe",
            "name_ko": "저택 사정 파악",
            "weeks": 1,
            "requirements": {"mask": 10},
            "stat_influence": {"stats": {"information": 0.45, "mask": 0.35, "social": 0.2}, "reference_stat": 45},
            "effects": {"information": 3, "threat_alert": 2, "fatigue": 2},
            "summary_ko": "하인, 일정, 친족 관계를 파악한다. 정보는 늘지만 경계도도 조금 오른다."
        },
        {
            "id": "spouse_public_couple_story",
            "name_ko": "공개 금슬 연출",
            "weeks": 1,
            "requirements": {"mask": 15},
            "stat_influence": {"stats": {"mask": 0.4, "social": 0.3, "grace": 0.2, "influence": 0.1}, "reference_stat": 45},
            "effects": {"public_harmony": 8, "social_suspicion": -2, "stress": 2},
            "summary_ko": "사교계가 납득할 부부 서사를 만든다. 이후 사건 의심을 낮추는 기반이 된다."
        }
    ]
    for action in actions:
        var reaction := _spouse_reaction_for_action(action, candidate)
        var box := _add_card()
        box.add_child(_make_label("%s  /  %d주" % [action.get("name_ko", action.get("id", "")), int(action.get("weeks", 1))], 16))
        box.add_child(_make_label(action.get("summary_ko", ""), 13))
        var preview_action: Dictionary = action.duplicate(true)
        var preview_effects: Dictionary = action.get("effects", {}).duplicate(true)
        _merge_effects_into(preview_effects, reaction.get("effects", {}))
        preview_action["effects"] = preview_effects
        _add_chip_row(box, "현재 예상 효과", ActionResolver.adjusted_effects(preview_action), "effect")
        var spouse_influence := ActionResolver.influence_summary(action)
        if spouse_influence != "":
            box.add_child(_make_label("능력 영향: " + spouse_influence, 12))
        if not Dictionary(reaction.get("effects", {})).is_empty():
            box.add_child(_make_label("성향 반응: " + String(reaction.get("summary", "")), 12))
        var button := Button.new()
        _style_button(button)
        var can_run := ActionResolver.can_run_action(action)
        button.text = "실행" if can_run else "불가: " + ActionResolver.explain_blocker(action)
        button.disabled = not can_run
        var action_copy: Dictionary = action
        var reaction_copy: Dictionary = reaction
        button.pressed.connect(func():
            _run_spouse_action(action_copy, reaction_copy)
        )
        box.add_child(button)

func _current_spouse_candidate() -> Dictionary:
    if GameState.spouse.is_empty():
        return {}
    return DataManager.find_by_id("candidate_profiles", "candidate_profiles", String(GameState.spouse.get("candidate_id", "")))

func _run_spouse_action(action: Dictionary, reaction: Dictionary) -> void:
    var action_to_run := action.duplicate(true)
    var merged_effects: Dictionary = action.get("effects", {}).duplicate(true)
    _merge_effects_into(merged_effects, reaction.get("effects", {}))
    action_to_run["effects"] = merged_effects
    if not ActionResolver.run_action(action_to_run):
        _show_spouse()
        return
    var reaction_effects: Dictionary = reaction.get("effects", {})
    if not reaction_effects.is_empty():
        GameState.add_log("배우자 성향 반응: " + String(reaction.get("summary", "")))
    _show_spouse()

func _spouse_reaction_for_action(action: Dictionary, candidate: Dictionary) -> Dictionary:
    var action_id := String(action.get("id", ""))
    var traits: Array = candidate.get("special_traits", [])
    var effects: Dictionary = {}
    var notes: Array[String] = []
    match action_id:
        "spouse_devoted_attention":
            _add_trait_reaction(traits, ["honor_bound", "pious_reputation", "widower"], effects, {"affection": 2, "direct_suspicion": -1}, notes, "의리와 의례를 존중해 안심한다.")
            _add_trait_reaction(traits, ["drawn_to_wildness", "tournament_pride"], effects, {"affection": 2, "public_harmony": -1}, notes, "격식보다 솔직한 동행에 끌린다.")
            _add_trait_reaction(traits, ["vain", "reputation_sensitive", "salon_patron", "public_harmony_focused"], effects, {"public_harmony": 3, "affection": 1}, notes, "사람들 앞의 다정함을 높게 평가한다.")
            _add_trait_reaction(traits, ["secretive", "court_intriguer", "blackmail_network"], effects, {"information": 1, "direct_suspicion": 1}, notes, "친절의 의도를 계산한다.")
            _add_trait_reaction(traits, ["near_royal_protocol", "ducal_house"], effects, {"public_harmony": 2, "stress": 1}, notes, "의전상 완벽한 동행을 요구한다.")
        "spouse_household_probe":
            _add_trait_reaction(traits, ["archive_power", "procedural_mind", "secretive"], effects, {"information": 1, "direct_suspicion": 3}, notes, "사적인 탐문을 기록과 침범으로 받아들인다.")
            _add_trait_reaction(traits, ["hidden_money", "bribe_rumor", "war_contracts", "famine_blame"], effects, {"information": 2, "threat_alert": 1}, notes, "숨긴 장부와 거래 흔적이 드러난다.")
            _add_trait_reaction(traits, ["household_watch", "capital_guard", "marcher_army"], effects, {"information": 1, "threat_alert": 3}, notes, "저택 방비가 곧바로 강화된다.")
            _add_trait_reaction(traits, ["trade_network", "diplomatic_web", "foreign_ties"], effects, {"information": 2}, notes, "연줄과 일정에서 쓸 만한 정보를 얻는다.")
            _add_trait_reaction(traits, ["honor_bound"], effects, {"direct_suspicion": 1}, notes, "정면 대화 없는 탐문을 불편해한다.")
        "spouse_public_couple_story":
            _add_trait_reaction(traits, ["public_harmony_focused", "reputation_sensitive", "salon_patron", "grain_league"], effects, {"public_harmony": 4, "social_suspicion": -1}, notes, "공개 서사를 적극적으로 이용한다.")
            _add_trait_reaction(traits, ["vain", "tournament_pride", "bloodline_pride"], effects, {"public_harmony": 3, "affection": 1}, notes, "체면이 세워지면 호의적으로 반응한다.")
            _add_trait_reaction(traits, ["near_royal_protocol", "ducal_house", "faction_leader"], effects, {"public_harmony": 3, "stress": 1}, notes, "격 높은 의전으로 효과가 커지지만 부담도 는다.")
            _add_trait_reaction(traits, ["secretive", "blackmail_network", "court_intriguer"], effects, {"information": 1, "direct_suspicion": 1}, notes, "공개 연출 뒤의 거래 가치를 계산한다.")
            _add_trait_reaction(traits, ["drawn_to_wildness"], effects, {"affection": -1}, notes, "과한 연출을 답답하게 여긴다.")
    return {"effects": effects, "summary": _join_strings(notes)}

func _add_trait_reaction(traits: Array, trait_ids: Array, effects: Dictionary, delta: Dictionary, notes: Array[String], note: String) -> void:
    for trait_id in trait_ids:
        if traits.has(String(trait_id)):
            _merge_effects_into(effects, delta)
            if not notes.has(note):
                notes.append(note)
            return

func _merge_effects_into(target: Dictionary, delta: Dictionary) -> void:
    for key in delta.keys():
        target[String(key)] = int(target.get(String(key), 0)) + int(delta[key])

func _show_removal() -> void:
    current_screen = "removal"
    _prepare_screen("제거/정치처리")
    if GameState.spouse.is_empty():
        _add_text("배우자가 있어야 사용할 수 있습니다.")
        return
    var methods: Array = DataManager.get_table("removal_methods").get("methods", [])
    for method in methods:
        if typeof(method) != TYPE_DICTIONARY:
            continue
        var box := _add_card()
        var counter_event := GameState.select_removal_counter_event(method)
        var removal_external_modifier := _removal_external_modifier(counter_event)
        var removal_evaluation := ActionResolver.evaluate_action(method, removal_external_modifier)
        box.add_child(_make_label("%s  /  준비 %d주  /  현재 성공률 %d" % [method.get("name_ko", method.get("id", "")), int(method.get("weeks_to_prepare", 1)), int(removal_evaluation.get("chance", 0))], 16))
        var removal_influence := ActionResolver.influence_summary(method, removal_external_modifier)
        if removal_influence != "":
            box.add_child(_make_label("능력 영향: " + removal_influence, 12))
        box.add_child(_make_label(method.get("summary_ko", ""), 13))
        _add_chip_row(box, "요구", method.get("requirements", {}), "requirement")
        var preview_method: Dictionary = method.duplicate(true)
        preview_method["risk_profile"] = ActionResolver.adjusted_effects(method, method.get("risk_profile", {}), removal_evaluation)
        _add_chip_row(box, "현재 예상 위험", preview_method.get("risk_profile", {}), "effect")
        var success_result := GameState.removal_result(method, true)
        if not success_result.is_empty():
            box.add_child(_make_label("성공 결과: " + String(success_result.get("name_ko", "")), 12))
            box.add_child(_make_label(String(success_result.get("summary_ko", "")), 12))
            _add_chip_row(box, "결과 효과", success_result.get("effects", {}), "effect")
        if not counter_event.is_empty():
            box.add_child(_make_label("예상 대응: " + String(counter_event.get("name_ko", counter_event.get("id", ""))), 12))
            box.add_child(_make_label(String(counter_event.get("summary_ko", "")), 12))
            _add_chip_row(box, "성공률 보정", {"success_modifier": int(counter_event.get("success_modifier", 0))}, "effect")
            _add_chip_row(box, "대응 효과", counter_event.get("effects", {}), "effect")
            _add_chip_row(box, "사건 영향", counter_event.get("case_effects", {}), "effect")
        _add_removal_warning(box, preview_method, success_result, counter_event)
        var button := Button.new()
        _style_button(button)
        var can_run := ActionResolver.can_run_action({"requirements": method.get("requirements", {})})
        button.text = _removal_button_text(method, can_run)
        button.disabled = not can_run
        var method_copy: Dictionary = method
        button.pressed.connect(func():
            _confirm_or_run_removal(method_copy)
        )
        box.add_child(button)

func _add_removal_warning(parent: VBoxContainer, method: Dictionary, success_result: Dictionary, counter_event: Dictionary) -> void:
    var warning := _removal_warning_info(method, success_result, counter_event)
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _panel_style(Color(warning.get("color", COLOR_RED))))
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 3)
    panel.add_child(box)
    box.add_child(_make_label("경고: %s / 위험도 %d" % [String(warning.get("title", "")), int(warning.get("score", 0))], 13))
    box.add_child(_make_label(String(warning.get("summary", "")), 12))
    parent.add_child(panel)

func _removal_warning_info(method: Dictionary, success_result: Dictionary, counter_event: Dictionary) -> Dictionary:
    var result_type := String(success_result.get("type", "fatal_case"))
    var score := _removal_risk_score(method, success_result, counter_event)
    var notes: Array[String] = []
    if bool(success_result.get("widow", true)):
        notes.append("사망 사건과 미망인 이미지가 남습니다.")
    else:
        notes.append("비치명 처리지만 혼인 관계와 가문 평판은 되돌리기 어렵습니다.")
    if not counter_event.is_empty():
        notes.append("예상 대응으로 성공률과 후폭풍 위험이 악화됩니다.")
    if score >= 45:
        notes.append("실행 전 정보력, 알리바이, 공개 서사를 준비하십시오.")
    var title := "치명적 고위험 처리" if result_type == "fatal_case" else "정치적 고위험 처리"
    var summary := _join_strings(notes) + " 첫 클릭은 확인이며, 같은 버튼을 다시 눌러야 실행됩니다."
    var color := Color(0.31, 0.06, 0.06, 0.86) if score >= 45 else Color(0.23, 0.12, 0.05, 0.86)
    if not bool(success_result.get("widow", true)):
        color = Color(0.2, 0.13, 0.04, 0.86)
    return {"title": title, "summary": summary, "score": score, "color": color}

func _removal_risk_score(method: Dictionary, success_result: Dictionary, counter_event: Dictionary) -> int:
    var score := 0
    var risk_profile: Dictionary = method.get("risk_profile", {})
    for key in risk_profile.keys():
        score += maxi(0, int(risk_profile[key]))
    var case_initial: Dictionary = success_result.get("case_initial", {})
    for key in case_initial.keys():
        score += int(case_initial[key]) / 2
    var case_effects: Dictionary = counter_event.get("case_effects", {})
    for key in case_effects.keys():
        score += maxi(0, int(case_effects[key]))
    if bool(success_result.get("widow", true)):
        score += 12
    return score

func _removal_button_text(method: Dictionary, can_run: bool) -> String:
    if not can_run:
        return "불가: " + ActionResolver.explain_blocker({"requirements": method.get("requirements", {})})
    var method_id := String(method.get("id", ""))
    if pending_removal_confirmation_id == method_id:
        return "위험 확인됨: 실행"
    return "위험 확인"

func _confirm_or_run_removal(method: Dictionary) -> void:
    var method_id := String(method.get("id", ""))
    if pending_removal_confirmation_id != method_id:
        pending_removal_confirmation_id = method_id
        GameState.add_log("처리 실행 전 위험 확인 필요: " + String(method.get("name_ko", method_id)))
        _show_removal()
        return
    pending_removal_confirmation_id = ""
    _run_removal(method)

func _show_coverup() -> void:
    current_screen = "coverup"
    _prepare_screen(_case_screen_title())
    GameState.evaluate_active_case()
    if GameState.flags.get("game_over", false):
        _show_game_over()
        return
    if GameState.active_case.is_empty():
        _add_text("진행 중인 사건 파일이 없습니다.")
        if GameState.flags.has("last_case_resolution"):
            _add_text("최근 사건 종결: " + String(GameState.flags.get("last_case_resolution", "")))
        return
    if GameState.active_case.has("result_name"):
        _add_section("처리 결과")
        var result_box := _add_card()
        result_box.add_child(_make_label(String(GameState.active_case.get("result_name", "")), 16))
        result_box.add_child(_make_label(String(GameState.active_case.get("result_text", "")), 12))
    if GameState.active_case.has("counter_event_name"):
        _add_section("처리 대응")
        var counter_box := _add_card()
        counter_box.add_child(_make_label(String(GameState.active_case.get("counter_event_name", "")), 16))
        counter_box.add_child(_make_label(String(GameState.active_case.get("counter_event_text", "")), 12))
    if GameState.flags.get("accusation_event_seen", false):
        _add_text("범인 지목 위험: " + String(GameState.flags.get("accusation_event_text", "")))
    _add_section("사건 위험")
    _add_key_values(GameState.active_case, ["investigation_progress", "rumor_spread", "evidence_risk", "alibi_strength", "public_grief"])
    var actions: Array = DataManager.get_table("coverup_actions").get("actions", [])
    for action in actions:
        if typeof(action) != TYPE_DICTIONARY:
            continue
        var box := _add_card()
        var coverup_modifier := _coverup_external_modifier(action)
        var coverup_evaluation := ActionResolver.evaluate_action(action, coverup_modifier)
        box.add_child(_make_label("%s  /  %d주  /  현재 성공률 %d" % [_case_action_name(action), int(action.get("weeks", 1)), int(coverup_evaluation.get("chance", 0))], 16))
        var coverup_influence := ActionResolver.influence_summary(action, coverup_modifier)
        if coverup_influence != "":
            box.add_child(_make_label("능력 영향: " + coverup_influence, 12))
        box.add_child(_make_label(_case_action_summary(action), 13))
        _add_chip_row(box, "성공", ActionResolver.adjusted_effects(action, action.get("effects", {}), coverup_evaluation), "effect")
        _add_chip_row(box, "실패", ActionResolver.adjusted_effects(action, action.get("effects_on_fail", {}), coverup_evaluation), "effect")
        var button := Button.new()
        _style_button(button)
        button.text = "실행" if ActionResolver.can_run_action(action) else "불가: " + ActionResolver.explain_blocker(action)
        button.disabled = not ActionResolver.can_run_action(action)
        var action_copy: Dictionary = action
        button.pressed.connect(func():
            _run_coverup_action(action_copy)
            GameState.evaluate_active_case()
            _show_coverup()
        )
        box.add_child(button)

func _show_game_over() -> void:
    current_screen = "game_over"
    _prepare_screen("게임오버")
    var reason := String(GameState.flags.get("game_over_reason", "치명적 의심에 도달했습니다."))
    _add_text(reason)
    _add_section("최종 위험")
    _add_key_values(GameState.player.get("global_risks", {}), ["social_suspicion", "origin_rumor", "notoriety", "underworld_trace"])
    if not GameState.active_case.is_empty():
        _add_section("사건 파일")
        _add_key_values(GameState.active_case, ["investigation_progress", "rumor_spread", "evidence_risk", "alibi_strength", "public_grief"])
    var button := Button.new()
    _style_button(button)
    button.text = "새 게임"
    button.pressed.connect(_request_new_game)
    content.add_child(button)

func _show_vertical_slice_complete() -> void:
    current_screen = "complete"
    _prepare_screen("수직 절편 완료")
    if not GameState.flags.get("case_resolved", false):
        _add_text("아직 사건이 종결되지 않았습니다. 은폐 화면에서 위험을 낮추십시오.")
        return
    _add_text("첫 결혼, 처리, 은폐 사건 종결까지의 핵심 루프가 완료되었습니다.")
    if GameState.flags.has("last_case_resolution"):
        _add_text("사건 종결: " + String(GameState.flags.get("last_case_resolution", "")))
    _add_section("현재 기반")
    _add_key_values(GameState.player.get("stats", {}), ["status", "funds_power", "information", "social", "influence", "cash"])
    _add_section("남은 위험")
    _add_key_values(GameState.player.get("global_risks", {}), ["social_suspicion", "origin_rumor", "notoriety", "underworld_trace"])
    var button := Button.new()
    _style_button(button)
    button.text = "다음 후보 보기"
    button.pressed.connect(_show_candidates)
    content.add_child(button)

func _start_match(candidate: Dictionary) -> void:
    var blocker := GameState.match_start_blocker()
    if blocker.is_empty() and not _candidate_minimums_met(candidate):
        blocker = "후보의 최소 조건을 충족하지 못했습니다."
    if not blocker.is_empty():
        GameState.add_log("맞선 시작 차단: " + blocker)
        GameState.request_feedback({
            "type": "outcome",
            "tone": "warning",
            "title": "맞선을 시작할 수 없음",
            "detail": blocker,
        })
        return
    var default_match: Dictionary = DataManager.get_table("match_config").get("default_match", {})
    var start_axes: Dictionary = candidate.get("match_start_axes", {}).duplicate(true)
    start_axes = _apply_item_match_axes(_apply_persona_axes(_apply_voice_stage_axes(start_axes)))
    start_axes = _apply_match_start_floors(start_axes, candidate)
    if not GameState.begin_match(String(candidate.get("id", "")), int(default_match.get("time_limit_turns", 8)), start_axes):
        return
    _show_match()

func _apply_item_match_axes(axes: Dictionary) -> Dictionary:
    var axis_ids := ["favor", "interest", "trust", "comfort", "face", "political_value"]
    var applied: Array[String] = []
    for axis_id in axis_ids:
        var bonus := GameState.equipped_effect_value(axis_id)
        if bonus == 0:
            continue
        axes[axis_id] = clampi(int(axes.get(axis_id, 0)) + bonus, 0, 100)
        applied.append("%s %s%d" % [_name_for(axis_id), "+" if bonus > 0 else "", bonus])
    if not applied.is_empty():
        GameState.add_log("아이템 맞선 보정: " + _join_strings(applied))
    return axes

func _apply_match_start_floors(axes: Dictionary, candidate: Dictionary) -> Dictionary:
    var config: Dictionary = DataManager.get_table("match_config")
    var rules := MATCH_OUTCOME_CALCULATOR.rules_for_candidate(candidate, config)
    var floors: Dictionary = rules.get("start_axis_floor", {})
    var applied: Array[String] = []
    for raw_axis_id in floors.keys():
        var axis_id := String(raw_axis_id)
        var old_value := int(axes.get(axis_id, 0))
        var new_value := maxi(old_value, int(floors[raw_axis_id]))
        axes[axis_id] = new_value
        if new_value > old_value:
            applied.append("%s %d→%d" % [_name_for(axis_id), old_value, new_value])
    if not applied.is_empty():
        GameState.add_log("기사 계급 관용 보정: " + _join_strings(applied))
    return axes

func _apply_match_choice(choice: Dictionary) -> void:
    if GameState.current_match.is_empty() or String(GameState.current_match.get("result", "")) != "":
        return
    if not _match_choice_can_select(choice):
        GameState.request_feedback({
            "type": "outcome",
            "tone": "warning",
            "title": "이 화제는 꺼낼 수 없습니다",
            "detail": _match_choice_blocker(choice),
        })
        return
    var previous_scroll := main_scroll.scroll_vertical
    var readiness := _match_choice_soft_evaluation(choice)
    var readiness_state := String(readiness.get("state", "stable"))
    var recorded_readiness_state := readiness_state if bool(readiness.get("has_soft_requirements", false)) else ""
    var repeat_count := _match_choice_usage_count(choice)
    var adjusted_effects := _match_choice_effects(choice)
    var dialogue := _match_dialogue_for_choice(choice, readiness_state, repeat_count)
    var turn_result := GameState.record_match_turn(
        String(choice.get("name_ko", choice.get("id", ""))),
        adjusted_effects,
        _match_reaction_for_effects(adjusted_effects, readiness_state, repeat_count),
        dialogue,
        recorded_readiness_state,
        String(choice.get("id", choice.get("name_ko", "")))
    )
    var net_effect := int(turn_result.get("net_effect", 0))
    GameState.request_feedback({
        "type": "match_turn",
        "tone": "success" if net_effect > 0 else "failure" if net_effect < 0 else "info",
        "net_effect": net_effect,
        "readiness_state": readiness_state,
        "repeat_level": repeat_count,
        "dominant_axis": _match_dominant_effect_axis(adjusted_effects),
        "turns_left": int(turn_result.get("turns_left", 0)),
        "turn_index": Array(GameState.current_match.get("choice_history", [])).size(),
    })
    if int(turn_result.get("turns_left", 0)) <= 0:
        pending_match_scroll_restore = -1
        _finish_match()
    else:
        pending_match_scroll_restore = previous_scroll
        _show_match()

func _match_reaction_for_effects(effects: Dictionary, readiness_state: String = "stable", repeat_count: int = 0) -> String:
    var strongest_axis := ""
    var strongest_value := 0
    var worst_value := 0
    for key in effects.keys():
        var value := int(effects[key])
        if value > strongest_value:
            strongest_value = value
            strongest_axis = String(key)
        worst_value = mini(worst_value, value)
    if readiness_state == "backfire":
        return "— 어설프게 빗나간 말에 표정이 굳고, 응접실의 온기가 눈에 띄게 식는다."
    if repeat_count >= 2:
        return "— 이미 여러 번 들은 이야기라는 듯 시선이 창밖으로 향하고, 대답이 짧아진다."
    if repeat_count == 1:
        return "— 같은 화제로 돌아온 것을 알아차리고 예의 바른 미소만 남긴다."
    if readiness_state == "reduced":
        if worst_value < 0:
            return "— 뜻은 알아들었지만 불안한 말끝을 놓치지 않고 조심스레 거리를 둔다."
        return "— 의도는 받아들이지만 매끄럽지 않은 표현까지 가만히 헤아린다."
    if worst_value <= -4:
        return "— 분위기가 날카롭게 흔들린다. 그러나 아직 만회할 수 있다."
    var reactions := {
        "favor": "— 굳어 있던 표정이 조금 누그러진다.",
        "interest": "— 몸을 앞으로 기울이며 다음 말을 기다린다.",
        "trust": "— 경계하던 눈빛에 처음으로 신뢰가 비친다.",
        "comfort": "— 긴장을 풀고 대화의 속도를 당신에게 맞춘다.",
        "face": "— 가문의 체면이 세워졌다는 듯 만족을 감추지 않는다.",
        "political_value": "— 감정 너머의 혼인 가치를 다시 계산하기 시작한다.",
    }
    return String(reactions.get(strongest_axis, "— 당신의 수를 조용히 받아들인다."))

func _match_dominant_effect_axis(effects: Dictionary) -> String:
    var dominant_axis := ""
    var dominant_strength := -1
    for raw_axis_id in effects.keys():
        var strength := absi(int(effects[raw_axis_id]))
        if strength > dominant_strength:
            dominant_axis = String(raw_axis_id)
            dominant_strength = strength
    return dominant_axis

func _match_dialogue_for_choice(choice: Dictionary, readiness_state: String, repeat_count: int = 0) -> String:
    var state_dialogue: Dictionary = choice.get("state_dialogue", {})
    var override_line := String(state_dialogue.get(readiness_state, ""))
    if override_line != "":
        return override_line
    var base_line := _select_dialogue_line(_dialogue_context_for_choice(choice), choice.get("tags", []))
    if readiness_state != "backfire" and repeat_count >= 2:
        return "이미 말씀드린 이야기지만… 다시 생각해 보면 중요한 대목이 있습니다."
    if readiness_state != "backfire" and repeat_count == 1:
        if base_line == "":
            return "아까의 이야기로 잠시 돌아가도 될까요?"
        return base_line + " …아까와 같은 화제로 돌아가며 상대의 표정을 살핀다."
    match readiness_state:
        "reduced":
            if base_line == "":
                return "제 뜻은… 충분히 전해졌기를 바랍니다."
            return base_line + " …말끝을 고르는 사이 문장이 잠시 흐트러진다."
        "backfire":
            return "아니, 제 뜻은… 잠시만요. 방금 말은 잊어주십시오."
        _:
            return base_line

func _match_choice_effects(choice: Dictionary) -> Dictionary:
    var match_config: Dictionary = DataManager.get_table("match_config")
    var scaling: Dictionary = match_config.get("default_match", {}).get("choice_stat_scaling", {})
    var effects: Dictionary = MATCH_CHOICE_CALCULATOR.calculate_effects(
        choice,
        _match_choice_tag_definitions(),
        GameState.player.get("stats", {}),
        scaling
    )
    var candidate := DataManager.find_by_id("candidate_profiles", "candidate_profiles", String(GameState.current_match.get("candidate_id", "")))
    var rules := MATCH_OUTCOME_CALCULATOR.rules_for_candidate(candidate, match_config)
    effects = MATCH_CHOICE_CALCULATOR.apply_candidate_affinity(effects, choice, candidate, rules)
    return _apply_match_repetition(effects, _match_choice_usage_count(choice))

func _match_choice_usage_count(choice: Dictionary) -> int:
    var choice_id := String(choice.get("id", choice.get("name_ko", "")))
    return int(Dictionary(GameState.current_match.get("choice_usage", {})).get(choice_id, 0))

func _apply_match_repetition(effects: Dictionary, repeat_count: int) -> Dictionary:
    if repeat_count <= 0:
        return effects
    var adjusted := effects.duplicate(true)
    var positive_multiplier := 0.65 if repeat_count == 1 else 0.35 if repeat_count == 2 else 0.10
    for raw_axis_id in adjusted.keys():
        var axis_id := String(raw_axis_id)
        var value := int(adjusted[raw_axis_id])
        if value > 0:
            adjusted[axis_id] = roundi(value * positive_multiplier)
        elif value < 0:
            adjusted[axis_id] = roundi(value * (1.15 if repeat_count == 1 else 1.35 if repeat_count == 2 else 1.6))
    var boredom_penalty := 1 if repeat_count == 1 else 3 if repeat_count == 2 else 5
    adjusted["interest"] = int(adjusted.get("interest", 0)) - boredom_penalty
    if repeat_count >= 2:
        adjusted["comfort"] = int(adjusted.get("comfort", 0)) - (2 if repeat_count == 2 else 4)
    if repeat_count >= 3:
        adjusted["trust"] = int(adjusted.get("trust", 0)) - 2
    return adjusted

func _match_choice_repeat_summary(choice: Dictionary) -> String:
    var repeat_count := _match_choice_usage_count(choice)
    if repeat_count <= 0:
        return ""
    if repeat_count == 1:
        return "반복 2회 · 효과 감소"
    if repeat_count == 2:
        return "반복 3회 · 지루함 누적"
    return "반복 %d회 · 역효과 위험" % [repeat_count + 1]

func _match_choice_soft_evaluation(choice: Dictionary) -> Dictionary:
    var scaling: Dictionary = DataManager.get_table("match_config").get("default_match", {}).get("choice_stat_scaling", {})
    return MATCH_CHOICE_CALCULATOR.soft_requirement_evaluation(choice, GameState.player.get("stats", {}), scaling)

func _match_choice_hard_action(choice: Dictionary) -> Dictionary:
    var player_stats: Dictionary = GameState.player.get("stats", {})
    var hard_requirements: Dictionary = Dictionary(choice.get("hard_requirements", {})).duplicate(true)
    for raw_key in Dictionary(choice.get("requirements", {})).keys():
        var requirement_id := String(raw_key)
        var stat_id := requirement_id.trim_prefix("min_")
        var required_value = Dictionary(choice.get("requirements", {}))[raw_key]
        var is_numeric := typeof(required_value) == TYPE_INT or typeof(required_value) == TYPE_FLOAT
        if is_numeric and player_stats.has(stat_id):
            continue
        hard_requirements[requirement_id] = required_value
    return {
        "requirements": hard_requirements,
        "cost": choice.get("cost", {}),
    }

func _match_choice_can_select(choice: Dictionary) -> bool:
    return ActionResolver.can_run_action(_match_choice_hard_action(choice))

func _match_choice_blocker(choice: Dictionary) -> String:
    return ActionResolver.explain_blocker(_match_choice_hard_action(choice))

func _match_choice_requirement_summary(choice: Dictionary) -> String:
    var evaluation := _match_choice_soft_evaluation(choice)
    var parts: Array[String] = []
    for entry in evaluation.get("entries", []):
        if typeof(entry) != TYPE_DICTIONARY:
            continue
        parts.append("%s %d/%d" % [
            _name_for(String(entry.get("stat_id", ""))),
            int(entry.get("current", 0)),
            int(entry.get("required", 0)),
        ])
    return _join_strings(parts)

func _match_choice_has_affinity(choice: Dictionary) -> bool:
    var candidate := DataManager.find_by_id("candidate_profiles", "candidate_profiles", String(GameState.current_match.get("candidate_id", "")))
    return MATCH_CHOICE_CALCULATOR.choice_has_affinity(choice, candidate)

func _match_choice_tag_definitions() -> Array:
    return DataManager.get_table("choice_tags").get("choice_tags", [])

func _finish_match() -> void:
    var axes: Dictionary = GameState.current_match.get("axes", {})
    var config := DataManager.get_table("match_config")
    var axis_defs: Array = config.get("axes", [])
    var candidate := DataManager.find_by_id("candidate_profiles", "candidate_profiles", String(GameState.current_match.get("candidate_id", "")))
    var prep_bonus := _candidate_preparation_bonus(candidate)
    var evaluation := MATCH_OUTCOME_CALCULATOR.evaluate(axes, candidate, config, prep_bonus)
    var score := int(evaluation.get("score", 0))
    var threshold := int(evaluation.get("threshold", 62))
    var critical_axes: Array[String] = []
    for raw_axis_id in evaluation.get("critical_axes", []):
        critical_axes.append(_name_for(String(raw_axis_id)))
    var age_penalty := GameState.marriage_market_age_penalty()
    var success := bool(evaluation.get("success", false))
    GameState.add_log("맞선 종료: 점수 %d / 기준 %d / 준비 보너스 %d (연령 -%d) / %s" % [score, threshold, prep_bonus, age_penalty, "성공" if success else "실패"])
    var failure_reason := "" if success else _match_failure_reason(axes, axis_defs, score, threshold, prep_bonus, critical_axes)
    if not success:
        GameState.add_log("실패 사유: " + failure_reason)
        if not GameState.flags.get("first_failure_seen", false):
            GameState.set_flag("first_failure_seen", true)
            GameState.add_log("튜토리얼 안내: 실패 사유를 확인하고 부족 축을 보완한 뒤 다시 시도하십시오.")
        GameState.apply_effects({"stress": 6, "social_suspicion": 2})
    GameState.finalize_match(success, String(candidate.get("id", "")), failure_reason, score, threshold, prep_bonus)
    GameState.request_feedback({
        "type": "outcome",
        "tone": "success" if success else "failure",
        "title": "맞선 성공" if success else "맞선 실패",
        "detail": "최종 점수 %d · 목표 %d" % [score, threshold],
    })
    _show_match()

func _continue_match_result() -> void:
    var result := String(GameState.current_match.get("result", ""))
    if result == "success":
        _show_wedding()
        return
    GameState.clear_current_match()
    _show_candidates()

func _run_removal(method: Dictionary) -> void:
    var counter_event := GameState.select_removal_counter_event(method)
    var counter_modifier := int(counter_event.get("success_modifier", 0))
    var evaluation := ActionResolver.evaluate_action(method, _removal_external_modifier(counter_event))
    var base_success := int(evaluation.get("chance", 0))
    TimeManager.advance_weeks(int(method.get("weeks_to_prepare", 1)))
    var roll := randi_range(1, 100)
    var success := roll <= base_success
    GameState.add_log("%s 실행: %s (판정 %d/%d, 대응 보정 %d)" % [method.get("name_ko", method.get("id", "")), "성공" if success else "실패", roll, base_success, counter_modifier])
    GameState.apply_removal_counter_event(counter_event)
    if not success:
        GameState.apply_effects({"direct_suspicion": 12, "threat_alert": 10, "social_suspicion": 5})
    var resolved_method := method.duplicate(true)
    resolved_method["risk_profile"] = ActionResolver.adjusted_effects(method, method.get("risk_profile", {}), evaluation)
    GameState.create_case_from_removal(resolved_method, success)
    GameState.apply_removal_counter_case_effects(counter_event)
    var result := GameState.removal_result(method, success)
    if success and bool(result.get("spouse_removed", true)):
        var previous_rank := GameState.remove_current_spouse()
        if bool(result.get("unlock_next_rank", true)):
            GameState.unlock_next_rank_candidates(previous_rank, 20, 1)
    GameState.request_feedback({
        "type": "outcome",
        "tone": "success" if success else "failure",
        "title": "계획 성공" if success else "계획 실패",
        "detail": "%s · 판정 %d / %d" % [String(method.get("name_ko", method.get("id", ""))), roll, base_success],
    })
    _show_coverup()

func _removal_external_modifier(counter_event: Dictionary) -> int:
    var security_penalty := int(GameState.spouse.get("threat_alert", 0)) / 5
    var suspicion_penalty := int(GameState.spouse.get("direct_suspicion", 0)) / 5
    return int(counter_event.get("success_modifier", 0)) - security_penalty - suspicion_penalty

func _case_screen_title() -> String:
    var case_type := String(GameState.active_case.get("case_type", ""))
    if _is_political_aftermath_case(case_type):
        return "정치 후폭풍 관리"
    if case_type == "failed_removal":
        return "실패 후폭풍 관리"
    return "은폐 사건 파일"

func _case_action_name(action: Dictionary) -> String:
    if _is_political_aftermath_case(String(GameState.active_case.get("case_type", ""))) and String(action.get("id", "")) == "coverup_public_mourning":
        return "공개 서사 정리"
    return String(action.get("name_ko", action.get("id", "")))

func _case_action_summary(action: Dictionary) -> String:
    if _is_political_aftermath_case(String(GameState.active_case.get("case_type", ""))) and String(action.get("id", "")) == "coverup_public_mourning":
        return "공식 설명과 의전을 맞춰 주변이 납득할 공개 서사를 만든다."
    return String(action.get("summary_ko", ""))

func _is_political_aftermath_case(case_type: String) -> bool:
    return case_type in ["political_disgrace", "distant_assignment", "annulment"]

func _run_rumor_operation(operation: Dictionary) -> void:
    var success := ActionResolver.run_operation(operation)
    var operation_id := String(operation.get("id", ""))
    if success and operation_id == "rumor_probe":
        GameState.unlock_accessible_candidates(clampi(GameState.get_stat("information") * 4, 30, 90), 1)
    elif success and operation_id == "rumor_cleanse":
        GameState.change_relationship("npc_rival_celina", "suspicion", -3)
    elif not success and operation_id == "rumor_seed":
        GameState.change_relationship("npc_rival_celina", "suspicion", 4)
    _show_rumors()

func _run_coverup_action(action: Dictionary) -> void:
    if not ActionResolver.can_run_action(action):
        GameState.add_log("은폐 행동 조건 미충족: " + String(action.get("name_ko", action.get("id", ""))) + " / " + ActionResolver.explain_blocker(action))
        GameState.request_feedback({
            "type": "outcome",
            "tone": "warning",
            "title": "실행할 수 없음",
            "detail": ActionResolver.explain_blocker(action),
        })
        return
    var evaluation := ActionResolver.evaluate_action(action, _coverup_external_modifier(action))
    var chance := int(evaluation.get("chance", 0))
    var roll := randi_range(1, 100)
    var success := roll <= chance
    var effects: Dictionary = action.get("effects" if success else "effects_on_fail", {})
    GameState.apply_effects(ActionResolver.adjusted_effects(action, effects, evaluation))
    TimeManager.advance_weeks(int(action.get("weeks", 1)))
    GameState.add_log("은폐 행동: %s / %s (판정 %d/%d)" % [action.get("name_ko", action.get("id", "")), "성공" if success else "실패", roll, chance])
    GameState.request_feedback({
        "type": "outcome",
        "tone": "success" if success else "failure",
        "title": "대응 성공" if success else "대응 실패",
        "detail": "%s · 판정 %d / %d" % [String(action.get("name_ko", action.get("id", ""))), roll, chance],
    })

func _coverup_success_chance(action: Dictionary) -> int:
    return int(ActionResolver.evaluate_action(action, _coverup_external_modifier(action)).get("chance", 0))

func _coverup_external_modifier(action: Dictionary) -> int:
    var modifier := 0
    if String(action.get("id", "")) == "coverup_public_mourning":
        modifier += GameState.equipped_effect_value("public_mourning")
    modifier -= int(GameState.active_case.get("investigation_progress", 0)) / 12
    modifier -= int(GameState.active_case.get("evidence_risk", 0)) / 15
    modifier -= GameState.get_risk("social_suspicion") / 12
    return modifier

func _dialogue_context_for_choice(choice: Dictionary) -> String:
    var raw_context := String(choice.get("line_context", "match_interest"))
    return String(MATCH_DIALOGUE_CONTEXT_ALIASES.get(raw_context, raw_context))

func _select_dialogue_line(context_id: String, tags: Array) -> String:
    var templates: Array = DataManager.get_table("dialogue_templates").get("dialogue_templates", [])
    var voice_stage := String(GameState.player.get("current_voice_stage", ""))
    var best_line := ""
    var best_score := -1
    for template in templates:
        if typeof(template) != TYPE_DICTIONARY:
            continue
        if String(template.get("speaker", "")) != "protagonist":
            continue
        if String(template.get("context", "")) != context_id:
            continue
        var score := 10
        if String(template.get("voice_stage_id", "")) == voice_stage:
            score += 100
        var template_tags: Array = template.get("choice_tags", [])
        for template_tag in template_tags:
            if tags.has(String(template_tag)):
                score += 5
        if score > best_score:
            best_score = score
            best_line = String(template.get("text_ko", ""))
    return best_line

func _match_failure_reason(axes: Dictionary, axis_defs: Array, score: int, threshold: int, prep_bonus: int, critical_axes: Array[String]) -> String:
    var reasons: Array[String] = []
    if not critical_axes.is_empty():
        reasons.append("치명 기준 미달: " + _join_strings(critical_axes))
    var gap := threshold - score
    if gap > 0:
        reasons.append("총점이 기준보다 %d 부족" % gap)
    var weak_axes := _weakest_axis_names(axes, axis_defs, 2)
    if not weak_axes.is_empty():
        reasons.append("보완 필요 축: " + _join_strings(weak_axes))
    if prep_bonus < 15:
        reasons.append("준비 보너스 낮음: %d" % prep_bonus)
    if reasons.is_empty():
        return "성공 기준은 넘겼지만 치명 조건 또는 특수 조건에 걸렸습니다."
    return _join_strings(reasons)

func _weakest_axis_names(axes: Dictionary, axis_defs: Array, count: int) -> Array[String]:
    var entries: Array = []
    for axis_def in axis_defs:
        if typeof(axis_def) != TYPE_DICTIONARY:
            continue
        var axis_id := String(axis_def.get("id", ""))
        entries.append({"id": axis_id, "value": int(axes.get(axis_id, 0))})
    entries.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
        return int(left.get("value", 0)) < int(right.get("value", 0))
    )
    var names: Array[String] = []
    for i in range(mini(count, entries.size())):
        var entry: Dictionary = entries[i]
        names.append("%s %d" % [_name_for(String(entry.get("id", ""))), int(entry.get("value", 0))])
    return names

func _candidate_minimums_met(candidate: Dictionary) -> bool:
    var minimums: Dictionary = candidate.get("minimums", {})
    for key in minimums.keys():
        if GameState.get_stat(String(key)) < int(minimums[key]):
            return false
    return true

func _candidate_preparation_bonus(candidate: Dictionary) -> int:
    return GameState.candidate_preparation_bonus(candidate)

func _persona_unlocked(persona: Dictionary) -> bool:
    var conditions: Dictionary = persona.get("unlock_conditions", {})
    if conditions.get("default", false):
        return true
    for key in conditions.keys():
        var key_string := String(key)
        var required = conditions[key]
        if key_string == "min_status_rank":
            var required_rank := String(required).trim_suffix("_or_higher")
            if _rank_order(GameState.current_social_rank()) < _rank_order(required_rank):
                return false
        elif key_string.begins_with("min_"):
            var stat_id := key_string.trim_prefix("min_")
            stat_id = String({"sociability": "social", "funds": "funds_power"}.get(stat_id, stat_id))
            if GameState.get_stat(stat_id) < int(required):
                return false
        elif key_string == "required_items":
            for item_id in required:
                if not GameState.inventory.has(String(item_id)):
                    return false
        elif typeof(required) == TYPE_BOOL:
            if bool(GameState.flags.get(key_string, false)) != bool(required):
                return false
    return true

func _set_persona(persona: Dictionary) -> void:
    GameState.set_current_persona(String(persona.get("id", "")))
    GameState.add_log("페르소나 변경: " + String(persona.get("name_ko", persona.get("id", ""))))
    _show_personas()

func _current_persona() -> Dictionary:
    return DataManager.find_by_id("personas", "personas", String(GameState.player.get("current_persona", "")))

func _persona_display_name() -> String:
    var persona := _current_persona()
    if persona.is_empty():
        return String(GameState.player.get("current_persona", ""))
    return String(persona.get("name_ko", persona.get("id", "")))

func _voice_stage_display_name() -> String:
    var voice := _current_voice_stage()
    if voice.is_empty():
        return String(GameState.player.get("current_voice_stage", ""))
    return String(voice.get("name_ko", voice.get("id", "")))

func _current_voice_stage() -> Dictionary:
    return DataManager.find_by_id("dialogue_stages", "stages", String(GameState.player.get("current_voice_stage", "")))

func _apply_voice_stage_axes(axes: Dictionary) -> Dictionary:
    var voice := _current_voice_stage()
    var modifiers: Dictionary = voice.get("base_modifiers", {})
    var match_axes: Dictionary = modifiers.get("match_axes", {})
    var applied: Array[String] = []
    for key in match_axes.keys():
        var axis_id := String(key)
        var bonus := int(match_axes[key])
        axes[axis_id] = clampi(int(axes.get(axis_id, 0)) + bonus, 0, 100)
        if bonus != 0:
            applied.append("%s %s%d" % [_name_for(axis_id), "+" if bonus > 0 else "", bonus])
    if not applied.is_empty():
        GameState.add_log("대사 단계 맞선 보정: " + _join_strings(applied))
    return axes

func _apply_persona_axes(axes: Dictionary) -> Dictionary:
    var persona := _current_persona()
    var modifiers: Dictionary = persona.get("modifiers", {})
    var match_axes: Dictionary = modifiers.get("match_axes", {})
    for key in match_axes.keys():
        axes[String(key)] = clampi(int(axes.get(String(key), 0)) + int(match_axes[key]), 0, 100)
    return axes

func _prepare_screen(title: String) -> void:
    _set_match_presentation(false)
    _refresh_header()
    _refresh_nav()
    _refresh_log()
    _clear(content)
    main_scroll.scroll_vertical = 0
    _add_section(title)
    if feedback_layer != null:
        feedback_layer.call_deferred("animate_screen", content)

func _prepare_dashboard_screen() -> void:
    _set_match_presentation(false)
    _refresh_header()
    _refresh_nav()
    _refresh_log()
    _clear(content)
    main_scroll.scroll_vertical = 0
    _update_responsive_layout()
    if feedback_layer != null:
        feedback_layer.call_deferred("animate_screen", content)

func _prepare_match_screen() -> void:
    if feedback_layer != null:
        feedback_layer.call("clear_transient_banners")
    _refresh_header()
    _refresh_nav()
    _refresh_log()
    _clear(content)
    _set_match_presentation(true)
    main_scroll.scroll_vertical = 0

func _restore_pending_match_scroll() -> void:
    if pending_match_scroll_restore < 0:
        return
    var target_scroll := pending_match_scroll_restore
    pending_match_scroll_restore = -1
    call_deferred("_set_main_scroll_vertical", target_scroll)

func _set_main_scroll_vertical(value: int) -> void:
    if main_scroll != null:
        main_scroll.scroll_vertical = value

func _set_match_presentation(active: bool) -> void:
    if match_backdrop != null:
        var was_visible := match_backdrop.visible
        match_backdrop.visible = active
        if active:
            match_backdrop.call("configure_presentation", _is_compact_layout(), bool(ProjectSettings.get_setting("accessibility/reduce_motion", false)))
            if not was_visible:
                match_backdrop.call("reset_atmosphere")
        elif was_visible:
            match_backdrop.call("reset_atmosphere")
    if header_label != null:
        header_label.visible = not active
    if header_row != null:
        header_row.visible = not active
    if resource_row != null:
        resource_row.visible = not active
    if nav_bar != null:
        nav_bar.visible = not active
    if log_frame != null:
        log_frame.visible = not active
    if root != null:
        root.add_theme_constant_override("separation", 0 if active else 7 if _is_mobile_layout() else 10)
    _update_responsive_layout()

func _play_match_turn_feedback(event: Dictionary) -> void:
    if match_backdrop == null or not match_backdrop.visible:
        return
    match_backdrop.call("play_turn_feedback", event)

func _add_nav_button(label: String, callback: Callable, screen_id: String) -> void:
    var button := Button.new()
    _style_button(button, screen_id != "" and screen_id == current_screen)
    button.text = label
    button.pressed.connect(callback)
    nav_bar.add_child(button)

func _add_section(text: String) -> void:
    var label := _make_label(text, 18)
    content.add_child(label)
    content.add_child(_make_ui_image(UI_DIVIDER, Vector2(0, 26), 0.82))

func _add_text(text: String) -> void:
    content.add_child(_make_label(text, 13))

func _add_card() -> VBoxContainer:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL))
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 5)
    panel.add_child(box)
    box.add_child(_make_ui_image(UI_CARD_TRIM, Vector2(0, 18), 0.78))
    content.add_child(panel)
    return box

func _make_portrait(npc: Dictionary, size: Vector2) -> Control:
    return _make_portrait_from_path(String(npc.get("portrait", "")), size)

func _make_ui_image(path: String, min_size: Vector2, alpha: float = 1.0) -> TextureRect:
    var rect := TextureRect.new()
    rect.texture = _load_texture(path)
    rect.custom_minimum_size = min_size
    rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    rect.modulate = Color(1, 1, 1, alpha)
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return rect

func _make_spouse_portrait(npc: Dictionary, size: Vector2) -> Control:
    return _make_portrait_from_path(_spouse_portrait_path(npc), size)

func _make_portrait_from_path(texture_path: String, size: Vector2) -> Control:
    var frame := PanelContainer.new()
    frame.custom_minimum_size = size
    frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    frame.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.03, 0.028, 0.92)))

    if texture_path.is_empty():
        var placeholder := Label.new()
        placeholder.text = "초상화\n준비중"
        placeholder.custom_minimum_size = size
        placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        placeholder.add_theme_font_size_override("font_size", 11)
        placeholder.add_theme_color_override("font_color", COLOR_MUTED)
        frame.add_child(placeholder)
        return frame

    var portrait := TextureRect.new()
    portrait.custom_minimum_size = size
    portrait.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    portrait.texture = _load_texture(texture_path)
    frame.add_child(portrait)
    return frame

func _spouse_portrait_path(npc: Dictionary) -> String:
    var variants: Dictionary = npc.get("spouse_portraits", {})
    var state_key := _spouse_portrait_state_key()
    return String(variants.get(state_key, variants.get("neutral", npc.get("portrait", ""))))

func _spouse_portrait_state_key() -> String:
    if GameState.spouse.is_empty():
        return "neutral"
    if int(GameState.spouse.get("health", 100)) <= 35:
        return "weakened"
    if int(GameState.spouse.get("direct_suspicion", 0)) >= 45 or int(GameState.spouse.get("threat_alert", 0)) >= 45:
        return "suspicious"
    if int(GameState.spouse.get("affection", 0)) >= 55 or int(GameState.spouse.get("public_harmony", 0)) >= 60:
        return "affectionate"
    return "neutral"

func _spouse_portrait_state_name() -> String:
    var names := {
        "neutral": "평상",
        "affectionate": "애정",
        "suspicious": "의심",
        "weakened": "쇠약",
    }
    return names.get(_spouse_portrait_state_key(), "평상")

func _add_key_values(source: Dictionary, keys: Array) -> void:
    var grid := GridContainer.new()
    grid.columns = 2 if _is_compact_layout() else 4
    grid.set_meta("responsive_wide_columns", 4)
    grid.set_meta("responsive_compact_columns", 2)
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_child(grid)
    for key in keys:
        if not source.has(key):
            continue
        var card := PanelContainer.new()
        card.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.055, 0.045, 0.78)))
        card.custom_minimum_size = Vector2(92, 50) if _is_mobile_layout() else Vector2(104, 54) if _is_compact_layout() else Vector2(128, 54)
        grid.add_child(card)

        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 1)
        card.add_child(box)

        var label := _make_label(_name_for(String(key)), 11)
        label.add_theme_color_override("font_color", COLOR_MUTED)
        box.add_child(label)

        var value := _make_label(_format_value(source[key]), 15 if _is_mobile_layout() else 17)
        value.add_theme_color_override("font_color", COLOR_TEXT)
        box.add_child(value)

func _add_axis_bars(axes: Dictionary) -> void:
    for key in axes.keys():
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        content.add_child(row)
        var label := _make_label(_name_for(String(key)), 12)
        label.custom_minimum_size = Vector2(56, 0) if _is_mobile_layout() else Vector2(68, 0) if _is_compact_layout() else Vector2(90, 0)
        row.add_child(label)
        var bar := ProgressBar.new()
        bar.min_value = 0
        bar.max_value = 100
        bar.value = int(axes[key])
        bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(bar)

func _add_match_radar(axes: Dictionary) -> void:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL))
    content.add_child(panel)

    var row := _make_responsive_row(14)
    panel.add_child(row)

    var chart: Control = MATCH_RADAR_CHART.new()
    chart.custom_minimum_size = Vector2(240, 190) if _is_mobile_layout() else Vector2(280, 220) if _is_compact_layout() else Vector2(360, 270)
    chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    chart.call("set_axes", axes)
    row.add_child(chart)

    var summary := GridContainer.new()
    summary.columns = 2
    summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(summary)
    for axis_id in ["favor", "interest", "trust", "comfort", "face", "political_value"]:
        _add_axis_summary_card(summary, axis_id, int(axes.get(axis_id, 0)))

func _add_axis_summary_card(parent: Node, axis_id: String, value: int) -> void:
    var box := VBoxContainer.new()
    box.custom_minimum_size = Vector2(92, 48) if _is_mobile_layout() else Vector2(110, 54)
    box.add_theme_constant_override("separation", 2)
    parent.add_child(box)

    var name := _make_label(_name_for(axis_id), 11 if _is_mobile_layout() else 12)
    name.add_theme_color_override("font_color", COLOR_MUTED)
    box.add_child(name)

    var value_label := _make_label("%d%%" % value, 16 if _is_mobile_layout() else 18)
    value_label.add_theme_color_override("font_color", COLOR_TEXT)
    box.add_child(value_label)

func _add_chip_row(parent: Node, title: String, values: Dictionary, mode: String = "effect") -> void:
    if values.is_empty():
        return
    var wrapper := VBoxContainer.new()
    wrapper.add_theme_constant_override("separation", 3)
    parent.add_child(wrapper)

    var title_label := _make_label(title, 12)
    title_label.add_theme_color_override("font_color", COLOR_MUTED)
    wrapper.add_child(title_label)

    var chips := HFlowContainer.new()
    chips.add_theme_constant_override("h_separation", 5)
    chips.add_theme_constant_override("v_separation", 5)
    chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    wrapper.add_child(chips)

    for key in values.keys():
        chips.add_child(_make_value_chip(String(key), values[key], mode))

func _make_value_chip(id: String, value, mode: String) -> Control:
    var chip := PanelContainer.new()
    chip.add_theme_stylebox_override("panel", _chip_style(_chip_color(id, value, mode)))

    var label := _make_label("%s %s" % [_name_for(id), _format_chip_value(value, mode)], 11 if _is_mobile_layout() else 12)
    label.autowrap_mode = TextServer.AUTOWRAP_OFF
    label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    label.add_theme_color_override("font_color", COLOR_TEXT)
    label.custom_minimum_size = Vector2(74, 22) if _is_mobile_layout() else Vector2(88, 22)
    label.tooltip_text = label.text
    chip.add_child(label)
    return chip

func _chip_color(id: String, value, mode: String) -> Color:
    if mode == "requirement":
        return Color(0.24, 0.17, 0.08, 0.9)
    if mode == "relationship":
        return Color(0.09, 0.18, 0.18, 0.9)
    if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
        return Color(0.12, 0.11, 0.1, 0.9)
    var numeric := float(value)
    var is_risk := bool(RISK_VALUE_IDS.get(id, false))
    var is_good := numeric >= 0.0
    if is_risk:
        is_good = numeric <= 0.0
    if is_equal_approx(numeric, 0.0):
        return Color(0.12, 0.11, 0.1, 0.9)
    return Color(0.07, 0.22, 0.15, 0.92) if is_good else Color(0.28, 0.08, 0.08, 0.92)

func _format_chip_value(value, mode: String) -> String:
    if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
        var number := float(value)
        var text := _format_value(value)
        if mode == "effect" and number > 0.0:
            text = "+" + text
        return text
    return str(value)

func _chip_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = Color(0.74, 0.52, 0.22, 0.45)
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.corner_radius_top_left = 4
    style.corner_radius_top_right = 4
    style.corner_radius_bottom_left = 4
    style.corner_radius_bottom_right = 4
    style.content_margin_left = 8
    style.content_margin_right = 8
    style.content_margin_top = 3
    style.content_margin_bottom = 3
    return style

func _add_save_controls() -> void:
    var box := _add_card()
    box.add_child(_make_label("빠른 저장", 15))
    var row := HFlowContainer.new()
    row.add_theme_constant_override("h_separation", 8)
    row.add_theme_constant_override("v_separation", 8)
    box.add_child(row)

    var save_button := Button.new()
    _style_button(save_button)
    save_button.text = "덮어쓰기" if SaveManager.has_save() else "저장"
    save_button.pressed.connect(_request_quick_save)
    row.add_child(save_button)

    var load_button := Button.new()
    _style_button(load_button)
    load_button.text = "불러오기"
    load_button.disabled = not SaveManager.has_save()
    load_button.pressed.connect(func():
        if SaveManager.load_game():
            _show_dashboard()
    )
    row.add_child(load_button)

    var auto_load_button := Button.new()
    _style_button(auto_load_button)
    auto_load_button.text = "자동 불러오기"
    auto_load_button.disabled = not SaveManager.has_auto_save()
    auto_load_button.pressed.connect(func():
        if SaveManager.load_auto_save():
            _show_dashboard()
    )
    row.add_child(auto_load_button)

    box.add_child(_make_label("수동 슬롯", 15))
    for slot in range(1, SaveManager.slot_count() + 1):
        var slot_row := HFlowContainer.new()
        slot_row.add_theme_constant_override("h_separation", 8)
        slot_row.add_theme_constant_override("v_separation", 8)
        box.add_child(slot_row)

        var summary := _make_label("슬롯 %d: %s" % [slot, SaveManager.slot_summary(slot)], 12)
        summary.custom_minimum_size = Vector2(180, 0) if _is_compact_layout() else Vector2(280, 0)
        summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        slot_row.add_child(summary)

        var slot_save := Button.new()
        _style_button(slot_save)
        slot_save.text = "덮어쓰기" if SaveManager.has_slot_save(slot) else "저장"
        var save_slot_index := slot
        slot_save.pressed.connect(func():
            _request_slot_save(save_slot_index)
        )
        slot_row.add_child(slot_save)

        var slot_load := Button.new()
        _style_button(slot_load)
        slot_load.text = "불러오기"
        slot_load.disabled = not SaveManager.has_slot_save(slot)
        var load_slot_index := slot
        slot_load.pressed.connect(func():
            if SaveManager.load_slot(load_slot_index):
                _show_dashboard()
        )
        slot_row.add_child(slot_load)

func _request_quick_save() -> void:
    if not SaveManager.has_save():
        _save_quick_now()
        return
    _request_confirmation(
        "빠른 저장을 덮어쓸까요?",
        "기존 빠른 저장 내용은 새 진행 상황으로 교체됩니다.",
        "덮어쓰기",
        _save_quick_now
    )

func _save_quick_now() -> void:
    SaveManager.save_game()
    _show_dashboard()

func _request_slot_save(slot: int) -> void:
    if not SaveManager.has_slot_save(slot):
        _save_slot_now(slot)
        return
    _request_confirmation(
        "슬롯 %d을 덮어쓸까요?" % slot,
        "이 슬롯의 기존 저장 내용은 새 진행 상황으로 교체됩니다.",
        "슬롯 덮어쓰기",
        _save_slot_now.bind(slot)
    )

func _save_slot_now(slot: int) -> void:
    SaveManager.save_slot(slot)
    _show_dashboard()

func _make_label(text: String, size: int = 13) -> Label:
    var label := Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", COLOR_TEXT)
    return label

func _panel_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = Color(0.78, 0.55, 0.24, 0.68)
    style.set_border_width_all(2)
    style.set_corner_radius_all(6)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 9
    style.content_margin_bottom = 9
    return style

func _ledger_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.89, 0.80, 0.62, 0.98)
    style.border_color = Color(0.43, 0.29, 0.13, 0.95)
    style.set_border_width_all(2)
    style.set_corner_radius_all(5)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 6
    style.content_margin_bottom = 6
    return style

func _button_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = COLOR_STROKE
    style.set_border_width_all(1)
    style.set_corner_radius_all(5)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 6
    style.content_margin_bottom = 6
    return style

func _style_button(button: Button, active: bool = false) -> void:
    button.add_theme_color_override("font_color", COLOR_TEXT)
    button.add_theme_color_override("font_disabled_color", Color(0.46, 0.42, 0.36, 1.0))
    var normal := Color(0.26, 0.18, 0.09, 0.96) if active else Color(0.18, 0.12, 0.09, 0.92)
    var hover := Color(0.34, 0.24, 0.12, 0.98) if active else Color(0.28, 0.18, 0.12, 0.95)
    var pressed := Color(0.18, 0.12, 0.06, 1.0) if active else Color(0.12, 0.08, 0.065, 0.98)
    button.add_theme_stylebox_override("normal", _button_style(normal))
    button.add_theme_stylebox_override("hover", _button_style(hover))
    button.add_theme_stylebox_override("pressed", _button_style(pressed))
    button.add_theme_stylebox_override("disabled", _button_style(Color(0.08, 0.075, 0.07, 0.8)))
    _bind_button_feedback(button)

func _bind_button_feedback(button: Button) -> void:
    if feedback_layer != null:
        feedback_layer.call("bind_button", button)

func _load_texture(path: String) -> Texture2D:
    if texture_cache.has(path):
        return texture_cache[path]
    var resource := ResourceLoader.load(path)
    if resource is Texture2D:
        var texture: Texture2D = resource
        texture_cache[path] = texture
        return texture
    push_warning("Texture resource load failed: " + path)
    var fallback := Image.create(16, 16, false, Image.FORMAT_RGBA8)
    fallback.fill(Color(0.08, 0.06, 0.05, 1.0))
    var fallback_texture := ImageTexture.create_from_image(fallback)
    texture_cache[path] = fallback_texture
    return fallback_texture

func _dict_to_text(dict: Dictionary) -> String:
    if dict.is_empty():
        return "없음"
    var parts: Array[String] = []
    for key in dict.keys():
        parts.append("%s %s" % [_name_for(String(key)), _format_value(dict[key])])
    return _join_strings(parts)

func _relationship_summary(dict: Dictionary) -> String:
    if dict.is_empty():
        return "없음"
    var preferred := ["favor", "trust", "respect", "transaction_value", "suspicion", "leverage"]
    var parts: Array[String] = []
    for key in preferred:
        if dict.has(key):
            parts.append("%s %s" % [_name_for(key), _format_value(dict[key])])
    return _join_strings(parts)

func _array_to_text(values: Array) -> String:
    if values.is_empty():
        return "없음"
    var parts: Array[String] = []
    for value in values:
        parts.append(str(value))
    return _join_strings(parts)

func _join_strings(parts: Array[String]) -> String:
    var text := ""
    for i in range(parts.size()):
        if i > 0:
            text += ", "
        text += parts[i]
    return text

func _name_for(id: String) -> String:
    var stat_name := String(STAT_NAMES.get(id, ""))
    if not stat_name.is_empty():
        return stat_name
    return GameState._flag_name(id)

func _slot_name(id: String) -> String:
    return SLOT_NAMES.get(id, id)

func _role_name(id: String) -> String:
    return ROLE_NAMES.get(id, id)

func _rank_name(id: String) -> String:
    return RANK_NAMES.get(id, id)

func _rank_order(id: String) -> int:
    var order := {
        "commoner": 0,
        "knight": 1,
        "baron": 2,
        "viscount": 3,
        "count": 4,
        "marquis": 5,
        "duke": 6,
        "royal": 7,
    }
    return int(order.get(id, 99))

func _faction_name(id: String) -> String:
    return FACTION_NAMES.get(id, id)

func _trait_list_text(values: Array) -> String:
    if values.is_empty():
        return "없음"
    var parts: Array[String] = []
    for value in values:
        parts.append(TRAIT_NAMES.get(String(value), String(value)))
    return _join_strings(parts)

func _format_value(value) -> String:
    if typeof(value) == TYPE_FLOAT:
        var rounded := int(value)
        if is_equal_approx(float(rounded), value):
            return str(rounded)
    return str(value)

func _clear(node: Node) -> void:
    for child in node.get_children():
        node.remove_child(child)
        child.queue_free()
