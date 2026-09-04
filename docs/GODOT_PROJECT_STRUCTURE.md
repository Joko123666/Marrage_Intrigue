# Godot 프로젝트 구조

이 문서는 현재 실제 구현 구조를 기준으로 유지한다. 새 화면, 데이터 파일, Autoload, 에셋을 추가할 때 이 문서를 같이 갱신한다.

## 프로젝트 루트

```text
res://
  project.godot
  icon.svg
  assets/
  data/
  docs/
  scenes/
  scripts/
```

## 실행 진입점

```text
project.godot
  [application]
    run/main_scene = res://scenes/main/Main.tscn

scenes/main/Main.tscn
  Control
    script = res://scripts/ui/Main.gd
```

`Main.gd`는 화면 라우터와 공통 UI 빌더 역할을 맡고, 화면별 본문은 `scripts/ui/screens/`로 단계적으로 분리한다. 현재 대시보드, 자유행동, 상점, 인물, 맞선 전용 화면이 별도 스크린 스크립트로 분리되어 있다.

## Autoload

```text
scripts/autoload/
  DataManager.gd       JSON 로딩과 id 조회
  GameState.gd         런타임 상태, 스탯, 위험, 관계, 후보, 배우자, 사건 파일
  TimeManager.gd       1주 단위 시간 진행, 나이 증가
  ActionResolver.gd    행동 요구조건, 비용, 효과, 성공 판정
  SaveManager.gd       user:// JSON 저장/불러오기
```

`project.godot` Autoload 등록:

```text
DataManager
GameState
TimeManager
ActionResolver
SaveManager
```

## 도메인 시스템

```text
scripts/systems/
  ProgressionOverview.gd 튜토리얼 진행도, 현재 목표, 힌트, 다음 행동을 단일 스냅샷으로 계산
```

화면은 이 스냅샷을 읽기만 하며 진행 규칙을 별도로 중복 구현하지 않는다. 맞선·결혼·배우자 제거 같은 핵심 상태 변경은 `GameState.gd`의 전이 API를 통해 수행한다.

## UI

```text
scripts/ui/
  Main.gd              화면 라우터, 공통 레이아웃, 공통 UI 헬퍼
  StrategicOverviewPanel.gd 상태·목표·확보 정보 통합 전략 현황판
  MatchRadarChart.gd   맞선 6축 레이더 차트 드로잉
  MatchBattleBackdrop.gd 맞선 결과에 반응하는 응접실 광원·휘장·촛불 배경 드로잉
  MatchMomentumRibbon.gd 맞선 순효과·주요 축·반복 단계 기반 중앙 장력선
  TimePassageFlow.gd  모든 주차 경과에 재사용하는 밤→새벽 궤적·주차 눈금
  screens/
    DashboardScreen.gd 생활 화면, 월간 목표, 3칸 일정, 능력 장부, 행동 리본
    FreeActionsScreen.gd 자유행동 본문, 카테고리 필터, 행동 실행
    ShopScreen.gd 아이템 구매/장착/해제
    CharactersScreen.gd 인물 목록, 역할군 필터, 시간·비용 기반 상호작용
    MatchBattleScreen.gd 인물 중심 혼인 교섭 UI와 결과 전환

scripts/tools/
  CaptureUi.gd          주요 UI 화면을 PNG로 캡처하는 검수용 스크립트
  SmokeDashboardSchedule.gd 대시보드 3칸 일정 예약·실행·초기화 회귀 테스트
  SmokeCharacterInteractions.gd 인물 상호작용 시간 경제와 화면 이동 검증
  SmokeSaveLoad.gd      저장/불러오기 스모크 테스트
  SmokeFlowInvariants.gd 상태 전이, 재혼, 장비 경계, 소문 대상 효과 회귀 테스트
  SmokeStrategicOverview.gd 전략 현황판 진행 상태·CTA·실시간 반응형 회귀 테스트
  SmokeUiFeedback.gd    버튼·배너·연속 토스트 수명주기 회귀 테스트
```

`Main.gd`의 현재 화면:

```text
dashboard    생활 화면, 월간 목표, 장기 행동 일정, 능력 장부, 전략 현황판
free         자유행동 목록과 실행
shop         아이템 구매/장착
characters   NPC 목록과 1주·피로·자원 비용 기반 상호작용
personas     페르소나 선택과 맞선 보정 표시
rumors       소문 주제/작전
candidates   결혼 후보 발견/정보 품질/맞선 시작
match        응접실 대화 교섭, 핵심 관계 리본, 6축 판정과 화제 선택지
wedding      결혼식 옵션
spouse       배우자 상태와 결혼 생활 행동
removal      제거/정치처리 방식 비교와 실행
coverup      은폐 사건 파일과 위험 관리
```

`Main.gd`의 공통 UI 헬퍼:

```text
_build_layout()          배경, 헤더, 내비게이션, 본문/로그 2열 구성
_refresh_nav()           현재 상태에 맞는 내비게이션 버튼 생성
_add_nav_button()        현재 화면 버튼 강조 포함
_add_card()              공통 반투명 카드 패널
_make_label()            공통 텍스트 스타일
_style_button()          일반/활성/비활성 버튼 스타일
_load_texture()          ResourceLoader 기반 이미지 로딩
```

## 검수 도구

```text
scripts/tools/CaptureUi.gd
```

현재 캡처 대상:

```text
tmp/ui_capture_dashboard.png
tmp/ui_capture_free.png
tmp/ui_capture_shop.png
tmp/ui_capture_characters.png
tmp/ui_capture_candidates.png
tmp/ui_capture_candidates_accessible.png
tmp/ui_capture_spouse.png
tmp/ui_capture_spouse_affectionate.png
tmp/ui_capture_spouse_suspicious.png
tmp/ui_capture_spouse_weakened.png
```

실행 예:

```powershell
& "C:\Users\USER\Desktop\Godot_v4.7-stable_win64.exe" --path . --display-driver windows --rendering-method gl_compatibility --script scripts/tools/CaptureUi.gd
```

Headless 실행은 프로젝트 로딩 검증에는 사용 가능하지만, 현재 화면 캡처는 일반 실행에서 저장 여부를 확인한다.

## 내보내기

`export_presets.cfg`의 `Windows Desktop` 프리셋은 `build/windows/MarriageIntrigue.exe`를 생성한다. 릴리스 패키지에서는 `build/`, `tmp/`, `docs/`, `scripts/tools/`와 미사용 원본·실루엣 이미지를 제외한다.

## 데이터

```text
data/
  meta/game_config.json
  player/
    player_initial_state.json
    dialogue_stages.json
    personas.json
    choice_tags.json
    dialogue_templates.json
  time/free_actions.json
  characters/
    npcs.json
    candidate_profiles.json
    relationship_axes.json
  shop/items.json
  rumors/rumor_actions.json
  match/match_config.json
  marriage/marriage_config.json
  removal/removal_methods.json
  coverup/coverup_actions.json
  nobility/
    ranks.json
    rank_events.json
  tutorial/tutorial_flow.json
```

데이터 규칙은 [DATA_SCHEMA.md](DATA_SCHEMA.md)를 따른다. 새 시스템은 가능하면 새 하드코딩보다 JSON 필드를 먼저 추가하고, `ActionResolver` 또는 전용 시스템에서 해석한다.
결혼 후보는 왕족을 제외한 `knight`, `baron`, `viscount`, `count`, `marquis`, `duke` 계급별 최소 3명씩 유지한다.

## 이미지/에셋

```text
assets/art/
  manor_corridor_bg.png       메인 UI 배경
  protagonist_portrait.png    대시보드 주인공 초상화
  ui/
    medieval_divider.png       화면 섹션 구분선 장식
    medieval_card_trim.png     카드 상단 장식
    medieval_panel_texture.png 전체 UI 질감 오버레이
    *_raw.png                  이미지 생성 원본 보존본
  characters/
    npc_baron_lucas_generated.png 남작 후보 루카스 초상화
    npc_baron_etienne.png     남작 후보 에티엔 초상화
    npc_baron_marius.png      남작 후보 마리우스 초상화
    npc_viscount_theodore.png 자작 후보 테오도르 초상화
    npc_viscount_hugo.png     자작 후보 위고 초상화
    npc_viscount_felix.png    자작 후보 펠릭스 초상화
    npc_count_astian.png      백작 후보 아스티앙 초상화
    npc_count_benedict.png    백작 후보 베네딕트 초상화
    npc_count_claude.png      백작 후보 클로드 초상화
    npc_marquis_valerian.png  후작 후보 발레리앙 초상화
    npc_marquis_renard.png    후작 후보 르나르 초상화
    npc_marquis_dorian.png    후작 후보 도리앙 초상화
    npc_duke_everard.png      공작 후보 에버라드 초상화
    npc_duke_severin.png      공작 후보 세브린 초상화
    npc_duke_cassian.png      공작 후보 카시안 초상화
    npc_broker_crow.png       정보상 브렌 초상화
    npc_guild_contact_ash.png 뒷세계 중개인 애쉬 초상화
    npc_knight_adrien.png     기사 후보 아드리엔 초상화
    npc_knight_cedric.png     기사 후보 세드릭 초상화
    npc_knight_rohan.png      기사 후보 로한 초상화
    npc_maid_ella.png         하녀 엘라 초상화
    npc_rival_celina.png      사교 라이벌 셀리나 초상화
    npc_tailor_mirelle.png    재단사 미렐 초상화
    silhouettes/
      candidate_baron_silhouette.png    미사용 후보 실루엣 보존본
      candidate_duke_silhouette.png     미사용 후보 실루엣 보존본
    spouse/
      npc_knight_adrien_spouse_affectionate.png 아드리엔 배우자 애정 상태
      npc_knight_adrien_spouse_suspicious.png   아드리엔 배우자 의심 상태
      npc_knight_adrien_spouse_weakened.png     아드리엔 배우자 쇠약 상태
      npc_baron_lucas_spouse_affectionate.png   루카스 배우자 애정 상태
      npc_baron_lucas_spouse_suspicious.png     루카스 배우자 의심 상태
      npc_baron_lucas_spouse_weakened.png       루카스 배우자 쇠약 상태
```

이미지는 export 빌드와 Godot importer 경로를 일관되게 사용하도록 `Main.gd`에서 `ResourceLoader`로 읽는다.
NPC/후보 기본 초상화 경로는 `data/characters/npcs.json`의 `portrait` 필드에서 읽는다. 배우자 상태별 초상화는 같은 파일의 `spouse_portraits` 필드에서 읽는다.
중세풍 UI 장식은 `Main.gd`에서 배경 질감 오버레이, 섹션 구분선, 카드 상단 트림으로 적용한다.

## 문서

```text
docs/
  SHARED_CONTEXT.md
  PROJECT_STATUS_2026-09-03.md
  PROJECT_SPEC.md
  DATA_SCHEMA.md
  IMPLEMENTATION_BACKLOG.md
  IMPLEMENTATION_NOTES.md
  GODOT_PROJECT_STRUCTURE.md
  UI_WIREFRAME.md
```

작업 규칙:

- 구조 변경 시 `GODOT_PROJECT_STRUCTURE.md` 갱신.
- 화면/레이아웃/흐름 변경 시 `UI_WIREFRAME.md` 갱신.
- 구현 범위나 검증 상태 변경 시 `IMPLEMENTATION_NOTES.md` 갱신.
