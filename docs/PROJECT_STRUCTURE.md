# Marriage intrigue 프로젝트 구조

이 문서는 실제 Godot 프로젝트 루트인 `Marriage intrigue/Marriage intrigue`를 기준으로 정리한 구조 문서입니다.

## 프로젝트 개요

- 엔진: Godot 4.7, GL Compatibility 렌더러
- 실행 진입점: `res://scenes/main/Main.tscn`
- 메인 UI 라우터/공통 UI 스크립트: `res://scripts/ui/Main.gd`
- 주요 방식: JSON 데이터 기반 싱글 씬 UI 프로토타입
- Autoload: `DataManager`, `GameState`, `TimeManager`, `ActionResolver`, `SaveManager`

## 최상위 구조

```text
res://
  project.godot
  icon.svg
  assets/
    art/
  data/
  docs/
  scenes/
  scripts/
  tmp/
```

## 실행 흐름

```text
project.godot
  run/main_scene = res://scenes/main/Main.tscn

scenes/main/Main.tscn
  Main: Control
    script = res://scripts/ui/Main.gd

scripts/ui/Main.gd
  _ready()
    dashboard_screen = DashboardScreen.new()
    DataManager.load_all()
    GameState.start_new_game(...)
    _build_layout()
    _show_dashboard()
```

## Autoload 스크립트

```text
scripts/autoload/
  DataManager.gd
    data/ 아래 JSON 테이블 로드 및 조회

  GameState.gd
    플레이어 상태, 주차, 플래그, 관계, 배우자, 사건 파일, 로그 관리

  TimeManager.gd
    주 단위 시간 진행과 week_advanced 신호 발행

  ActionResolver.gd
    행동 요구 조건, 비용, 효과, 성공 판정 처리

  SaveManager.gd
    user:// 기반 저장/불러오기
```

## UI 구조

```text
scripts/ui/
  Main.gd
    배경, 헤더, 내비게이션, 본문, 로그 패널을 코드로 생성
    화면 라우팅과 공통 UI 헬퍼 담당

  screens/
    DashboardScreen.gd
      생활 화면, 월간 목표, 3칸 장기 행동 일정, 능력 장부, 하단 행동 리본 담당
    FreeActionsScreen.gd
      자유행동 목록, 카테고리 필터, 장착 아이템 보정 표시 담당
    ShopScreen.gd
      아이템 구매, 장착, 해제 버튼과 슬롯 표시 담당
    CharactersScreen.gd
      인물 목록, 역할군 필터, 시간·비용 기반 상호작용 담당
    MatchBattleScreen.gd
      응접실 혼인 교섭 화면, 인물/대사/관계 리본/화제 선택/결과 패널 담당

  MatchRadarChart.gd
    맞선 화면의 6축 관계 수치 레이더 차트 렌더링
  MatchBattleBackdrop.gd
    맞선 페이즈 전용 응접실과 턴 결과에 반응하는 광원, 휘장, 차탁, 촛불 렌더링
  MatchMomentumRibbon.gd
    순효과 방향, 주요 관계축, 반복 권태를 중앙 장력선으로 렌더링
  TimePassageFlow.gd
    일상 행동부터 월·연도 전환까지 공통 사용하는 시간 궤적과 주차 눈금 렌더링
```

`Main.gd`의 공통 레이아웃은 다음 구조를 갖습니다.

```text
Main(Control)
  Background TextureRect
  Dark Shade ColorRect
  UI Texture Overlay
  MarginContainer
    VBoxContainer root
      Header Label
      Navigation HBoxContainer
      Body HBoxContainer
        ScrollContainer
          VBoxContainer content
        Log Panel
          ItemList log_list
```

## 주요 화면

| 화면 ID | 역할 |
| --- | --- |
| `dashboard` | 생활 화면, 월간 목표, 장기 행동 일정 예약/실행, 능력 장부, 저장 컨트롤 |
| `free` | 자유 행동 목록 및 실행 |
| `shop` | 아이템 구매, 장착, 해제 |
| `characters` | NPC 목록, 상호작용, 거래 |
| `personas` | 페르소나 선택과 맞선 보정 |
| `rumors` | 소문 주제와 작전 실행 |
| `candidates` | 후보 발견, 정보 열람, 맞선 시작 |
| `match` | 응접실 대화 교섭, 핵심 관계 리본과 6축 판정, 화제 선택 |
| `wedding` | 결혼 옵션 진행 |
| `spouse` | 배우자 상태와 결혼 생활 행동 |
| `removal` | 제거/정치 처리 방식 선택 |
| `coverup` | 사건 파일, 위험 수치, 은폐 행동 |
| `game_over` | 게임 오버 사유와 새 게임 |
| `complete` | 현재 구현 범위 완료 요약 |

## 데이터 구조

```text
data/
  meta/
    game_config.json

  player/
    player_initial_state.json
    dialogue_stages.json
    personas.json
    choice_tags.json
    dialogue_templates.json

  time/
    free_actions.json

  characters/
    npcs.json
    candidate_profiles.json
    relationship_axes.json

  shop/
    items.json

  rumors/
    rumor_actions.json

  match/
    match_config.json

  marriage/
    marriage_config.json

  removal/
    removal_methods.json

  coverup/
    coverup_actions.json

  nobility/
    ranks.json
    rank_events.json

  tutorial/
    tutorial_flow.json
```

데이터 파일은 화면 표시와 행동 처리의 원천입니다. 새 기능을 추가할 때는 가능한 한 JSON 스키마를 먼저 확장하고, `DataManager`와 `ActionResolver`가 이를 읽어 처리하도록 유지하는 편이 현재 구조와 잘 맞습니다.

## 아트 에셋

```text
assets/art/
  manor_corridor_bg.png
    메인 UI 배경 이미지

  protagonist_portrait.png
    대시보드 주인공 초상

  ui/
    medieval_panel_texture.png
    medieval_divider.png
    medieval_card_trim.png
    *_raw.png

  characters/
    npc_*.png
    후보, NPC, 상점/정보원/라이벌 초상

  characters/silhouettes/
    candidate_*_silhouette.png
    고위 후보 임시 실루엣

  characters/spouse/
    *_spouse_affectionate.png
    *_spouse_suspicious.png
    *_spouse_weakened.png
    배우자 상태별 초상
```

## 씬과 도구

```text
scenes/
  main/
    Main.tscn

scripts/tools/
  CaptureUi.gd
    주요 화면 캡처용 도구

  SmokeCharacterInteractions.gd
    인물 상호작용의 시간·피로·관계 변화와 거래 화면 이동 검증

  SmokeSaveLoad.gd
    저장/불러오기 스모크 테스트용 도구
```

## 내보내기

- `export_presets.cfg`에 Godot 4.7용 `Windows Desktop` 릴리스 프리셋이 있다.
- 기본 출력은 `build/windows/MarriageIntrigue.exe`이며 `build/`는 버전 관리에서 제외한다.
- `tmp/`, `docs/`, `scripts/tools/`와 미사용 원본·실루엣 이미지는 릴리스 패키지에 포함하지 않는다.

## 문서

```text
docs/
  SHARED_CONTEXT.md
  PROJECT_STATUS_2026-09-03.md
  PROJECT_STRUCTURE.md
  GODOT_PROJECT_STRUCTURE.md
  UI_WIREFRAME.md
  PROJECT_SPEC.md
  DATA_SCHEMA.md
  IMPLEMENTATION_BACKLOG.md
  IMPLEMENTATION_NOTES.md
  IMPLEMENTATION_STATUS_CHECKLIST.md
  CODEX_IMPLEMENTATION_DATA_SUMMARY.md
```

## 임시/검증 산출물

```text
tmp/
  ui_capture_*.png
  *_contact_sheet.png
```

`tmp/`는 UI 캡처, 초상 비교, 에셋 검토용 산출물이 모이는 위치입니다. 게임 런타임에서 직접 참조하는 파일은 `assets/`, `data/`, `scenes/`, `scripts/` 아래에 두는 것이 좋습니다.

## 변경 시 갱신 기준

- 새 Autoload 추가: 이 문서의 Autoload 섹션과 `project.godot` 확인
- 새 화면 추가: UI 구조와 주요 화면 표 갱신
- 새 JSON 테이블 추가: 데이터 구조와 `DATA_SCHEMA.md` 갱신
- 새 아트 경로 추가: 아트 에셋 섹션 및 해당 JSON의 `portrait`/리소스 경로 확인
- UI 배치 변경: `UI_WIREFRAME.md`와 `UI_WIREFRAME.png` 갱신
