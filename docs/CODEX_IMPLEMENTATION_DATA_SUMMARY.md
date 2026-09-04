# 귀족 권력상승 시뮬레이션 - Codex 구현용 데이터 정리 v0.1

## 1. 사용 엔진

**Godot Engine 4.x** 기준으로 정리한다.

이 기획은 액션보다 UI, 상태표, 선택지, 장기 시뮬레이션, 데이터 기반 이벤트가 핵심이므로 Godot의 2D/Control UI와 데이터 로딩 구조에 잘 맞는다.

## 2. Codex에 전달할 핵심 목표

Codex가 우선 구현해야 하는 것은 전체 게임이 아니라 다음 수직 절편이다.

```text
14세 평민 고아 시작
→ 1주 단위 자유행동
→ 상인/정보상 상호작용
→ 기사 후보 색출
→ 맞선 레이더 승부
→ 결혼
→ 배우자 대시보드
→ 제거 또는 정치처리
→ 은폐 사건 파일
→ 남작 후보 접근권 획득
```

## 3. 패키지 구성

```text
CODEX_README.md

docs/
  PROJECT_SPEC.md
  DATA_SCHEMA.md
  IMPLEMENTATION_BACKLOG.md
  GODOT_PROJECT_STRUCTURE.md

res/data/
  meta/game_config.json
  player/player_initial_state.json
  player/dialogue_stages.json
  player/personas.json
  player/choice_tags.json
  player/dialogue_templates.json
  time/free_actions.json
  characters/npcs.json
  characters/candidate_profiles.json
  characters/relationship_axes.json
  shop/items.json
  rumors/rumor_actions.json
  match/match_config.json
  marriage/marriage_config.json
  removal/removal_methods.json
  coverup/coverup_actions.json
  nobility/ranks.json
  tutorial/tutorial_flow.json

res/scripts/autoload/
  DataManager.gd
  GameState.gd
  TimeManager.gd
  ActionResolver.gd

codex_prompts/
  01_bootstrap_project.md
  02_free_action_system.md
  03_persona_dialogue_system.md
  04_match_system.md
  05_removal_coverup_system.md
```

## 4. 구현 우선순위

1. 데이터 로더와 새 게임 시작
2. 1주 단위 시간/행동 시스템
3. 주인공 대사 단계와 페르소나
4. 캐릭터/관계 시스템
5. 상점/아이템
6. 소문 조사/유포
7. 후보 색출/정보 품질
8. 맞선 레이더 시스템
9. 결혼/배우자 대시보드
10. 제거/정치처리 MVP
11. 은폐 사건 파일
12. 기사 튜토리얼 수직 절편 완성

## 5. 데이터 규칙 요약

- 모든 id는 snake_case.
- 모든 스탯은 기본 0~100.
- 행동은 `weeks`만큼 시간을 소모한다.
- 행동 결과는 `effects`의 델타를 적용한다.
- 요구조건은 `requirements`로 검사한다.
- 모든 상태 변화는 로그로 남긴다.
- 제거/은폐는 실제 절차가 아니라 추상 게임 판정으로 구현한다.

## 6. Codex에게 줄 기본 프롬프트

```text
이 프로젝트는 Godot 4.x / GDScript 2.0 기반의 PC용 2D UI 시뮬레이션이다.
먼저 docs/PROJECT_SPEC.md, docs/DATA_SCHEMA.md, docs/IMPLEMENTATION_BACKLOG.md를 읽고,
res/data/**/*.json을 원본 게임 데이터로 사용해 단계별로 구현해라.
처음 구현 목표는 기사 튜토리얼 수직 절편이다.
모든 기능은 데이터 주도 구조로 만들고, JSON 필드가 빠져도 크래시하지 않도록 기본값을 사용해라.
제거/은폐 시스템은 실제 범죄 절차가 아니라 추상화된 게임 수치와 위험 토큰으로만 구현해라.
```

## 7. 가장 먼저 만들 화면

- DashboardScreen: 현재 주차, 나이, 스탯, 자금, 의심도, 로그
- FreeActionScreen: 자유행동 버튼 목록
- CharacterListScreen: 재단사, 정보상, 기사 후보, 라이벌 표시
- CandidateScreen: 후보 색출과 정보 품질
- MatchScreen: 6축 맞선 레이더/막대
- SpouseDashboardScreen: 결혼 후 배우자 상태
- RemovalScreen: 제거/정치처리 선택
- CoverupCaseScreen: 은폐 사건 파일

## 8. 주의점

초기 버전에서 후작, 공작, 왕족, 쿠데타, 대규모 파벌전까지 구현하려고 하면 범위가 과해진다. Codex 작업은 반드시 기사 튜토리얼 루프를 먼저 완성한 뒤 확장해야 한다.
