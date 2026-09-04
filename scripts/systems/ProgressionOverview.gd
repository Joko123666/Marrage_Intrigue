extends RefCounted

func snapshot() -> Dictionary:
    var steps: Array = DataManager.get_table("tutorial_flow").get("steps", [])
    var completed := completed_step_count()
    var current_step: Dictionary = steps[completed] if completed < steps.size() else {}
    var result := {
        "completed_steps": completed,
        "total_steps": steps.size(),
        "step_id": String(current_step.get("id", "complete")),
        "objective": String(current_step.get("objective_ko", "핵심 루프를 완료했습니다.")),
        "hint": _step_hint(String(current_step.get("id", "complete"))),
        "action_id": _step_action_id(String(current_step.get("id", "complete"))),
        "action_label": _step_action_label(String(current_step.get("id", "complete"))),
    }
    if bool(GameState.flags.get("case_resolved", false)):
        return _override(result, "사건 종결 결과를 확인합니다.", "첫 핵심 루프가 완료되었습니다. 결과를 확인하고 다음 후보 루프로 이동할 수 있습니다.", "complete", "완료 결과 보기")
    if not GameState.active_case.is_empty():
        return _override(result, "사건 위험을 낮추고 사건 파일을 종결합니다.", "매주 조사와 소문이 커집니다. 공개 애도, 알리바이, 공식 소견으로 위험을 낮추십시오.", "coverup", "은폐로 이동")
    if bool(GameState.flags.get("match_success_pending", false)):
        return _override(result, "결혼식 옵션을 선택해 혼인을 성립시킵니다.", "맞선에 성공했습니다. 비용과 결과 효과를 비교하고 결혼식을 진행하십시오.", "wedding", "결혼식으로 이동")
    if not GameState.current_match.is_empty():
        return _override(result, "맞선의 6개 관계 축을 관리해 혼인 의사를 얻습니다.", "흥미만 올리면 안심과 체면이 무너질 수 있으니 6개 축의 균형을 보십시오.", "match", "맞선 계속")
    return result

func completed_step_count() -> int:
    var steps: Array = DataManager.get_table("tutorial_flow").get("steps", [])
    var completed := 1
    if not GameState.inventory.is_empty() or not GameState.equipped.is_empty():
        completed = maxi(completed, 2)
    var knight_known := GameState.known_candidates.has("candidate_knight_tutorial_adrien")
    if knight_known:
        completed = maxi(completed, 3)
    if knight_known and _candidate_minimums_met():
        completed = maxi(completed, 4)
    if knight_known and GameState.week >= 10:
        completed = maxi(completed, 5)
    if not GameState.current_match.is_empty() or bool(GameState.flags.get("match_success_pending", false)) or bool(GameState.flags.get("married", false)) or not GameState.active_case.is_empty():
        completed = maxi(completed, 6)
    if bool(GameState.flags.get("match_success_pending", false)) or bool(GameState.flags.get("married", false)) or not GameState.active_case.is_empty():
        completed = maxi(completed, 7)
    if bool(GameState.flags.get("spouse_dashboard_seen", false)) or not GameState.active_case.is_empty():
        completed = maxi(completed, 8)
    if not GameState.active_case.is_empty() or bool(GameState.flags.get("widowed_once", false)):
        completed = maxi(completed, 9)
    if bool(GameState.flags.get("case_resolved", false)):
        completed = steps.size()
    return mini(completed, steps.size())

func _candidate_minimums_met() -> bool:
    var candidate := DataManager.find_by_id("candidate_profiles", "candidate_profiles", "candidate_knight_tutorial_adrien")
    for key in Dictionary(candidate.get("minimums", {})).keys():
        if GameState.get_stat(String(key)) < int(Dictionary(candidate.get("minimums", {})).get(key, 0)):
            return false
    return true

func _step_action_id(step_id: String) -> String:
    match step_id:
        "meet_tailor": return "shop"
        "gather_knight_rumor": return "rumors"
        "train_for_meeting", "chance_meeting": return "free"
        "match_knight": return "candidates"
        "wedding_knight": return "wedding"
        "spouse_dashboard_intro": return "spouse"
        "first_removal_or_hold": return "removal"
        "complete": return "complete"
        _: return "free"

func _step_action_label(step_id: String) -> String:
    match step_id:
        "meet_tailor": return "상점 방문"
        "gather_knight_rumor": return "후보 정보 찾기"
        "train_for_meeting": return "능력 훈련"
        "chance_meeting": return "10주차까지 준비"
        "match_knight": return "후보 확인"
        "wedding_knight": return "결혼식으로 이동"
        "spouse_dashboard_intro": return "배우자 확인"
        "first_removal_or_hold": return "처리 방식 비교"
        "complete": return "완료 결과 보기"
        _: return "자유행동으로 이동"

func _step_hint(step_id: String) -> String:
    match step_id:
        "meet_tailor": return "상점에서 아이템을 구입하고 장착해 스탯과 행동 보정을 확인하십시오."
        "gather_knight_rumor": return "소문 작전의 탐문이나 정보상 거래로 기사 후보 정보를 확보하십시오."
        "train_for_meeting": return "외모와 예법 최소 조건을 맞추고 자금과 피로를 관리하십시오."
        "chance_meeting": return "후보와 만날 10주차까지 부족한 능력과 페르소나를 정비하십시오."
        "match_knight": return "후보 화면에서 아드리엔 경과의 맞선을 시작하십시오."
        "wedding_knight": return "비용과 효과를 비교해 결혼식 옵션을 선택하십시오."
        "spouse_dashboard_intro": return "배우자 대시보드에서 상태와 주변 인물, 가문 압박을 확인하십시오."
        "first_removal_or_hold": return "배우자를 유지할지, 제거하거나 정치적으로 처리할지 비교하십시오."
        "complete": return "완료 화면에서 결과를 확인하십시오."
        _: return "자유행동으로 다음 목표를 준비하십시오."

func _override(base: Dictionary, objective: String, hint: String, action_id: String, action_label: String) -> Dictionary:
    var result := base.duplicate(true)
    result["objective"] = objective
    result["hint"] = hint
    result["action_id"] = action_id
    result["action_label"] = action_label
    return result
