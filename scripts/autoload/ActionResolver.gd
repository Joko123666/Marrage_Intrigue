extends Node

const STAT_INFLUENCE_CALCULATOR := preload("res://scripts/systems/StatInfluenceCalculator.gd")

# 역할: 데이터 기반 행동 실행. 요구조건 확인, 비용/효과 적용, 시간 경과를 처리한다.

func _value_as_int(id: String) -> int:
    var value = GameState.get_value(id)
    if value == null:
        return 0
    return int(value)

func can_run_action(action: Dictionary) -> bool:
    var requirements: Dictionary = action.get("requirements", {})
    for key in requirements.keys():
        var required = requirements[key]
        var key_string := String(key)
        if key_string.begins_with("min_"):
            var stat_id := key_string.trim_prefix("min_")
            if _value_as_int(stat_id) < int(required):
                return false
        elif typeof(required) == TYPE_BOOL:
            if bool(GameState.get_value(key_string)) != bool(required):
                return false
        elif typeof(required) == TYPE_INT or typeof(required) == TYPE_FLOAT:
            var current = GameState.get_value(key_string)
            if current == null or int(current) < int(required):
                return false
        elif key_string == "rank_min":
            continue
        elif GameState.get_value(key_string) == null:
            return false

    var cost: Dictionary = action.get("cost", {})
    for key in cost.keys():
        var key_string := String(key)
        var stat_id := key_string.replace("_min", "") if key_string.ends_with("_min") else key_string
        var current = GameState.get_value(stat_id)
        if current == null:
            return false
        if key_string.ends_with("_min"):
            if int(current) < int(cost[key]):
                return false
        elif stat_id == "fatigue" or stat_id == "stress":
            if int(current) + int(cost[key]) > 100:
                return false
        elif int(current) < int(cost[key]):
            return false
    return true

func explain_blocker(action: Dictionary) -> String:
    if can_run_action(action):
        return ""
    var requirements: Dictionary = action.get("requirements", {})
    for key in requirements.keys():
        var required = requirements[key]
        var key_string := String(key)
        if key_string.begins_with("min_"):
            var stat_id := key_string.trim_prefix("min_")
            if _value_as_int(stat_id) < int(required):
                return "%s %d 필요" % [_display_name(stat_id), int(required)]
        elif typeof(required) == TYPE_BOOL:
            if bool(GameState.get_value(key_string)) != bool(required):
                return "%s 필요" % _display_name(key_string)
        elif typeof(required) == TYPE_INT or typeof(required) == TYPE_FLOAT:
            var current = GameState.get_value(key_string)
            if current == null or int(current) < int(required):
                return "%s %d 필요" % [_display_name(key_string), int(required)]

    var cost: Dictionary = action.get("cost", {})
    for key in cost.keys():
        var key_string := String(key)
        var stat_id := key_string.replace("_min", "") if key_string.ends_with("_min") else key_string
        var current = GameState.get_value(stat_id)
        if current == null:
            return "%s 값 없음" % _display_name(stat_id)
        if key_string.ends_with("_min") and int(current) < int(cost[key]):
            return "%s %d 필요" % [_display_name(stat_id), int(cost[key])]
        if (stat_id == "fatigue" or stat_id == "stress") and int(current) + int(cost[key]) > 100:
            return "%s가 100을 초과함" % _display_name(stat_id)
        if stat_id != "fatigue" and stat_id != "stress" and int(current) < int(cost[key]):
            return "%s %d 필요" % [_display_name(stat_id), int(cost[key])]
    return "조건 미충족"

func _display_name(id: String) -> String:
    return String(GameState.call("_value_name", id))

func run_action(action: Dictionary) -> bool:
    if not can_run_action(action):
        GameState.add_log("행동 조건 미충족: " + String(action.get("name_ko", action.get("id", "unknown"))) + " / " + explain_blocker(action))
        GameState.request_feedback({
            "type": "outcome",
            "tone": "warning",
            "title": "실행할 수 없음",
            "detail": explain_blocker(action),
        })
        return false
    var evaluation := evaluate_action(action)
    var effects := adjusted_effects(action, {}, evaluation)
    effects = _effects_with_item_bonuses(action, effects)
    GameState.apply_effects(effects)
    apply_action_relationship_effects(action, evaluation)
    _apply_open_ui_side_effects(action)
    var weeks := int(action.get("weeks", 1))
    TimeManager.advance_weeks(weeks)
    GameState.add_log("행동 실행: %s / %d주 경과" % [action.get("name_ko", action.get("id", "unknown")), weeks])
    GameState.request_feedback({
        "type": "action_result",
        "tone": "success",
        "title": String(action.get("name_ko", action.get("id", "unknown"))),
        "kicker": _action_result_kicker(action),
        "detail": String(action.get("result_ko", action.get("summary_ko", "계획한 일을 마쳤습니다."))),
        "backdrop": String(action.get("result_backdrop", "")),
        "effects": effects.duplicate(true),
        "weeks": weeks,
        "category": String(action.get("category", "")),
    })
    return true

func _action_result_kicker(action: Dictionary) -> String:
    match String(action.get("category", "")):
        "self_improvement": return "육성 기록"
        "economy": return "생활 기록"
        "rumor": return "정보 활동"
        "social": return "사교 활동"
        "recovery": return "휴식 기록"
        "shop": return "준비 활동"
        _: return "행동 기록"

func apply_action_relationship_effects(action: Dictionary, evaluation: Dictionary = {}) -> void:
    var target_npc_id := String(action.get("target_npc_id", ""))
    if target_npc_id.is_empty():
        return
    var relationship_effects: Dictionary = adjusted_effects(action, action.get("relationship_effects", {}), evaluation)
    for key in relationship_effects.keys():
        var value = relationship_effects[key]
        if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
            GameState.change_relationship(target_npc_id, String(key), int(value))

func _effects_with_item_bonuses(action: Dictionary, base_effects: Dictionary = {}) -> Dictionary:
    var effects: Dictionary = base_effects.duplicate(true) if not base_effects.is_empty() else action.get("effects", {}).duplicate(true)
    var action_id := String(action.get("id", ""))
    if action_id == "practice_etiquette":
        var bonus := GameState.equipped_effect_value("etiquette_training_bonus")
        if bonus > 0:
            effects["etiquette"] = int(effects.get("etiquette", 0)) + bonus
            effects["grace"] = int(effects.get("grace", 0)) + bonus
            GameState.add_log("아이템 보정: 예법 훈련 효율 +%d" % bonus)
    return effects

func run_operation(operation: Dictionary, success_bonus: int = 0) -> bool:
    if not can_run_action(operation):
        GameState.add_log("작전 조건 미충족: " + String(operation.get("name_ko", operation.get("id", "unknown"))) + " / " + explain_blocker(operation))
        GameState.request_feedback({
            "type": "outcome",
            "tone": "warning",
            "title": "작전을 실행할 수 없음",
            "detail": explain_blocker(operation),
        })
        return false
    var evaluation := evaluate_action(operation, success_bonus)
    var base_success := int(evaluation.get("chance", 100))
    var roll := randi_range(1, 100)
    var success := roll <= clampi(base_success, 5, 95)
    var cost: Dictionary = operation.get("cost", {})
    var cost_effects := {}
    for key in cost.keys():
        cost_effects[key] = -int(cost[key])
    GameState.apply_effects(cost_effects)
    var outcome_effects: Dictionary = operation.get("effects_on_success" if success else "effects_on_fail", {})
    GameState.apply_effects(adjusted_effects(operation, outcome_effects, evaluation))
    apply_operation_relationship_effects(operation, success)
    TimeManager.advance_weeks(int(operation.get("weeks", 1)))
    GameState.add_log("%s: %s (판정 %d/%d)" % [operation.get("name_ko", operation.get("id", "unknown")), "성공" if success else "실패", roll, base_success])
    GameState.request_feedback({
        "type": "outcome",
        "tone": "success" if success else "failure",
        "title": "작전 성공" if success else "작전 실패",
        "detail": "%s · 판정 %d / %d" % [String(operation.get("name_ko", operation.get("id", "unknown"))), roll, base_success],
    })
    return success

func apply_operation_relationship_effects(operation: Dictionary, success: bool) -> void:
    var target_npc_id := String(operation.get("target_npc_id", ""))
    if target_npc_id.is_empty():
        return
    var field := "relationship_effects_on_success" if success else "relationship_effects_on_fail"
    var relationship_effects: Dictionary = operation.get(field, {})
    for key in relationship_effects.keys():
        var value = relationship_effects[key]
        if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
            GameState.change_relationship(target_npc_id, String(key), int(value))

func evaluate_action(action: Dictionary, extra_chance_modifier: int = 0) -> Dictionary:
    return STAT_INFLUENCE_CALCULATOR.evaluate(action, GameState.player.get("stats", {}), extra_chance_modifier)

func adjusted_effects(action: Dictionary, effects: Dictionary = {}, evaluation: Dictionary = {}) -> Dictionary:
    var source_effects := effects if not effects.is_empty() else Dictionary(action.get("effects", {}))
    return STAT_INFLUENCE_CALCULATOR.adjusted_effects(action, source_effects, GameState.player.get("stats", {}), evaluation)

func influence_summary(action: Dictionary, extra_chance_modifier: int = 0) -> String:
    return STAT_INFLUENCE_CALCULATOR.summary(evaluate_action(action, extra_chance_modifier), GameState.VALUE_NAMES)

func _apply_open_ui_side_effects(action: Dictionary) -> void:
    var action_id := String(action.get("id", ""))
    if action_id == "gather_rumor":
        var quality := clampi(GameState.get_stat("information") * 3, 10, 85)
        GameState.unlock_candidates_for_rank("knight", quality, 1)
    elif action_id == "attend_social_event" and GameState.get_stat("status") >= 1:
        GameState.unlock_accessible_candidates(clampi(GameState.get_stat("information") * 2, 0, 70), 1)
