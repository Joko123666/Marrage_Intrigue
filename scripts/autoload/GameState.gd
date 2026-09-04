extends Node

# 역할: 플레이 중 변하는 런타임 상태를 보관한다.
# 실제 프로젝트에서는 SaveManager와 연동한다.

signal state_changed(path: String, value)
signal log_changed()
signal feedback_event(event: Dictionary)

var week: int = 1
var age_years: int = 14
var player: Dictionary = {}
var flags: Dictionary = {}
var log: Array[String] = []
var inventory: Array[String] = []
var equipped: Dictionary = {}
var equipped_applied_effects: Dictionary = {}
var known_candidates: Dictionary = {}
var relationships: Dictionary = {}
var spouse: Dictionary = {}
var active_case: Dictionary = {}
var current_match: Dictionary = {}

var _feedback_batch_depth: int = 0
var _feedback_batch_changes: Dictionary = {}

const SAVE_SCHEMA_VERSION := 3
const MATCH_OUTCOME_CALCULATOR := preload("res://scripts/systems/MatchOutcomeCalculator.gd")

const FLAG_NAMES := {
    "tutorial_completed": "튜토리얼 완료",
    "entered_nobility": "귀족 사회 진입",
    "married": "결혼",
    "widowed_once": "첫 미망인 상태",
    "access_to_household": "저택 접근권",
    "available_event": "사교 행사 가능",
    "match_success_pending": "결혼식 대기",
    "spouse_dashboard_seen": "배우자 대시보드 확인",
    "widowed": "미망인",
    "game_over": "게임오버 후보",
    "case_resolved": "사건 종결",
    "first_failure_seen": "첫 실패 안내",
    "first_danger_warning_seen": "첫 위험 상승 안내",
    "accusation_event_seen": "범인 지목 이벤트",
    "marriage_ended_nonlethal": "비치명 혼인 종료",
    "last_wedding_event_id": "최근 결혼식 이벤트",
    "last_wedding_event_title": "최근 결혼식 결과",
    "last_wedding_event_text": "최근 결혼식 결과 설명",
    "last_removal_counter_id": "최근 처리 대응 이벤트",
    "last_removal_counter_title": "최근 처리 대응",
    "last_removal_counter_text": "최근 처리 대응 설명",
    "last_removal_result_type": "최근 처리 결과 유형",
    "last_removal_result_title": "최근 처리 결과",
    "last_removal_result_text": "최근 처리 결과 설명",
    "last_rank_event_id": "최근 작위 압박 이벤트",
    "last_rank_event_title": "최근 작위 압박",
    "last_rank_event_text": "최근 작위 압박 설명",
    "last_rank_event_week": "최근 작위 압박 주차",
}

const VALUE_NAMES := {
    "beauty": "외모",
    "culture": "교양",
    "grace": "기품",
    "etiquette": "예법",
    "wildness": "야성",
    "mask": "가면술",
    "impulse_control": "충동제어",
    "funds_power": "배경자금",
    "cash": "자금",
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
    "health": "건강",
    "affection": "애정",
    "direct_suspicion": "직접 의심",
    "threat_alert": "경계도",
    "public_harmony": "공개 금슬",
    "investigation_progress": "조사 진행도",
    "rumor_spread": "소문 확산도",
    "evidence_risk": "증거 위험도",
    "alibi_strength": "알리바이 강도",
    "public_grief": "공개 애도",
    "etiquette_training_bonus": "예법 훈련 보너스",
    "public_mourning": "공개 애도",
    "widow_count": "미망인 횟수",
    "success_modifier": "성공률 보정",
    "case_type": "사건 유형",
}

const RELATIONSHIP_NAMES := {
    "favor": "호감",
    "trust": "신뢰",
    "respect": "존중",
    "transaction_value": "거래 가치",
    "fear": "공포",
    "loyalty": "충성",
    "suspicion": "의심",
    "debt": "빚",
    "leverage": "약점",
}

const RANK_ORDER := {
    "commoner": 0,
    "knight": 1,
    "baron": 2,
    "viscount": 3,
    "count": 4,
    "marquis": 5,
    "duke": 6,
    "royal": 7,
}

const PROGRESSION_STAT_ALIASES := {
    "sociability": "social",
    "funds": "funds_power",
}

func start_new_game(initial_state: Dictionary) -> void:
    week = initial_state.get("start_week", 1)
    age_years = initial_state.get("start_age_years", 14)
    player = initial_state.duplicate(true)
    flags = player.get("flags", {}).duplicate(true)
    inventory.clear()
    equipped.clear()
    equipped_applied_effects.clear()
    known_candidates.clear()
    relationships.clear()
    spouse.clear()
    active_case.clear()
    current_match.clear()
    _initialize_relationships()
    log.clear()
    add_log("게임 시작: 14세, 평민 고아.")
    emit_signal("state_changed", "game/new", true)

func export_state() -> Dictionary:
    return {
        "schema_version": SAVE_SCHEMA_VERSION,
        "week": week,
        "age_years": age_years,
        "player": player.duplicate(true),
        "flags": flags.duplicate(true),
        "log": log.duplicate(),
        "inventory": inventory.duplicate(),
        "equipped": equipped.duplicate(true),
        "equipped_applied_effects": equipped_applied_effects.duplicate(true),
        "known_candidates": known_candidates.duplicate(true),
        "relationships": relationships.duplicate(true),
        "spouse": spouse.duplicate(true),
        "active_case": active_case.duplicate(true),
        "current_match": current_match.duplicate(true),
}

func import_state(state: Dictionary) -> void:
    var migrated := _migrate_state(state)
    week = int(migrated.get("week", 1))
    age_years = int(migrated.get("age_years", 14))
    player = migrated.get("player", {}).duplicate(true)
    flags = migrated.get("flags", player.get("flags", {})).duplicate(true)
    player["flags"] = flags

    log.clear()
    for entry in migrated.get("log", []):
        log.append(String(entry))

    inventory.clear()
    for item_id in migrated.get("inventory", []):
        inventory.append(String(item_id))

    equipped = migrated.get("equipped", {}).duplicate(true)
    equipped_applied_effects = migrated.get("equipped_applied_effects", {}).duplicate(true)
    known_candidates = migrated.get("known_candidates", {}).duplicate(true)
    relationships = migrated.get("relationships", {}).duplicate(true)
    spouse = migrated.get("spouse", {}).duplicate(true)
    active_case = migrated.get("active_case", {}).duplicate(true)
    current_match = migrated.get("current_match", {}).duplicate(true)

    add_log("저장 데이터 불러오기 완료.")
    emit_signal("state_changed", "game/load", true)

func _migrate_state(state: Dictionary) -> Dictionary:
    var migrated := state.duplicate(true)
    if int(migrated.get("schema_version", 0)) < 1:
        migrated["schema_version"] = 1
    if not migrated.has("player") or typeof(migrated.get("player")) != TYPE_DICTIONARY:
        migrated["player"] = DataManager.get_table("player_initial_state").duplicate(true)
    var migrated_player: Dictionary = migrated.get("player", {})
    if not migrated_player.has("stats"):
        migrated_player["stats"] = DataManager.get_table("player_initial_state").get("stats", {}).duplicate(true)
    if not migrated_player.has("global_risks"):
        migrated_player["global_risks"] = DataManager.get_table("player_initial_state").get("global_risks", {}).duplicate(true)
    if not migrated_player.has("flags"):
        migrated_player["flags"] = {}
    if not migrated_player.has("counters"):
        migrated_player["counters"] = {}
    migrated["player"] = migrated_player
    if not migrated.has("flags") or typeof(migrated.get("flags")) != TYPE_DICTIONARY:
        migrated["flags"] = migrated_player.get("flags", {}).duplicate(true)
    if not migrated.has("log") or typeof(migrated.get("log")) != TYPE_ARRAY:
        migrated["log"] = []
    if not migrated.has("inventory") or typeof(migrated.get("inventory")) != TYPE_ARRAY:
        migrated["inventory"] = []
    for key in ["equipped", "equipped_applied_effects", "known_candidates", "relationships", "spouse", "active_case", "current_match"]:
        if not migrated.has(key) or typeof(migrated.get(key)) != TYPE_DICTIONARY:
            migrated[key] = {}
    if int(migrated.get("schema_version", 0)) < 3 and Dictionary(migrated.get("equipped_applied_effects", {})).is_empty():
        migrated["equipped_applied_effects"] = _legacy_equipped_effects(Dictionary(migrated.get("equipped", {})))
    var migrated_relationships: Dictionary = migrated.get("relationships", {})
    if migrated_relationships.is_empty():
        migrated["relationships"] = _default_relationships()
    migrated["schema_version"] = SAVE_SCHEMA_VERSION
    return migrated

func _legacy_equipped_effects(legacy_equipped: Dictionary) -> Dictionary:
    var result := {}
    for slot in legacy_equipped.keys():
        var item := DataManager.find_by_id("items", "items", String(legacy_equipped.get(slot, "")))
        var numeric_effects := {}
        for key in Dictionary(item.get("effects", {})).keys():
            var value = Dictionary(item.get("effects", {})).get(key)
            if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
                numeric_effects[String(key)] = int(value)
        result[String(slot)] = numeric_effects
    return result

func _default_relationships() -> Dictionary:
    var defaults := {}
    var characters: Array = DataManager.get_table("npcs").get("characters", [])
    for npc in characters:
        if typeof(npc) != TYPE_DICTIONARY:
            continue
        defaults[String(npc.get("id", ""))] = npc.get("relationship", {}).duplicate(true)
    return defaults

func _initialize_relationships() -> void:
    relationships.clear()
    var characters: Array = DataManager.get_table("npcs").get("characters", [])
    for npc in characters:
        if typeof(npc) != TYPE_DICTIONARY:
            continue
        var npc_id := String(npc.get("id", ""))
        relationships[npc_id] = npc.get("relationship", {}).duplicate(true)

func add_log(message: String) -> void:
    log.append("[W%03d] %s" % [week, message])
    if log.size() > 200:
        log.pop_front()
    emit_signal("log_changed")

func change_stat(stat_id: String, delta: int) -> void:
    if delta == 0:
        return
    var stats: Dictionary = player.get("stats", {})
    if stats.has(stat_id):
        var old_val: int = int(stats.get(stat_id, 0))
        var new_val: int = clampi(old_val + delta, 0, 100)
        stats[stat_id] = new_val
        player["stats"] = stats
        add_log("%s %s%d -> %d" % [_value_name(stat_id), "+" if delta > 0 else "", delta, new_val])
        emit_signal("state_changed", "stats/" + stat_id, new_val)
        _record_feedback_change("stats/" + stat_id, stat_id, new_val - old_val, new_val)
        return

    var risks: Dictionary = player.get("global_risks", {})
    if risks.has(stat_id):
        var old_risk: int = int(risks.get(stat_id, 0))
        var new_risk: int = clampi(old_risk + delta, 0, 100)
        risks[stat_id] = new_risk
        player["global_risks"] = risks
        add_log("%s %s%d -> %d" % [_value_name(stat_id), "+" if delta > 0 else "", delta, new_risk])
        emit_signal("state_changed", "global_risks/" + stat_id, new_risk)
        _record_feedback_change("global_risks/" + stat_id, stat_id, new_risk - old_risk, new_risk)
        return

    if spouse.has(stat_id):
        var old_spouse: int = int(spouse.get(stat_id, 0))
        var new_spouse: int = clampi(old_spouse + delta, 0, 100)
        spouse[stat_id] = new_spouse
        add_log("%s %s%d -> %d" % [_value_name(stat_id), "+" if delta > 0 else "", delta, new_spouse])
        emit_signal("state_changed", "spouse/" + stat_id, new_spouse)
        _record_feedback_change("spouse/" + stat_id, stat_id, new_spouse - old_spouse, new_spouse)
        return

    if active_case.has(stat_id):
        var old_case: int = int(active_case.get(stat_id, 0))
        var new_case: int = clampi(old_case + delta, 0, 100)
        active_case[stat_id] = new_case
        add_log("%s %s%d -> %d" % [_value_name(stat_id), "+" if delta > 0 else "", delta, new_case])
        emit_signal("state_changed", "case/" + stat_id, new_case)
        _record_feedback_change("case/" + stat_id, stat_id, new_case - old_case, new_case)
        return

    var counters: Dictionary = player.get("counters", {})
    var old_counter: int = int(counters.get(stat_id, 0))
    var new_counter: int = clampi(old_counter + delta, 0, 100)
    counters[stat_id] = new_counter
    player["counters"] = counters
    add_log("%s %s%d -> %d" % [_value_name(stat_id), "+" if delta > 0 else "", delta, new_counter])
    emit_signal("state_changed", "counters/" + stat_id, new_counter)
    _record_feedback_change("counters/" + stat_id, stat_id, new_counter - old_counter, new_counter)

func apply_effects(effects: Dictionary) -> void:
    var starts_batch := _feedback_batch_depth == 0
    if starts_batch:
        _feedback_batch_changes.clear()
    _feedback_batch_depth += 1
    for key in effects.keys():
        var value = effects[key]
        if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
            change_stat(String(key), int(value))
        elif typeof(value) == TYPE_BOOL:
            set_flag(String(key), bool(value))
    _feedback_batch_depth -= 1
    if starts_batch:
        _flush_feedback_changes()

func request_feedback(event: Dictionary) -> void:
    if event.is_empty():
        return
    emit_signal("feedback_event", event)

func _record_feedback_change(path: String, stat_id: String, delta: int, value: int) -> void:
    if delta == 0:
        return
    var change := {
        "id": stat_id,
        "name": _value_name(stat_id),
        "delta": delta,
        "value": value,
    }
    if _feedback_batch_depth > 0:
        if _feedback_batch_changes.has(path):
            var previous: Dictionary = _feedback_batch_changes[path]
            change["delta"] = int(previous.get("delta", 0)) + delta
        _feedback_batch_changes[path] = change
        return
    request_feedback({"type": "effects", "changes": {path: change}})

func _flush_feedback_changes() -> void:
    if _feedback_batch_changes.is_empty():
        return
    request_feedback({"type": "effects", "changes": _feedback_batch_changes.duplicate(true)})
    _feedback_batch_changes.clear()

func get_stat(stat_id: String) -> int:
    var stats: Dictionary = player.get("stats", {})
    return int(stats.get(stat_id, 0))

func get_risk(risk_id: String) -> int:
    var risks: Dictionary = player.get("global_risks", {})
    return int(risks.get(risk_id, 0))

func get_value(id: String):
    var stats: Dictionary = player.get("stats", {})
    if stats.has(id):
        return stats[id]
    var risks: Dictionary = player.get("global_risks", {})
    if risks.has(id):
        return risks[id]
    if flags.has(id):
        return flags[id]
    if spouse.has(id):
        return spouse[id]
    if active_case.has(id):
        return active_case[id]
    var counters: Dictionary = player.get("counters", {})
    if counters.has(id):
        return counters[id]
    if id == "week":
        return week
    if id == "age_years":
        return age_years
    return null

func set_flag(flag_id: String, value: bool = true) -> void:
    flags[flag_id] = value
    player["flags"] = flags
    add_log("%s: %s" % [_flag_name(flag_id), "예" if value else "아니오"])
    emit_signal("state_changed", "flags/" + flag_id, value)

func match_start_blocker() -> String:
    if bool(flags.get("game_over", false)):
        return "게임이 종료된 상태입니다."
    if bool(flags.get("married", false)) or not spouse.is_empty():
        return "현재 혼인이 유지 중입니다."
    if bool(flags.get("match_success_pending", false)):
        return "성공한 맞선의 결혼식을 먼저 진행해야 합니다."
    if not active_case.is_empty():
        return "진행 중인 사건을 먼저 종결해야 합니다."
    if not current_match.is_empty():
        return "이미 진행 중인 맞선이 있습니다."
    return ""

func can_start_match() -> bool:
    return match_start_blocker().is_empty()

func begin_match(candidate_id: String, turns_left: int, axes: Dictionary) -> bool:
    if not can_start_match() or candidate_id.is_empty():
        return false
    flags.erase("last_match_failure_reason")
    player["flags"] = flags
    current_match = {
        "candidate_id": candidate_id,
        "turns_left": turns_left,
        "axes": axes.duplicate(true),
        "choice_history": [],
        "choice_usage": {},
    }
    add_log("맞선 시작: " + _candidate_display_name(candidate_id))
    emit_signal("state_changed", "match/start", current_match)
    return true

func record_match_turn(choice_name: String, effects: Dictionary, reaction: String, dialogue: String, readiness_state: String = "stable", choice_id: String = "") -> Dictionary:
    if current_match.is_empty() or not String(current_match.get("result", "")).is_empty():
        return {}
    var axes: Dictionary = current_match.get("axes", {}).duplicate(true)
    var net_effect := 0
    for key in effects.keys():
        var delta := int(effects[key])
        axes[String(key)] = clampi(int(axes.get(String(key), 0)) + delta, 0, 100)
        net_effect += delta
    current_match["axes"] = axes
    current_match["turns_left"] = int(current_match.get("turns_left", 0)) - 1
    current_match["last_choice_name"] = choice_name
    current_match["last_effects"] = effects.duplicate(true)
    current_match["last_reaction"] = reaction
    current_match["last_readiness_state"] = readiness_state
    var history_id := choice_id if not choice_id.is_empty() else choice_name
    var choice_usage: Dictionary = current_match.get("choice_usage", {}).duplicate(true)
    choice_usage[history_id] = int(choice_usage.get(history_id, 0)) + 1
    current_match["choice_usage"] = choice_usage
    var choice_history: Array = current_match.get("choice_history", []).duplicate()
    choice_history.append(history_id)
    current_match["choice_history"] = choice_history
    if dialogue.is_empty():
        current_match.erase("last_dialogue")
    else:
        current_match["last_dialogue"] = dialogue
        add_log("대사: " + dialogue)
    add_log("맞선 선택: " + choice_name)
    emit_signal("state_changed", "match/turn", current_match)
    return {"net_effect": net_effect, "turns_left": int(current_match.get("turns_left", 0))}

func finalize_match(success: bool, candidate_id: String, failure_reason: String, score: int, threshold: int, preparation_bonus: int) -> void:
    if current_match.is_empty():
        return
    if success:
        flags["match_success_pending"] = true
        flags["pending_spouse_candidate"] = candidate_id
        flags.erase("last_match_failure_reason")
        current_match["result"] = "success"
        current_match.erase("failure_reason")
    else:
        flags["last_match_failure_reason"] = failure_reason
        current_match["result"] = "failure"
        current_match["failure_reason"] = failure_reason
    player["flags"] = flags
    current_match["final_score"] = score
    current_match["result_threshold"] = threshold
    current_match["prep_bonus"] = preparation_bonus
    emit_signal("state_changed", "match/result", current_match)

func clear_current_match() -> void:
    if current_match.is_empty():
        return
    current_match.clear()
    emit_signal("state_changed", "match/clear", true)

func complete_wedding_transition() -> void:
    flags["match_success_pending"] = false
    flags.erase("pending_spouse_candidate")
    player["flags"] = flags
    current_match.clear()
    emit_signal("state_changed", "marriage/wedding_complete", true)

func remove_current_spouse() -> String:
    var previous_rank := String(spouse.get("rank", ""))
    spouse.clear()
    flags["married"] = false
    player["flags"] = flags
    emit_signal("state_changed", "spouse/removed", true)
    return previous_rank

func set_current_persona(persona_id: String) -> void:
    player["current_persona"] = persona_id
    emit_signal("state_changed", "player/current_persona", persona_id)

func unlock_candidate(candidate_id: String, quality: int = 0) -> void:
    var old_quality: int = int(known_candidates.get(candidate_id, -1))
    var new_quality: int = maxi(old_quality, quality)
    known_candidates[candidate_id] = new_quality
    var candidate_name := _candidate_display_name(candidate_id)
    if old_quality < 0:
        add_log("새 결혼 후보 발견: " + candidate_name)
        request_feedback({
            "type": "discovery",
            "tone": "info",
            "title": "새 혼인 후보 발견",
            "detail": candidate_name,
        })
    elif new_quality > old_quality:
        add_log("후보 정보 품질 상승: %s %d" % [candidate_name, new_quality])
    emit_signal("state_changed", "candidates/" + candidate_id, new_quality)

func unlock_candidates_for_rank(rank_id: String, quality: int = 0, count: int = 1) -> int:
    var unlocked := 0
    var candidates: Array = DataManager.get_table("candidate_profiles").get("candidate_profiles", [])
    for candidate in candidates:
        if typeof(candidate) != TYPE_DICTIONARY:
            continue
        if String(candidate.get("rank", "")) != rank_id:
            continue
        var candidate_id := String(candidate.get("id", ""))
        if known_candidates.has(candidate_id):
            continue
        unlock_candidate(candidate_id, quality)
        unlocked += 1
        if unlocked >= count:
            break
    return unlocked

func unlock_or_improve_candidates_for_rank(rank_id: String, quality: int = 0, count: int = 1) -> int:
    var changed := unlock_candidates_for_rank(rank_id, quality, count)
    if changed >= count:
        return changed

    var candidates: Array = DataManager.get_table("candidate_profiles").get("candidate_profiles", [])
    for candidate in candidates:
        if typeof(candidate) != TYPE_DICTIONARY:
            continue
        if String(candidate.get("rank", "")) != rank_id:
            continue
        var candidate_id := String(candidate.get("id", ""))
        if not known_candidates.has(candidate_id):
            continue
        var old_quality := int(known_candidates.get(candidate_id, 0))
        if old_quality >= quality:
            continue
        unlock_candidate(candidate_id, quality)
        changed += 1
        if changed >= count:
            break
    return changed

func unlock_next_rank_candidates(current_rank: String, quality: int = 0, count: int = 1) -> int:
    var next_rank := next_marriage_rank(current_rank)
    if next_rank == "":
        add_log("다음 작위 후보가 없습니다.")
        return 0
    var changed := unlock_or_improve_candidates_for_rank(next_rank, quality, count)
    if changed > 0:
        add_log("다음 작위 후보 접근: " + _rank_display_name(next_rank))
    return changed

func next_marriage_rank(current_rank: String) -> String:
    var order := ["knight", "baron", "viscount", "count", "marquis", "duke"]
    var index := order.find(current_rank)
    if index < 0 or index >= order.size() - 1:
        return ""
    return String(order[index + 1])

func _rank_display_name(rank_id: String) -> String:
    var rank := DataManager.find_by_id("nobility_ranks", "ranks", rank_id)
    return String(rank.get("name_ko", rank_id))

func unlock_accessible_candidates(quality: int = 0, count: int = 1) -> int:
    var unlocked := 0
    var candidates: Array = DataManager.get_table("candidate_profiles").get("candidate_profiles", [])
    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var rank_a := String(a.get("rank", ""))
        var rank_b := String(b.get("rank", ""))
        if int(RANK_ORDER.get(rank_a, 99)) == int(RANK_ORDER.get(rank_b, 99)):
            return String(a.get("id", "")) < String(b.get("id", ""))
        return int(RANK_ORDER.get(rank_a, 99)) < int(RANK_ORDER.get(rank_b, 99))
    )
    for candidate in candidates:
        if typeof(candidate) != TYPE_DICTIONARY:
            continue
        var candidate_id := String(candidate.get("id", ""))
        if known_candidates.has(candidate_id):
            continue
        if not _candidate_market_accessible(candidate):
            continue
        unlock_candidate(candidate_id, quality)
        unlocked += 1
        if unlocked >= count:
            break
    return unlocked

func get_relationship(npc_id: String) -> Dictionary:
    if not relationships.has(npc_id):
        relationships[npc_id] = {}
    return relationships[npc_id]

func change_relationship(npc_id: String, axis: String, delta: int) -> void:
    var rel := get_relationship(npc_id)
    var old_value := int(rel.get(axis, 0))
    var new_value := clampi(old_value + delta, -100, 100)
    rel[axis] = new_value
    relationships[npc_id] = rel
    add_log("%s 관계 %s %s%d -> %d" % [_npc_display_name(npc_id), _relationship_name(axis), "+" if delta > 0 else "", delta, new_value])
    emit_signal("state_changed", "relationships/" + npc_id + "/" + axis, new_value)
    var actual_delta := new_value - old_value
    if actual_delta != 0:
        request_feedback({
            "type": "relationship",
            "title": _npc_display_name(npc_id),
            "detail": "%s %s%d" % [_relationship_name(axis), "+" if actual_delta > 0 else "", actual_delta],
            "axis": axis,
            "delta": actual_delta,
        })

func add_item(item_id: String) -> void:
    if not inventory.has(item_id):
        inventory.append(item_id)
        add_log("아이템 획득: " + _item_display_name(item_id))
        emit_signal("state_changed", "inventory", inventory)
        request_feedback({
            "type": "reward",
            "tone": "success",
            "title": "아이템 획득",
            "detail": _item_display_name(item_id),
        })

func equip_item(item: Dictionary) -> void:
    var item_id := String(item.get("id", ""))
    var slot := String(item.get("slot", "misc"))
    if item_id.is_empty() or not inventory.has(item_id):
        return
    var previous_item_id := String(equipped.get(slot, ""))
    if previous_item_id == item_id:
        return
    if not previous_item_id.is_empty():
        _remove_item_effects(slot)
    equipped[slot] = item_id
    equipped_applied_effects[slot] = _apply_item_effects_with_tracking(item.get("effects", {}))
    add_log("장착: " + String(item.get("name_ko", item_id)))
    emit_signal("state_changed", "equipped/" + slot, item_id)

func unequip_slot(slot: String) -> void:
    var item_id := String(equipped.get(slot, ""))
    if item_id.is_empty():
        return
    _remove_item_effects(slot)
    equipped.erase(slot)
    add_log("장착 해제: " + _item_display_name(item_id))
    emit_signal("state_changed", "equipped/" + slot, "")

func equipped_effect_value(effect_id: String) -> int:
    var total := 0
    for slot in equipped.keys():
        var item_id := String(equipped.get(slot, ""))
        if item_id.is_empty():
            continue
        var item := DataManager.find_by_id("items", "items", item_id)
        var effects: Dictionary = item.get("effects", {})
        if effects.has(effect_id):
            total += int(effects.get(effect_id, 0))
    return total

func _apply_item_effects_with_tracking(effects: Dictionary) -> Dictionary:
    var before := {}
    for key in effects.keys():
        var value = effects[key]
        if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
            continue
        var current = get_value(String(key))
        before[String(key)] = int(current) if current != null else 0
    apply_effects(effects)
    var applied := {}
    for key in before.keys():
        var current = get_value(String(key))
        var actual_delta := (int(current) if current != null else 0) - int(before[key])
        if actual_delta != 0:
            applied[String(key)] = actual_delta
    return applied

func _remove_item_effects(slot: String) -> void:
    var effects: Dictionary = equipped_applied_effects.get(slot, {})
    var reversed_effects := {}
    for key in effects.keys():
        var value = effects[key]
        if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
            reversed_effects[key] = -int(value)
    apply_effects(reversed_effects)
    equipped_applied_effects.erase(slot)

func create_spouse_from_candidate(candidate: Dictionary) -> void:
    _reset_current_marriage_lifecycle()
    spouse = {
        "candidate_id": candidate.get("id", ""),
        "character_id": candidate.get("character_id", ""),
        "rank": candidate.get("rank", "unknown"),
        "health": 78,
        "affection": 35,
        "direct_suspicion": 5,
        "threat_alert": 5,
        "public_harmony": 25,
    }
    set_flag("married", true)
    set_flag("entered_nobility", true)
    set_flag("access_to_household", true)
    set_flag("available_event", true)
    apply_effects({
        "status": int(candidate.get("status_gain", 0)),
        "funds_power": int(candidate.get("wealth_gain", 0))
    })
    add_log("결혼 성립: " + _candidate_display_name(String(candidate.get("id", "unknown"))))
    evaluate_voice_stage()
    emit_signal("state_changed", "spouse", spouse)

func select_wedding_result_event(option: Dictionary, candidate: Dictionary) -> Dictionary:
    var events: Array = DataManager.get_table("marriage_config").get("wedding_result_events", [])
    var best_event: Dictionary = {}
    var best_score := -999999
    var traits: Array = candidate.get("special_traits", [])
    for event in events:
        if typeof(event) != TYPE_DICTIONARY:
            continue
        var event_dict: Dictionary = event
        if not _wedding_event_matches(event_dict, option, candidate):
            continue
        var score := int(event_dict.get("priority", 0)) + (_matching_trait_count(traits, event_dict.get("trigger_traits_any", [])) * 5)
        if score > best_score:
            best_score = score
            best_event = event_dict
    return best_event.duplicate(true)

func apply_wedding_result_event(option: Dictionary, candidate: Dictionary) -> Dictionary:
    var event := select_wedding_result_event(option, candidate)
    if event.is_empty():
        return {}
    flags["last_wedding_event_id"] = String(event.get("id", ""))
    flags["last_wedding_event_title"] = String(event.get("name_ko", event.get("id", "")))
    flags["last_wedding_event_text"] = String(event.get("summary_ko", ""))
    player["flags"] = flags
    apply_effects(event.get("effects", {}))
    add_log("결혼식 결과: %s - %s" % [flags["last_wedding_event_title"], flags["last_wedding_event_text"]])
    emit_signal("state_changed", "flags/last_wedding_event", flags["last_wedding_event_id"])
    return event

func _wedding_event_matches(event: Dictionary, option: Dictionary, candidate: Dictionary) -> bool:
    if not _matches_string_filter(String(option.get("id", "")), event.get("option_ids", [])):
        return false
    if not _matches_string_filter(String(candidate.get("rank", "")), event.get("rank_ids", [])):
        return false
    var required_traits: Array = event.get("trigger_traits_any", [])
    if not required_traits.is_empty() and _matching_trait_count(candidate.get("special_traits", []), required_traits) <= 0:
        return false
    return true

func _matches_string_filter(value: String, filter_values: Array) -> bool:
    if filter_values.is_empty():
        return true
    for filter_value in filter_values:
        if String(filter_value) == value:
            return true
    return false

func _matching_trait_count(traits: Array, required_traits: Array) -> int:
    var matched := 0
    for required in required_traits:
        if traits.has(String(required)):
            matched += 1
    return matched

func select_removal_counter_event(method: Dictionary) -> Dictionary:
    var events: Array = DataManager.get_table("removal_methods").get("counter_events", [])
    var candidate := current_spouse_candidate()
    var best_event: Dictionary = {}
    var best_score := -999999
    for event in events:
        if typeof(event) != TYPE_DICTIONARY:
            continue
        var event_dict: Dictionary = event
        if not _removal_counter_event_matches(event_dict, method, candidate):
            continue
        var score := int(event_dict.get("priority", 0))
        score += _matching_string_count(method.get("countered_by", []), event_dict.get("counter_ids", [])) * 5
        score += _matching_trait_count(candidate.get("special_traits", []), event_dict.get("trigger", {}).get("candidate_traits_any", [])) * 4
        if score > best_score:
            best_score = score
            best_event = event_dict
    return best_event.duplicate(true)

func apply_removal_counter_event(event: Dictionary) -> void:
    if event.is_empty():
        flags.erase("last_removal_counter_id")
        flags.erase("last_removal_counter_title")
        flags.erase("last_removal_counter_text")
        player["flags"] = flags
        return
    flags["last_removal_counter_id"] = String(event.get("id", ""))
    flags["last_removal_counter_title"] = String(event.get("name_ko", event.get("id", "")))
    flags["last_removal_counter_text"] = String(event.get("summary_ko", ""))
    player["flags"] = flags
    apply_effects(event.get("effects", {}))
    add_log("처리 대응 이벤트: %s - %s" % [flags["last_removal_counter_title"], flags["last_removal_counter_text"]])
    emit_signal("state_changed", "flags/last_removal_counter", flags["last_removal_counter_id"])

func apply_removal_counter_case_effects(event: Dictionary) -> void:
    if event.is_empty() or active_case.is_empty():
        return
    active_case["counter_event_id"] = String(event.get("id", ""))
    active_case["counter_event_name"] = String(event.get("name_ko", event.get("id", "")))
    active_case["counter_event_text"] = String(event.get("summary_ko", ""))
    apply_effects(event.get("case_effects", {}))
    emit_signal("state_changed", "case/counter_event", active_case)

func current_spouse_candidate() -> Dictionary:
    if spouse.is_empty():
        return {}
    return DataManager.find_by_id("candidate_profiles", "candidate_profiles", String(spouse.get("candidate_id", "")))

func _removal_counter_event_matches(event: Dictionary, method: Dictionary, candidate: Dictionary) -> bool:
    var method_ids: Array = event.get("method_ids", [])
    if not _matches_string_filter(String(method.get("id", "")), method_ids):
        return false
    if _matching_string_count(method.get("countered_by", []), event.get("counter_ids", [])) <= 0:
        return false
    var trigger: Dictionary = event.get("trigger", {})
    if not _matches_string_filter(String(candidate.get("rank", "")), trigger.get("rank_ids", [])):
        return false
    var traits: Array = trigger.get("candidate_traits_any", [])
    if not traits.is_empty() and _matching_trait_count(candidate.get("special_traits", []), traits) <= 0:
        return false
    if not _matches_value_min(trigger.get("spouse_min", {})):
        return false
    if not _matches_value_max(trigger.get("spouse_max", {})):
        return false
    if not _matches_value_min(trigger.get("player_min", {})):
        return false
    if not _matches_value_max(trigger.get("player_max", {})):
        return false
    return true

func _matching_string_count(values: Array, required_values: Array) -> int:
    var matched := 0
    for required in required_values:
        if values.has(String(required)):
            matched += 1
    return matched

func _matches_value_min(values: Dictionary) -> bool:
    for key in values.keys():
        var current = get_value(String(key))
        if current == null or int(current) < int(values[key]):
            return false
    return true

func _matches_value_max(values: Dictionary) -> bool:
    for key in values.keys():
        var current = get_value(String(key))
        if current == null or int(current) > int(values[key]):
            return false
    return true

func create_case_from_removal(method: Dictionary, success: bool) -> void:
    _reset_current_case_lifecycle()
    var risk_profile: Dictionary = method.get("risk_profile", {})
    var result := removal_result(method, success)
    var case_initial: Dictionary = result.get("case_initial", {})
    var result_type := String(result.get("type", "fatal_case" if success else "failed_removal"))
    active_case = {
        "method_id": method.get("id", ""),
        "success": success,
        "case_type": result_type,
        "result_name": String(result.get("name_ko", "실패 후폭풍" if not success else "사건")),
        "result_text": String(result.get("summary_ko", "처리 결과로 후폭풍 파일이 열렸습니다.")),
        "investigation_progress": int(case_initial.get("investigation_progress", 10 if success else 20)),
        "rumor_spread": int(case_initial.get("rumor_spread", 8 if success else 18)),
        "evidence_risk": int(case_initial.get("evidence_risk", risk_profile.get("evidence_risk", 10))),
        "alibi_strength": 0,
        "public_grief": 0,
    }
    for key in risk_profile.keys():
        if String(key) != "evidence_risk":
            change_stat(String(key), int(risk_profile[key]))
    apply_effects(result.get("effects", {}))
    flags["last_removal_result_type"] = result_type
    flags["last_removal_result_title"] = String(result.get("name_ko", active_case.get("result_name", "")))
    flags["last_removal_result_text"] = String(result.get("summary_ko", active_case.get("result_text", "")))
    player["flags"] = flags
    if success and bool(result.get("widow", true)):
        set_flag("widowed_once", true)
        set_flag("widowed", true)
        _apply_repeated_widow_penalty()
    elif success:
        set_flag("marriage_ended_nonlethal", true)
    add_log("처리 결과: %s - %s" % [flags["last_removal_result_title"], flags["last_removal_result_text"]])
    add_log("후폭풍 파일 생성: " + String(method.get("name_ko", method.get("id", "unknown"))))
    evaluate_voice_stage()
    emit_signal("state_changed", "case", active_case)

func _reset_current_marriage_lifecycle() -> void:
    for flag_id in ["widowed", "marriage_ended_nonlethal", "case_resolved", "last_case_resolution", "accusation_event_seen", "accusation_event_text", "spouse_dashboard_seen"]:
        flags.erase(flag_id)
    player["flags"] = flags

func _reset_current_case_lifecycle() -> void:
    for flag_id in ["widowed", "marriage_ended_nonlethal", "case_resolved", "last_case_resolution", "accusation_event_seen", "accusation_event_text"]:
        flags.erase(flag_id)
    player["flags"] = flags

func removal_result(method: Dictionary, success: bool) -> Dictionary:
    if success:
        var result: Dictionary = method.get("success_result", {})
        if result.is_empty():
            return {
                "type": "fatal_case",
                "name_ko": "사망 사건",
                "summary_ko": "배우자가 제거되고 사건 파일이 열린다.",
                "spouse_removed": true,
                "widow": true,
                "unlock_next_rank": true,
            }
        return result.duplicate(true)
    return {
        "type": "failed_removal",
        "name_ko": "실패 후폭풍",
        "summary_ko": "처리가 실패해 배우자가 살아 있고 의심과 경계가 커졌다.",
        "spouse_removed": false,
        "widow": false,
        "unlock_next_rank": false,
    }

func _apply_repeated_widow_penalty() -> void:
    var counters: Dictionary = player.get("counters", {})
    var widow_count := int(counters.get("widow_count", 0)) + 1
    counters["widow_count"] = widow_count
    player["counters"] = counters
    if widow_count <= 1:
        return
    var suspicion_penalty := mini(30, 6 * (widow_count - 1))
    var notoriety_penalty := mini(20, 4 * (widow_count - 1))
    apply_effects({
        "social_suspicion": suspicion_penalty,
        "notoriety": notoriety_penalty,
        "origin_rumor": widow_count - 1,
    })
    add_log("반복 미망인 이미지 페널티: %d번째 사건" % widow_count)

func on_week_elapsed() -> void:
    _process_age_pressure()
    if bool(flags.get("game_over", false)):
        return
    apply_persona_maintenance()
    evaluate_voice_stage()
    if not active_case.is_empty():
        var coverup := DataManager.get_table("coverup_actions")
        var decay: Dictionary = coverup.get("weekly_decay_after_event", {})
        for key in decay.keys():
            change_stat(String(key), int(decay[key]))
        var danger_peak := maxi(maxi(int(active_case.get("investigation_progress", 0)), int(active_case.get("rumor_spread", 0))), maxi(int(active_case.get("evidence_risk", 0)), get_risk("social_suspicion")))
        if danger_peak >= 40 and not bool(flags.get("first_danger_warning_seen", false)):
            set_flag("first_danger_warning_seen", true)
            add_log("튜토리얼 안내: 사건 위험이 상승했습니다. 은폐 행동으로 조사, 소문, 증거를 낮추십시오.")
        evaluate_active_case()
    if not bool(flags.get("game_over", false)):
        apply_rank_pressure_event()

func marriage_market_age_penalty() -> int:
    var soft_limit := int(player.get("soft_limit_age_years", 30))
    if age_years < soft_limit:
        return 0
    return mini(24, (age_years - soft_limit + 1) * 3)

func candidate_preparation_bonus(candidate: Dictionary) -> int:
    var preferred: Dictionary = candidate.get("preferred_stats", {})
    if preferred.is_empty():
        return -marriage_market_age_penalty()
    var match_config: Dictionary = DataManager.get_table("match_config")
    var rules: Dictionary = MATCH_OUTCOME_CALCULATOR.rules_for_candidate(candidate, match_config)
    var preferred_entries: Array[Dictionary] = []
    for key in preferred.keys():
        var entry_weight := float(preferred[key])
        if entry_weight > 0.0:
            preferred_entries.append({"id": String(key), "weight": entry_weight})
    preferred_entries.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
        var left_weight := float(left.get("weight", 0.0))
        var right_weight := float(right.get("weight", 0.0))
        if not is_equal_approx(left_weight, right_weight):
            return left_weight > right_weight
        return String(left.get("id", "")) < String(right.get("id", ""))
    )
    var top_count := int(rules.get("preparation_top_stats", 0))
    if top_count > 0 and preferred_entries.size() > top_count:
        preferred_entries.resize(top_count)
    var weighted_total := 0.0
    var weight_sum := 0.0
    for entry in preferred_entries:
        var stat_id := String(entry.get("id", ""))
        var weight := float(entry.get("weight", 0.0))
        weighted_total += float(get_stat(stat_id)) * weight
        weight_sum += weight
    if weight_sum <= 0.0:
        return -marriage_market_age_penalty()
    var preparation_scale := float(rules.get("preparation_scale", 0.45))
    return int((weighted_total / weight_sum) * preparation_scale) - marriage_market_age_penalty()

func apply_persona_maintenance() -> void:
    var persona_id := String(player.get("current_persona", ""))
    var persona := DataManager.find_by_id("personas", "personas", persona_id)
    if persona.is_empty():
        return
    var maintenance: Dictionary = persona.get("maintenance", {})
    var fatigue_cost := maxi(0, int(maintenance.get("weekly_fatigue", 0)))
    var cash_cost := maxi(0, int(maintenance.get("weekly_funds", 0)))
    if fatigue_cost > 0:
        change_stat("fatigue", fatigue_cost)
    if cash_cost <= 0:
        return
    var available_cash := get_stat("cash")
    var paid := mini(available_cash, cash_cost)
    if paid > 0:
        change_stat("cash", -paid)
    var shortfall := cash_cost - paid
    if shortfall <= 0:
        add_log("페르소나 유지: %s / 자금 %d / 피로 +%d" % [persona.get("name_ko", persona_id), cash_cost, fatigue_cost])
        return
    change_stat("stress", 2 + shortfall)
    change_stat("origin_rumor", 1)
    add_log("페르소나 유지비 부족: %s / 부족 자금 %d" % [persona.get("name_ko", persona_id), shortfall])

func evaluate_voice_stage() -> bool:
    var stages: Array = DataManager.get_table("dialogue_stages").get("stages", [])
    if stages.is_empty():
        return false
    var current_id := String(player.get("current_voice_stage", "voice_0_street_beast"))
    var current_order := -1
    for stage in stages:
        if typeof(stage) == TYPE_DICTIONARY and String(stage.get("id", "")) == current_id:
            current_order = int(stage.get("order", 0))
            break
    var next_stage: Dictionary = {}
    var next_order := current_order
    for stage in stages:
        if typeof(stage) != TYPE_DICTIONARY:
            continue
        var stage_dict: Dictionary = stage
        var stage_order := int(stage_dict.get("order", 0))
        if stage_order <= next_order:
            continue
        if not _voice_stage_requirements_met(stage_dict):
            continue
        if not _voice_stage_story_met(stage_order):
            continue
        next_stage = stage_dict
        next_order = stage_order
    if next_stage.is_empty():
        return false
    player["current_voice_stage"] = String(next_stage.get("id", current_id))
    flags["last_voice_stage_title"] = String(next_stage.get("name_ko", next_stage.get("id", "")))
    flags["last_voice_stage_week"] = week
    player["flags"] = flags
    add_log("대사 단계 성장: " + String(flags["last_voice_stage_title"]))
    emit_signal("state_changed", "player/current_voice_stage", player["current_voice_stage"])
    return true

func _voice_stage_requirements_met(stage: Dictionary) -> bool:
    var conditions: Dictionary = stage.get("typical_conditions", {})
    var recommended: Dictionary = conditions.get("recommended", {})
    for raw_key in recommended.keys():
        var key := String(raw_key)
        if not key.begins_with("min_"):
            continue
        var requested_stat := key.trim_prefix("min_")
        var stat_id := String(PROGRESSION_STAT_ALIASES.get(requested_stat, requested_stat))
        if get_stat(stat_id) < int(recommended[raw_key]):
            return false
    return true

func _voice_stage_story_met(stage_order: int) -> bool:
    if stage_order <= 1:
        return true
    if stage_order == 2:
        return bool(flags.get("entered_nobility", false)) or bool(flags.get("married", false))
    if stage_order == 3:
        return bool(flags.get("widowed_once", false))
    var rank_order := int(RANK_ORDER.get(current_social_rank(), 0))
    if stage_order == 4:
        return rank_order >= int(RANK_ORDER["count"])
    if stage_order == 5:
        return rank_order >= int(RANK_ORDER["duke"])
    return false

func current_social_rank() -> String:
    if not spouse.is_empty():
        return String(spouse.get("rank", "commoner"))
    return "commoner"

func _process_age_pressure() -> void:
    var soft_limit := int(player.get("soft_limit_age_years", 30))
    var hard_limit := int(player.get("hard_limit_age_years", 35))
    if age_years >= soft_limit:
        var warning_key := "age_pressure_seen_%d" % age_years
        if not bool(flags.get(warning_key, false)):
            flags[warning_key] = true
            player["flags"] = flags
            add_log("혼인 시장 연령 압박: %d세 / 맞선 준비 보너스 -%d" % [age_years, marriage_market_age_penalty()])
    if age_years < hard_limit or bool(flags.get("game_over", false)):
        return
    flags["game_over_reason"] = "%d세에 도달해 혼인 시장에서 퇴장했습니다." % hard_limit
    set_flag("game_over", true)
    add_log("연령 한계 도달: 권력 상승 여정이 종료되었습니다.")
    emit_signal("state_changed", "game/age_limit", age_years)

func select_rank_pressure_event() -> Dictionary:
    if spouse.is_empty() or not bool(flags.get("married", false)):
        return {}
    var config: Dictionary = DataManager.get_table("rank_events")
    var check: Dictionary = config.get("weekly_check", {})
    var start_week := int(check.get("start_week", 12))
    var interval_weeks := maxi(1, int(check.get("interval_weeks", 4)))
    if week < start_week or ((week - start_week) % interval_weeks) != 0:
        return {}
    var last_week := int(flags.get("last_rank_event_week", -999))
    var candidate := current_spouse_candidate()
    if candidate.is_empty():
        return {}
    var best_event: Dictionary = {}
    var best_score := -999999
    for event in config.get("events", []):
        if typeof(event) != TYPE_DICTIONARY:
            continue
        var event_dict: Dictionary = event
        if not _rank_event_matches(event_dict, candidate, last_week):
            continue
        var traits: Array = candidate.get("special_traits", [])
        var score := int(event_dict.get("priority", 0)) + (_matching_trait_count(traits, event_dict.get("trigger_traits_any", [])) * 5)
        if score > best_score:
            best_score = score
            best_event = event_dict
    return best_event.duplicate(true)

func apply_rank_pressure_event() -> Dictionary:
    var event := select_rank_pressure_event()
    if event.is_empty():
        return {}
    var event_id := String(event.get("id", ""))
    flags["last_rank_event_id"] = event_id
    flags["last_rank_event_title"] = String(event.get("name_ko", event_id))
    flags["last_rank_event_text"] = String(event.get("summary_ko", ""))
    flags["last_rank_event_week"] = week
    flags["last_rank_event_effects"] = event.get("effects", {}).duplicate(true)
    flags["rank_event_seen_" + event_id] = true
    player["flags"] = flags
    apply_effects(event.get("effects", {}))
    _apply_rank_event_unlocks(event)
    add_log("작위 압박: %s - %s" % [flags["last_rank_event_title"], flags["last_rank_event_text"]])
    emit_signal("state_changed", "flags/last_rank_event", event_id)
    return event

func _rank_event_matches(event: Dictionary, candidate: Dictionary, last_week: int) -> bool:
    var event_id := String(event.get("id", ""))
    if event_id == "" or bool(flags.get("rank_event_seen_" + event_id, false)):
        return false
    if week < int(event.get("min_week", 1)):
        return false
    if week - last_week < int(event.get("cooldown_weeks", 4)):
        return false
    if not _matches_string_filter(String(candidate.get("rank", "")), event.get("rank_ids", [])):
        return false
    if not _matches_value_min(event.get("player_min", {})):
        return false
    if not _matches_value_max(event.get("player_max", {})):
        return false
    if not _matches_value_min(event.get("spouse_min", {})):
        return false
    if not _matches_value_max(event.get("spouse_max", {})):
        return false
    return true

func _apply_rank_event_unlocks(event: Dictionary) -> void:
    for unlock in event.get("unlock_candidates", []):
        if typeof(unlock) != TYPE_DICTIONARY:
            continue
        var unlock_dict: Dictionary = unlock
        var rank_id := String(unlock_dict.get("rank", ""))
        if rank_id == "":
            continue
        unlock_or_improve_candidates_for_rank(rank_id, int(unlock_dict.get("quality", 30)), int(unlock_dict.get("count", 1)))

func evaluate_active_case() -> void:
    if active_case.is_empty() or bool(flags.get("game_over", false)):
        return
    var investigation := int(active_case.get("investigation_progress", 0))
    var rumor := int(active_case.get("rumor_spread", 0))
    var evidence := int(active_case.get("evidence_risk", 0))
    var alibi := int(active_case.get("alibi_strength", 0))
    var grief := int(active_case.get("public_grief", 0))
    var social_suspicion := get_risk("social_suspicion")
    if investigation >= 100 or social_suspicion >= 100 or evidence >= 100:
        flags["game_over_reason"] = _game_over_reason(investigation, evidence, social_suspicion)
        set_flag("game_over", true)
        add_log("치명적 의심에 도달했습니다. 게임오버 상태입니다.")
        emit_signal("state_changed", "case/game_over", active_case)
        return
    if not bool(flags.get("accusation_event_seen", false)) and (investigation >= 75 or evidence >= 70 or social_suspicion >= 80):
        flags["accusation_event_text"] = _accusation_event_text(investigation, evidence, social_suspicion)
        set_flag("accusation_event_seen", true)
        add_log("범인 지목 이벤트: " + String(flags.get("accusation_event_text", "")))
        emit_signal("state_changed", "case/accusation", active_case)
    var danger := maxi(maxi(investigation, rumor), maxi(evidence, social_suspicion))
    var narrative := maxi(alibi, grief)
    if danger <= 35 and narrative >= 25:
        flags["last_case_resolution"] = "위험 최대치 %d / 공개 서사 %d" % [danger, narrative]
        active_case.clear()
        set_flag("case_resolved", true)
        add_log("사건 종결: 의심이 안정권으로 내려갔고 공개 서사가 정착했습니다.")
        emit_signal("state_changed", "case/resolved", true)

func _game_over_reason(investigation: int, evidence: int, social_suspicion: int) -> String:
    if investigation >= 100:
        return "조사 진행도가 100에 도달했습니다."
    if evidence >= 100:
        return "증거 위험도가 100에 도달했습니다."
    if social_suspicion >= 100:
        return "사회적 의심이 100에 도달했습니다."
    return "치명적 위험에 도달했습니다."

func _accusation_event_text(investigation: int, evidence: int, social_suspicion: int) -> String:
    if investigation >= 75:
        return "가문 대리인이 사건 흐름을 다시 묻기 시작했습니다. 조사 진행도를 낮추십시오."
    if evidence >= 70:
        return "불안정한 증거가 주인공 쪽으로 모이고 있습니다. 증거 위험도를 낮추십시오."
    if social_suspicion >= 80:
        return "사교계가 사건의 책임을 주인공에게 돌리기 시작했습니다. 사회적 의심을 낮추십시오."
    return "사건 책임이 주인공에게 향하고 있습니다."

func _flag_name(flag_id: String) -> String:
    return FLAG_NAMES.get(flag_id, flag_id)

func _value_name(value_id: String) -> String:
    return VALUE_NAMES.get(value_id, value_id)

func _relationship_name(axis_id: String) -> String:
    return RELATIONSHIP_NAMES.get(axis_id, axis_id)

func _npc_display_name(npc_id: String) -> String:
    var npc := DataManager.find_by_id("npcs", "characters", npc_id)
    return String(npc.get("name_ko", npc_id))

func _item_display_name(item_id: String) -> String:
    var item := DataManager.find_by_id("items", "items", item_id)
    return String(item.get("name_ko", item_id))

func _candidate_market_accessible(candidate: Dictionary) -> bool:
    var rank_id := String(candidate.get("rank", ""))
    if rank_id == "royal":
        return false
    var rank := DataManager.find_by_id("nobility_ranks", "ranks", rank_id)
    var requirements: Dictionary = rank.get("access_requirement", {})
    for key in requirements.keys():
        var current = get_value(String(key))
        if current == null or int(current) < int(requirements[key]):
            return false
    return true

func _candidate_display_name(candidate_id: String) -> String:
    var candidate := DataManager.find_by_id("candidate_profiles", "candidate_profiles", candidate_id)
    if candidate.is_empty():
        return candidate_id
    var npc := DataManager.find_by_id("npcs", "characters", String(candidate.get("character_id", "")))
    if npc.is_empty():
        return candidate_id
    return String(npc.get("name_ko", candidate_id))
