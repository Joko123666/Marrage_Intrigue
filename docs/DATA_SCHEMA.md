# 데이터 스키마 설명 v0.1

## 공통 규칙

- 모든 id는 snake_case 문자열.
- 숫자 스탯은 기본 0~100.
- 효과는 additive delta로 처리하고, 적용 후 0~100 범위로 clamp한다.
- `weeks`는 행동 소요 주 수.
- `requirements`는 기본적으로 행동/선택지 활성 조건. 단, 맞선 선택지에서 플레이어 숫자 스탯을 가리키는 값은 버튼 잠금이 아니라 효과량을 바꾸는 소프트 숙련 기준이다.
- 맞선 선택지를 반드시 잠가야 하는 플래그·자원·서사 조건은 `hard_requirements`에 둔다. `requirements` 안에서도 플레이어 스탯이 아닌 조건은 하드 조건으로 처리한다.
- `effects`는 실행 후 상태 변화.
- `summary_ko`는 UI 툴팁에 사용할 수 있다.

## 주요 플레이어 스탯

| id | 의미 |
| --- | --- |
| beauty | 외모 |
| culture | 교양 |
| grace | 기품 |
| etiquette | 예법 |
| wildness | 야성 |
| mask | 가면술 |
| impulse_control | 충동제어 |
| cash | 실제 운용 자금 |
| funds_power | 재력/배경 자금력 |
| information | 정보력 |
| social | 사교력 |
| influence | 영향력 |
| status | 신분/작위 단계 |
| fatigue | 피로 |
| stress | 스트레스 |
| ambition | 야망 |

## 의심/위험 축

| id | 의미 |
| --- | --- |
| social_suspicion | 사교계가 주인공을 수상하게 보는 장기 의심 |
| direct_suspicion | 배우자가 주인공을 직접 의심하는 정도 |
| threat_alert | 배우자가 신변 위협을 느껴 방비를 강화하는 정도 |
| evidence_risk | 사건 단위 증거 위험도 |
| origin_rumor | 출신 소문 위험 |
| underworld_trace | 뒷세계 거래 흔적 |

## 맞선 레이더 축

| id | 의미 |
| --- | --- |
| favor | 호감 |
| interest | 흥미 |
| trust | 신뢰 |
| comfort | 안심 |
| face | 체면 만족 |
| political_value | 정략 가치 |

## free_actions.json

```json
{
  "id": "train_beauty",
  "name_ko": "외모 관리",
  "category": "self_improvement",
  "weeks": 2,
  "cost": {"cash": 3, "fatigue": 4},
  "effects": {"beauty": 3, "mask": 1, "cash": -3, "fatigue": 4},
  "summary_ko": "...",
  "result_ko": "거울 앞에서 자세와 표정을 거듭 다듬었습니다...",
  "result_backdrop": "res://assets/art/actions/action_mirror_chamber.png",
  "tags": ["beauty", "mask"]
}
```

`result_ko`는 행동 완료 시 육성·생활 결과 장면에 출력하는 서술 문장이다. 생략하면 `summary_ko`, 그것도 없으면 공통 완료 문장으로 폴백한다. `result_backdrop`은 같은 장면의 배경 텍스처 경로이며 현재 모든 자유행동이 거울방·서재·시장 골목 3종 중 하나를 참조한다. 결과 장면의 실제 변화 칩은 데이터의 원본 `effects`가 아니라 능력 영향과 장비 보정을 모두 적용한 최종 효과를 사용한다.

## npc 구조

```json
{
  "id": "npc_knight_adrien",
  "portrait": "res://assets/art/characters/npc_knight_adrien.png",
  "match_portraits": {
    "neutral": "res://assets/art/characters/npc_knight_adrien.png",
    "favorable": "res://assets/art/characters/match/npc_knight_adrien_match_favorable.png",
    "wary": "res://assets/art/characters/match/npc_knight_adrien_match_wary.png"
  },
  "spouse_portraits": {
    "neutral": "res://assets/art/characters/npc_knight_adrien.png",
    "affectionate": "res://assets/art/characters/spouse/npc_knight_adrien_spouse_affectionate.png",
    "suspicious": "res://assets/art/characters/spouse/npc_knight_adrien_spouse_suspicious.png",
    "weakened": "res://assets/art/characters/spouse/npc_knight_adrien_spouse_weakened.png"
  },
  "name_ko": "아드리엔 경",
  "role": "candidate_knight_tutorial",
  "faction": "minor_knightly_house",
  "relationship": {"favor": 5, "trust": 0},
  "candidate_profile_id": "candidate_knight_tutorial_adrien"
}
```

`match_portraits`는 맞선 표정 변형이 준비된 후보 NPC에만 필요한 선택 필드다. 맞선 시작 전과 직전 변화량이 0이면 `neutral`, 긍정 변화면 `favorable`, `backfire` 또는 관계 축 합계가 음수면 `wary`를 선택한다. 키나 필드가 없으면 `neutral`, 최종적으로 `portrait` 순서로 폴백한다.
`spouse_portraits`는 결혼 후보 NPC에만 필요한 선택 필드다. 배우자 대시보드에서 `health`, `affection`, `public_harmony`, `direct_suspicion`, `threat_alert` 값에 따라 `neutral`, `affectionate`, `suspicious`, `weakened` 중 하나를 선택한다.
`portrait`는 실제 후보 초상화 또는 임시 실루엣 경로를 가리킬 수 있다. 현재 왕족을 제외한 기사/남작/자작/백작/후작/공작 후보는 실제 초상화를 사용한다.

## candidate_profiles.json

결혼 후보는 `character_id`로 `npcs.json`의 NPC를 참조한다. 왕족을 제외한 `knight`, `baron`, `viscount`, `count`, `marquis`, `duke`는 각 계급별 최소 3명씩 유지한다.

```json
{
  "id": "candidate_knight_cedric",
  "character_id": "npc_knight_cedric",
  "rank": "knight",
  "marriage_difficulty": 32,
  "preferred_stats": {"beauty": 0.7, "wildness": 0.8, "etiquette": 0.7},
  "minimums": {"beauty": 30, "etiquette": 8},
  "match_start_axes": {"favor": 15, "interest": 20, "trust": 25},
  "family_scrutiny": 10,
  "security_level": 30,
  "wealth_gain": 10,
  "status_gain": 1,
  "special_traits": ["honor_bound", "debt_pressure"],
  "motivation_ko": "혼인으로 얻고 싶은 것",
  "pressure_ko": "가문/파벌/경제가 주는 현재 압박",
  "weakness_hint_ko": "고급 정보 품질에서 드러나는 공략 단서",
  "spouse_dynamic_ko": "결혼 이후 관계 관리의 긴장",
  "unique_match_choices": [
    {
      "id": "match_unique_cedric_debt_probe",
      "name_ko": "빚 이야기를 돌려 묻는다",
      "candidate_specific": true,
      "tags": ["subtle_probe", "political"],
      "requirements": {"information": 18, "mask": 10},
      "effects": {"political_value": 5, "trust": 3, "comfort": -2},
      "state_dialogue": {
        "reduced": "요즘 기사 가문의 채무가 흔하다지요. 경의 이야기는 아니라고 믿습니다만…",
        "backfire": "빚이 상당하시다 들었습니다. …아직 비밀이었습니까?"
      },
      "line_context": "political_value_offer"
    }
  ]
}
```

`motivation_ko`, `pressure_ko`, `weakness_hint_ko`, `spouse_dynamic_ko`는 후보를 단순 작위/조건 묶음이 아니라 이해관계가 있는 인물로 보이게 하는 서사 필드다. 후보 화면에서는 정보 품질 30 이상에 혼인 동기, 60 이상에 내부 압박과 결혼 후 긴장, 85 이상에 약점 단서를 표시한다. 결혼 후 배우자 화면에서는 `spouse_dynamic_ko`와 `special_traits`를 사용해 결혼 생활 행동의 추가 반응을 계산한다.
배우자 화면의 가문 카드는 `faction`, `rank`, `pressure_ko`, `weakness_hint_ko`, `family_scrutiny`, `security_level`, `special_traits`를 사용한다. `faction`은 한글 가문/파벌명으로 변환되고, `special_traits`는 하인, 섭정 친족, 계승 경쟁자, 상단/장부, 기록관, 살롱, 무장 수행원, 외교 사절 같은 주변 세력 설명으로 변환된다.
`unique_match_choices`는 선택 필드다. 후보별 맞선 선택지를 기본 선택지보다 먼저 표시하며, 선택지 구조는 `match_config.json`의 `choice_examples`와 동일하다.
맞선 선택지의 숫자 스탯 `requirements`는 권장 숙련치다. 현재 수치가 기준의 40~99%면 긍정 효과가 줄고 부정 효과가 커지며, 40% 미만이면 긍정 효과 일부가 실제 하락으로 반전된다. 정확히 40%인 경계에서는 원래 긍정 효과를 0으로 만들어 역효과에서 감소 효과로 넘어가는 중립 완충점으로 사용한다. 잠금이 필요한 조건만 `hard_requirements`에 기록한다.
`state_dialogue`는 선택 필드이며 `reduced`, `backfire` 상태에서 출력할 주인공 전용 대사를 정의한다. 전용 문장이 없으면 시스템 공통 보정 문장을 사용하고, `stable` 상태는 기존 `line_context`와 대사 단계 템플릿을 유지한다.

런타임 `current_match`에는 선택한 화제 id를 순서대로 담는 `choice_history: Array[String]`와 화제별 누적 사용 횟수를 담는 `choice_usage: Dictionary`가 포함된다. 효과 미리보기와 실제 적용은 현재 사용 횟수를 기준으로 같은 반복 감쇠를 계산하며, 턴 확정 뒤 두 필드를 갱신한다. 두 필드는 일반 상태 저장에 포함되어 맞선 도중 저장·불러오기에서도 반복 상태가 유지된다.

## rank_events.json

`rank_events`는 결혼 이후 시간이 흐를 때 배우자 작위와 가문 성향에 따라 발생하는 중후반 압박 이벤트다. `weekly_check.start_week` 이후 `interval_weeks` 주기마다 검사하며, 조건에 맞는 미발생 이벤트 중 `priority`와 후보 특성 일치 수가 높은 항목을 선택한다.

```json
{
  "id": "rank_pressure_count_salon_faction",
  "name_ko": "백작가 살롱 파벌전",
  "summary_ko": "살롱 후원자와 군수 계약자들이 편을 가르며 주인공에게 공개 입장을 요구한다.",
  "rank_ids": ["count"],
  "trigger_traits_any": ["salon_patron", "military_supply"],
  "min_week": 30,
  "cooldown_weeks": 6,
  "priority": 50,
  "effects": {"social": 1, "influence": 1, "social_suspicion": 4, "stress": 4, "public_harmony": -4},
  "unlock_candidates": [{"rank": "marquis", "quality": 35, "count": 1}]
}
```

`effects`는 기존 상태 변화 규칙을 따른다. `unlock_candidates`는 이벤트 발생 후 다음 작위 후보 정보를 일부 열어 중후반 진행이 끊기지 않도록 한다. 이벤트는 `rank_event_seen_<id>` 플래그로 1회 발생 처리된다.

## marriage_config.json

`wedding_options`는 결혼식 선택지다. `effects`는 결혼 성립 이후 배우자 상태와 주인공 스탯에 적용된다.

```json
{
  "id": "wedding_social",
  "name_ko": "사교적 결혼식",
  "weeks": 3,
  "cash_cost": 18,
  "effects": {"cash": -18, "public_harmony": 10, "social": 5, "influence": 2, "fatigue": 5}
}
```

`wedding_result_events`는 결혼식 결과 이벤트다. `option_ids`가 있으면 해당 결혼식 옵션에서만 발생하고, `rank_ids`가 있으면 해당 후보 작위에서만 발생한다. `trigger_traits_any`가 있으면 후보 `special_traits` 중 하나 이상이 일치해야 한다. 조건을 만족하는 이벤트 중 `priority`와 특성 일치 수가 높은 항목을 선택한다.

```json
{
  "id": "wedding_social_useful_introductions",
  "name_ko": "쓸 만한 소개",
  "summary_ko": "적당히 갖춘 예식은 하객들의 입을 열었다.",
  "option_ids": ["wedding_social"],
  "priority": 10,
  "effects": {"information": 2, "influence": 1, "public_harmony": 2}
}
```

## removal_methods.json

제거 방식은 실제 절차가 아니라 게임 추상화다.

```json
{
  "id": "removal_scandal_disgrace",
  "category": "political_removal",
  "weeks_to_prepare": 6,
  "base_success": 55,
  "requirements": {"information": 40, "social": 15, "leverage": 20},
  "risk_profile": {"social_suspicion": 4, "evidence_risk": 10},
  "success_result": {
    "type": "political_disgrace",
    "name_ko": "정치적 실각",
    "spouse_removed": true,
    "widow": false,
    "unlock_next_rank": true,
    "effects": {"influence": 1, "notoriety": 1},
    "case_initial": {"investigation_progress": 6, "rumor_spread": 18, "evidence_risk": 8}
  },
  "countered_by": ["strong_family", "high_reputation", "royal_patronage"]
}
```

`success_result`는 처리 성공 후 결과 분기를 정의한다. `type`은 `fatal_case`, `political_disgrace`, `distant_assignment`, `annulment` 등을 사용한다. `widow: false`인 결과는 미망인 플래그와 반복 미망인 페널티를 만들지 않으며, 대신 정치 후폭풍 파일을 생성한다. `spouse_removed`는 배우자 대시보드에서 이탈시키는지, `unlock_next_rank`는 다음 작위 후보 접근을 열지 결정한다.

`counter_events`는 제거/정치처리 방식에 대응하는 추상 이벤트다. 실제 절차가 아니라 가문 방어, 하인 증언, 주치의 검토, 군무 후원, 성직 기록 같은 판정 요소만 다룬다.

```json
{
  "id": "counter_family_shields_reputation",
  "name_ko": "가문의 평판 방패",
  "counter_ids": ["strong_family", "high_reputation"],
  "method_ids": ["removal_scandal_disgrace"],
  "trigger": {
    "candidate_traits_any": ["bloodline_pride", "ducal_house"]
  },
  "priority": 42,
  "success_modifier": -15,
  "effects": {"social_suspicion": 3},
  "case_effects": {"rumor_spread": 8}
}
```

`method_ids`가 있으면 특정 방식에만 적용된다. `trigger.candidate_traits_any`, `trigger.spouse_min`, `trigger.spouse_max`, `trigger.player_min`, `trigger.player_max`, `trigger.rank_ids`로 발생 조건을 좁힌다. 실행 전 `effects`와 `success_modifier`가 적용되고, 사건 파일 생성 후 `case_effects`가 조사/소문/증거 위험에 반영된다.

## coverup_actions.json

은폐 행동도 실제 절차가 아니라 위험 토큰 조정이다.

```json
{
  "id": "coverup_public_mourning",
  "weeks": 1,
  "requirements": {"mask": 20},
  "base_success": 86,
  "effects": {"public_grief": 12, "social_suspicion": -3},
  "effects_on_fail": {"public_grief": 3, "social_suspicion": 3}
}
```

`effects`는 성공 효과, `effects_on_fail`은 실패 효과다. 실제 성공률은 `base_success`에 주인공의 가면술/정보력/사교력 보정과 현재 사건 위험 페널티를 더해 계산한다.
