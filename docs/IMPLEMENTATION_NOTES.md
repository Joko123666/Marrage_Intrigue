# 구현 메모 v0.1

이 폴더 자체가 Godot 프로젝트 루트다. Godot 4.x에서 `project.godot`을 열면 `res://scenes/main/Main.tscn`이 실행된다.

## 현재 구현 범위

- JSON 로딩 Autoload
- 새 게임 시작과 런타임 상태 관리
- 1280x720 기준 해상도, Control UI 확장 스케일 정책, 작은 창/모바일 세로 배치 전환
- 작은 창과 640px 모바일 폭에서 후보/인물/배우자 초상화 행, 상태 카드 그리드, 필터/저장 버튼 줄바꿈 대응
- 1주 단위 시간 진행
- 30세부터 연령별 맞선 준비 페널티 적용, 35세 도달 시 연령 한계 게임오버
- 자유행동 실행, 비용/조건/효과 처리와 카테고리 필터
- `stat_influence` 기반 공통 능력 판정: 행동별 가중 스탯, 피로/스트레스, 성공률, 효과량, 실패 위험을 함께 계산
- 상점 구매/장착
- 상점 장착 해제와 같은 슬롯 아이템 교체 시 이전 효과 제거
- 장비 효과는 슬롯별 실제 적용 변화량을 저장해 0/100 경계에서도 안전하게 해제하고 세이브 스키마 3으로 복원
- 장착 아이템의 행동/맞선/은폐 보정 연결
- 인물 목록 표시와 1주·피로·자원 비용이 적용되는 기본 상호작용
- 인물 역할군 필터
- 인물 화면을 `scripts/ui/screens/CharactersScreen.gd`로 분리하고 관계 효과를 `ActionResolver`에서 공통 적용
- 페르소나 선택, 맞선 축 보정, 주간 자금/피로 유지비와 유지비 부족 후폭풍
- 소문 주제/작전 화면
- 소문 작전 데이터의 대상 NPC와 성공/실패 관계 효과를 `ActionResolver`에서 공통 적용
- 후보 발견/정보 품질 표시
- 후보 작위 필터와 작위/정보/난도/보안 정렬
- 대시보드 현재 상태 요약/경보/추천 행동 표시
- 대시보드 상단에 현재 진행 단계·지위·대사/페르소나, 현재 목표·진행률·바로가기, 후보·인맥·보유품·최대 위험을 묶은 전략 현황판 표시
- 대시보드 첫 화면을 생활 공간 속 주인공, 월간 목표, 최대 3개 장기 행동 일정, 능력/평판/위험 장부, 하단 행동 리본으로 재구성
- 예약 일정은 확정 시 순차 실행하며 중간에 자원 조건을 잃으면 남은 행동을 중단
- 전략 현황판은 데스크톱 3열, 작은 창 2열, 모바일 1열로 전환하고 사건 상태에서는 긴급 브리핑과 은폐 바로가기를 표시
- 대시보드 본문을 `scripts/ui/screens/DashboardScreen.gd`로 1차 분리
- 자유행동 본문을 `scripts/ui/screens/FreeActionsScreen.gd`로 분리
- 상점 본문을 `scripts/ui/screens/ShopScreen.gd`로 분리
- 후보별 혼인 동기/내부 압박/약점/결혼 후 긴장 표시
- 왕족을 제외한 기사/남작/자작/백작/후작/공작 후보를 계급별 3명씩 구성
- 현재 신분/사교/영향력 조건에 따른 접근 가능 후보 해금
- `tutorial_flow.json` 기반 대시보드 튜토리얼 진행 카드와 단계 완료 체크
- 맞선 레이더 선택지와 성공/실패 판정
- 혼인/결혼식 대기/진행 중 사건/게임오버에서는 새 맞선 진입을 `GameState`가 차단
- 맞선 예측과 최종 판정은 연령 페널티를 포함한 단일 준비 보너스 계산을 사용
- 맞선 숫자 스탯 요구치는 선택지를 잠그지 않고 부족 비율에 따라 상승량 감소·부작용 강화·긍정 효과 반전으로 처리
- 맞선 선택지 잠금은 `hard_requirements`와 플레이어 스탯이 아닌 필수 조건에만 적용
- 일반 HUD를 숨기는 맞선 전용 응접실 교섭 UI, 양측 초상화, 대화 핍, 핵심 관계 리본, 화제 단축키, 성공/실패 결과 전환
- 결혼식 선택과 배우자 대시보드
- 결혼식 옵션/후보 특성 기반 결과 이벤트와 효과 적용
- 결혼 이후 배우자 작위/후보 특성 기반 중후반 압박 이벤트와 다음 작위 후보 해금
- 결혼 생활 행동으로 금슬, 의심, 정보 조정
- 배우자 후보 특성에 따른 결혼 생활 행동 추가 반응
- 배우자 후보의 가문/파벌, 내부 압박, 약점 단서, 감시/보안 수치, 주변 세력 요약 표시
- 제거/정치처리 판정
- 제거/정치처리 방식별 `countered_by`와 후보 특성/배우자 상태 기반 대응 이벤트
- 직접 제거와 비치명 정치/법적 처리의 성공 결과 분기
- 제거/정치처리 카드의 치명/비치명 위험 경고와 2단계 실행 확인
- 은폐 사건 파일과 주간 위험 증가
- 생성 이미지 기반 배경과 주인공 초상화
- 생성 이미지 기반 NPC/후보/배우자 초상화와 카드 배치
- 배우자 상태값 기반 평상/애정/의심/쇠약 초상화 전환
- 생성 이미지 기반 중세풍 UI 장식과 질감 오버레이
- 반투명 패널, 상태 카드, 버튼 스타일 등 기본 UI 테마
- 현재 대사 단계와 선택지 태그 기반 맞선 대사 출력
- 맞선 선택지의 `충분`/`효과↓`/`역효과` 상태에 따른 능숙한 대사·머뭇거림·실언과 상대의 수용·경계·냉각 반응 출력
- 맞선 소프트 요구의 정확한 40% 경계는 긍정 효과 0으로 완충하고, `stats/*` 변경 시 맞선 카드를 지연 일괄 갱신해 표시와 실제 적용값을 동기화
- 스탯과 결혼/미망인/작위 진행에 따른 대사 단계 자동 성장과 단계별 맞선 축 보정
- 맞선 실패 시 부족 축, 점수 차, 준비 보너스를 포함한 상세 사유 표시
- 후보 프로필의 `unique_match_choices` 기반 후보별 맞선 선택지
- `MatchRadarChart.gd` 기반 맞선 6축 레이더 그래프
- 장착 아이템의 맞선 시작 축 보정과 예법 훈련/공개 애도 보정
- 은폐 사건 종결 조건과 게임오버 화면
- 은폐 행동의 현재 성공률, 성공 효과, 실패 효과 분리
- 자유행동·인물 상호작용·소문·결혼 생활·맞선·제거·은폐 카드에 실제 능력 보정과 현재 예상 결과 표시
- 조사/증거/사회적 의심이 높을 때 1회 발생하는 범인 지목 위험 이벤트
- 첫 실패/첫 위험 상승 튜토리얼 안내 로그와 수직 절편 완료 화면
- 두 번째 미망인 사건부터 사회적 의심/악명/출신 소문이 증가하는 반복 이미지 페널티
- 재혼과 새 사건 시작 시 현재 회차의 미망인/비치명 종료/사건 종결/범인 지목 상태를 초기화하고 역사 플래그는 유지
- 행동 차단 사유의 스탯/위험 id 한글 표시
- 행동 로그를 실패/위험/성공/저장/자금 계열 색상으로 분류
- 효과, 요구조건, 관계 수치를 색상 칩으로 표시
- `SaveManager.gd` 기반 `user://marriage_intrigue_save.json` 수동 저장/불러오기
- 매주 경과 시 `user://marriage_intrigue_autosave.json` 자동 저장과 자동 저장 불러오기 버튼
- `user://marriage_intrigue_slot_*.json` 3개 수동 저장 슬롯
- `SAVE_SCHEMA_VERSION` 기반 저장 데이터 마이그레이션과 누락 필드 기본값 보정
- 동적 이미지 경로를 `ResourceLoader`로 불러와 export 빌드 호환성 확보
- 처리 성공 시 현재 배우자 작위의 다음 작위 후보를 여는 기본 중후반 루프

## 생성 이미지 에셋

이미지 생성은 Codex 내장 `image_gen` 도구를 사용했다.

- `res://assets/art/manor_corridor_bg.png`: 귀족 저택 복도 배경
- `res://assets/art/protagonist_portrait.png`: 14세 주인공 초상화
- `res://assets/art/ui/medieval_divider.png`: 화면 섹션 구분선 장식
- `res://assets/art/ui/medieval_card_trim.png`: 카드 상단 플라크 장식
- `res://assets/art/ui/medieval_panel_texture.png`: 전체 UI 질감 오버레이
- `res://assets/art/characters/npc_tailor_mirelle.png`: 재단사 미렐 초상화
- `res://assets/art/characters/npc_broker_crow.png`: 정보상 브렌 초상화
- `res://assets/art/characters/npc_guild_contact_ash.png`: 뒷세계 중개인 애쉬 초상화
- `res://assets/art/characters/npc_knight_adrien.png`: 기사 후보 아드리엔 초상화
- `res://assets/art/characters/npc_knight_cedric.png`: 기사 후보 세드릭 초상화
- `res://assets/art/characters/npc_knight_rohan.png`: 기사 후보 로한 초상화
- `res://assets/art/characters/npc_baron_lucas_generated.png`: 남작 후보 루카스 초상화
- `res://assets/art/characters/npc_baron_etienne.png`: 남작 후보 에티엔 초상화
- `res://assets/art/characters/npc_baron_marius.png`: 남작 후보 마리우스 초상화
- `res://assets/art/characters/npc_viscount_theodore.png`: 자작 후보 테오도르 초상화
- `res://assets/art/characters/npc_viscount_hugo.png`: 자작 후보 위고 초상화
- `res://assets/art/characters/npc_viscount_felix.png`: 자작 후보 펠릭스 초상화
- `res://assets/art/characters/npc_count_astian.png`: 백작 후보 아스티앙 초상화
- `res://assets/art/characters/npc_count_benedict.png`: 백작 후보 베네딕트 초상화
- `res://assets/art/characters/npc_count_claude.png`: 백작 후보 클로드 초상화
- `res://assets/art/characters/npc_marquis_valerian.png`: 후작 후보 발레리앙 초상화
- `res://assets/art/characters/npc_marquis_renard.png`: 후작 후보 르나르 초상화
- `res://assets/art/characters/npc_marquis_dorian.png`: 후작 후보 도리앙 초상화
- `res://assets/art/characters/npc_duke_everard.png`: 공작 후보 에버라드 초상화
- `res://assets/art/characters/npc_duke_severin.png`: 공작 후보 세브린 초상화
- `res://assets/art/characters/npc_duke_cassian.png`: 공작 후보 카시안 초상화
- `res://assets/art/characters/npc_maid_ella.png`: 하녀 엘라 초상화
- `res://assets/art/characters/npc_rival_celina.png`: 사교 라이벌 셀리나 초상화
- `res://assets/art/characters/silhouettes/candidate_*_silhouette.png`: 미사용 후보 실루엣 보존본
- `res://assets/art/characters/spouse/*_spouse_affectionate.png`: 배우자 애정 상태 초상화
- `res://assets/art/characters/spouse/*_spouse_suspicious.png`: 배우자 의심 상태 초상화
- `res://assets/art/characters/spouse/*_spouse_weakened.png`: 배우자 쇠약 상태 초상화

UI 이미지는 `ResourceLoader.load()`로 Godot import 리소스를 읽는다. 이 방식은 `res://` 원본 파일 직접 접근에 의존하지 않아 export 빌드에서도 동작한다.
NPC 기본 초상화는 `data/characters/npcs.json`의 `portrait` 필드를 통해 인물/후보 화면에서 공유한다. 배우자 화면은 `spouse_portraits` 필드와 배우자 상태값으로 사용할 이미지를 고른다.

## 기본 플레이 루트

```text
대시보드
-> 자유행동: 소문 조사로 기사 후보 발견
-> 자유행동: 잡일과 심부름/훈련/휴식으로 자금과 스탯 준비
-> 페르소나: 순진한 보호대상 등 상황에 맞는 이미지 선택
-> 후보: 아드리엔 경과 맞선 시작
-> 맞선: 선택지를 골라 레이더 축 조정
-> 결혼식: 검소한 결혼식 이상 진행, 결혼식 결과 이벤트 확인
-> 배우자 대시보드에서 배우자 상태와 결혼식 결과 확인
-> 결혼 생활 행동으로 정보/의심/금슬 조정
-> 처리: 사고사 위장 또는 다른 정치처리 선택, 성공 결과/예상 대응/위험 경고 확인 후 2단계 실행
-> 은폐/후폭풍: 사망 사건은 은폐, 비치명 처리는 정치 후폭풍으로 위험 관리
```

## 후보군 데이터 기준

- `candidate_profiles.json`에는 현재 18명의 비왕족 결혼 후보가 있다.
- 계급별 수량: 기사 3명, 남작 3명, 자작 3명, 백작 3명, 후작 3명, 공작 3명.
- 왕족 후보는 엔드게임용으로 별도 설계가 필요해 이번 최소 3명 규칙에서 제외한다.
- 기사/남작/자작/백작/후작/공작 후보는 실제 초상화를 사용한다.
- 각 후보는 `motivation_ko`, `pressure_ko`, `weakness_hint_ko`, `spouse_dynamic_ko`로 혼인 동기, 가문 압박, 약점 단서, 결혼 후 관계 긴장을 가진다.
- 결혼식 결과 이벤트는 `marriage_config.json`의 `wedding_result_events`에서 예식 옵션, 후보 작위, 후보 `special_traits`를 기준으로 가장 높은 우선순위 항목을 선택한다.
- 결혼 후에는 `special_traits` 조합에 따라 헌신적 동행, 저택 사정 파악, 공개 금슬 연출 행동에 추가 효과와 반응 문구가 붙는다.
- 결혼 후 배우자 화면의 가문 카드는 `faction`, `family_scrutiny`, `security_level`, `pressure_ko`, `weakness_hint_ko`, `special_traits`로 가문명, 감시 수준, 보안 수준, 관리 단서, 주변 인물/감시망을 요약한다.
- 제거/정치처리 대응 이벤트는 `removal_methods.json`의 `counter_events`에서 방식의 `countered_by`, 후보 `special_traits`, 배우자 상태값을 기준으로 가장 높은 우선순위 항목을 선택한다.
- 제거/정치처리 성공 결과는 `success_result`를 따른다. `widow: true`는 미망인 사건 파일, `widow: false`는 정치 후폭풍 파일을 만들며 반복 미망인 페널티를 발생시키지 않는다.
- 제거/정치처리는 위험도 점수, 미망인/비미망인 결과, 예상 대응 여부를 경고 카드로 요약하고 첫 클릭은 확인, 두 번째 클릭은 실행으로 처리한다.

## 조작 피드백 규칙

- 모든 일반 버튼은 누르는 순간 색상 압축과 짧은 모바일 진동으로 입력 수신을 알린다.
- 한 행동에서 발생한 여러 스테이터스 변화는 `GameState.apply_effects()` 단위로 묶어 우측 상단 토스트 하나에 표시한다.
- 이로운 변화, 불리한 변화, 혼합 변화는 각각 녹색, 적색, 황색으로 구분한다. 피로·스트레스·의심·위험 계열은 감소가 이로운 변화다.
- 행동/작전/맞선/은폐/제거 결과는 상단 중앙 배너와 짧은 화면 플래시로 성공·실패·경고를 구분한다.
- 후보 발견, 아이템 획득, 혼인 성립은 일반 수치 변화보다 강한 발견·보상·마일스톤 피드백을 사용한다.
- 일반 화면 전환은 짧은 페이드·슬라이드로 새 화면 진입을 알리고, 맞선 화면은 기존 전용 전투 진입 연출을 유지한다.
- 공통 렌더링은 `scripts/ui/UiFeedbackLayer.gd`, 이벤트 발생과 수치 변화 묶음 처리는 `scripts/autoload/GameState.gd`가 담당한다.

## 달력과 시간 경과 연출

- 기존 52주 단위 진행과 나이 계산은 유지하고, 52주를 12개월에 균등 배분해 주차에서 `제N년 N월`을 계산한다.
- 달력은 별도 세이브 필드를 사용하지 않으므로 기존 저장 데이터도 현재 `week` 값만으로 동일한 날짜를 복원한다.
- 일반 화면 상단 우측 금장 패널에는 현재 연·월, 전체 주차, 나이를 상시 표시한다.
- 맞선 전용 화면에서는 라운드 헤더에 현재 연·월을 함께 표시한다.
- 월이 바뀌면 청색 계열의 `시간이 흐릅니다`, 연도가 바뀌면 금색 계열의 `새로운 해` 중앙 연출을 표시한다.
- 한 행동이 여러 달을 건너뛰면 중간 월을 연속 재생하지 않고 최종 도착 월과 경과 주 수를 한 번에 보여준다.
- 달력 계산과 경계 감지는 `scripts/autoload/TimeManager.gd`, 연출은 `scripts/ui/UiFeedbackLayer.gd`가 담당한다.

## 핵심 자원 HUD

- 일반 헤더 문장에 섞여 있던 자금과 피로를 독립된 상시 자원 카드로 분리한다.
- 플레이어의 실제 행동 제약 수치는 피로이므로, 체력 HUD는 `100 - 피로`를 행동 여력으로 표시하고 실제 피로도도 보조 문구로 함께 보여준다.
- 체력은 0~100 게이지와 양호·주의·위험 색상으로 표시한다.
- 재화는 상한이 없으므로 게이지 대신 큰 현재값과 부족·주의·사용 가능 상태를 표시한다.
- 자금과 체력이 바뀌면 카드 테두리, 숫자 색상, 확대 펄스와 `+/- 변화량`을 함께 표시한다.
- 맞선 전용 화면에서는 일반 HUD 대신 플레이어 전투 패널에 체력 게이지와 재화를 표시한다.
- 공통 자원 카드는 `scripts/ui/ResourceHudCard.gd`, 상태 연결과 반응형 배치는 `scripts/ui/Main.gd`가 담당한다.

## 검증 상태

### 2026-07-29 인물 상호작용·Windows 내보내기 개선

- `Main.gd`의 인물 목록·필터·행동 UI를 `CharactersScreen.gd`로 분리했다.
- 대화, 후보 정보 구입, 견제 완화는 `ActionResolver.run_action()`을 통해 1주와 피로/자원 비용을 사용하며 관계 효과도 공통 적용한다.
- 거래 버튼은 상점 화면만 열고 관계 보상을 만들지 않는다.
- Godot 4.7에서 메인 씬 실행과 `Smoke*.gd` 12개 전체 통과를 확인했다.
- `CaptureUi.gd`를 Windows GL Compatibility 렌더러로 실행해 38개 UI 캡처를 모두 재생성했고 대시보드 일정과 응접실 교섭 배치를 확인했다.
- `Windows Desktop` 릴리스 프리셋으로 `build/windows/MarriageIntrigue.exe`를 생성하고 `--headless --quit-after 60` 기동 종료 코드 0을 확인했다.
- `CaptureUi.gd`는 `--headless` dummy 렌더러에서는 viewport texture가 없어 캡처할 수 없다. 실제 캡처 검증에는 Windows display driver를 사용한다.

### 2026-07-19 구조 개선

- `ProgressionOverview.gd`가 목표 문구, 보조 힌트, 진행률, 다음 행동 ID와 버튼 문구를 하나의 스냅샷으로 계산한다. 대시보드 상세 진행과 전략 현황판은 같은 값을 사용한다.
- 전략 현황판은 생성 시점의 열 수를 고정하지 않고 창 크기 변경 신호에 반응해 같은 인스턴스를 3열·2열·1열로 다시 배치한다.
- 현황판의 인맥 수는 전체 관계 데이터가 아니라 현재 주차에 실제 접근 가능한 NPC만 집계한다.
- 맞선 시작·턴 기록·결과 확정·결혼 완료·배우자 제거·페르소나 변경은 `GameState`의 전이 API를 통해 상태 동기화와 `state_changed` 신호를 보장한다.
- 토스트 종료 콜백은 약한 참조를 사용해 연속 알림 제한으로 먼저 제거된 패널을 다시 참조하지 않는다.
- 프로젝트 스트레치 모드를 비활성화해 820px·640px 창에서 1280px 캔버스를 축소하지 않고 실제 글꼴·버튼 크기를 유지한다.
- 대시보드 소개 카드는 520px까지 가로 구성을 유지해 세로 공간을 절약하고, 공통 카드 행과 스탯 그리드는 창 크기 변경 시 같은 인스턴스에서 즉시 재배치된다.
- 전략 현황판에는 상태 배지, 카드별 색상 강조선, 전용 진행 게이지와 브리핑 패널을 적용하고 컴팩트·모바일 로그 높이를 줄여 본문 가시 영역을 확대했다.
- UI 캡처는 화면 전환 애니메이션이 끝난 뒤 저장해 최종 명도와 배치를 검수한다.

- `res/data/**/*.json`은 PowerShell `ConvertFrom-Json` 기준으로 파싱 검증 완료.
- Godot 4.6.3 headless 기준 프로젝트 로딩 검증 완료.
- Godot 4.6.3 headless 기준 메인 씬 1초 실행 검증 완료.
- 저장/로드 스모크 테스트에서 결혼식 결과 이벤트 선택, 플래그 저장, 배우자 수치 변화 검증 완료.
- 저장/로드 스모크 테스트에서 작위 압박 이벤트 선택, 효과 플래그 저장, 다음 작위 후보 해금 검증 완료.
- 저장/로드 스모크 테스트에서 제거/정치처리 대응 이벤트 선택, 배우자 위험 변화, 사건 파일 반영 검증 완료.
- 저장/로드 스모크 테스트에서 비치명 정치처리 결과 타입, 비미망인 플래그, 정치 후폭풍 파일 생성 검증 완료.
- 처리 화면 UI 캡처에서 위험 경고 카드와 2단계 확인 버튼 표시 검수 완료.
- 작은 창 UI 캡처에서 후보, 처리, 정치 후폭풍 화면의 세로 배치와 버튼 줄바꿈 검수 완료.
- 인물 역할군 필터와 후보 작위/정보/난도/보안 정렬 UI 캡처 검수 완료.
- 640px 모바일 UI 캡처에서 대시보드, 후보, 맞선, 배우자 화면의 여백/헤더/카드/로그 패널 배치 검수 완료.
- 2026-07-15 Godot 4.6.3 headless 프로젝트 로딩과 메인 씬 1초 실행 재검증 완료.
- 대사 단계 자동 성장, 페르소나 주간 유지비, 30세 페널티, 35세 종료 조건 스모크 테스트 완료.
- 이미지 로딩을 `ResourceLoader` 기반으로 변경한 뒤 메인 씬 실행 시 export 비호환 경고가 사라지는 것을 확인.
- 2026-07-17 Godot 4.6.3 headless에서 기존 7개 스모크 테스트와 `SmokeFlowInvariants.gd` 회귀 테스트 통과.
- 2026-07-19 `SmokeStrategicOverview.gd`와 1280/820/640px 실제 UI 캡처로 전략 현황판 반응형 배치 검증 완료.
- 2026-07-19 전체 9개 스모크 테스트와 37개 UI 캡처를 재실행해 모두 통과. 캡처 로그에서 해제 객체 참조 오류가 발생하지 않음을 확인.

## 기사 맞선 튜토리얼 밸런스

- 기사 계급의 성공 기준은 50점이며, 호감·흥미·신뢰·편안함만 치명적 실패 축으로 사용한다.
- 체면과 정치 가치는 기사 맞선에서 낮은 가중치로 반영되어 사교·예법·정치 능력의 초반 부담을 줄인다.
- 거친 초기 페르소나와 말투 때문에 핵심 감정 축이 바닥나지 않도록 기사 맞선 시작 시 최소치를 보장한다.
- 준비 보너스는 후보가 선호하는 능력치 중 가장 강한 2개를 중심으로 계산한다.
- 후보의 취향 태그와 일치하는 선택지는 긍정 효과가 커지고 부작용이 줄어든다.
- 남작 이상 계급은 기존 62점 기준과 전 축 치명적 실패 규칙을 유지한다.
