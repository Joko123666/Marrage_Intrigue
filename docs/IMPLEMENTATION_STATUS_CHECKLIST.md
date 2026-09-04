# 구현 현황 체크리스트

기획 문서와 별도로 실제 구현 상태를 추적하는 파일이다. 새 기능을 구현하거나 범위를 바꿀 때 이 파일을 갱신한다.

상태 표기:

- `[x]` 구현됨
- `[~]` 부분 구현
- `[ ]` 미구현

마지막 갱신: 2026-09-01

## 요약

```text
구현됨: 프로젝트 부트스트랩, JSON 로딩, 런타임 상태, 시간 진행, 자유행동, 상점,
        인물/관계 기본 상호작용, 페르소나 선택, 소문 작전, 후보 발견,
        맞선, 결혼, 배우자 대시보드, 제거/정치처리, 은폐 사건 파일,
        기본 UI 테마와 생성 이미지 에셋, NPC/후보/배우자 초상화,
        배우자 상태별 초상화 전환, 왕족 제외 계급별 후보 3명 구성,
        왕족 제외 결혼 후보 실제 초상화, 후보별 입체 설정 필드,
        중세풍 UI 장식 에셋, 맞선 레이더 그래픽, 저장/불러오기,
        자동 저장, 저장 슬롯, 런타임 데이터 마이그레이션,
        기본 작위 상승 후보 루프, 대시보드 상태 요약,
        대사 단계 자동 성장과 맞선 보정, 페르소나 주간 유지비,
        30세 혼인 시장 압박과 35세 종료 조건, Windows 릴리스 내보내기

부분 구현: 상황별 대사/행동 페르소나 보정, 후보 정보 품질 세부 공개,
          라이벌 소문전, 튜토리얼 수직 절편의 성공/실패 연출,
          UI 검수/레이아웃 안정화, 모바일 대응, 작위별 중후반 루프

미구현: 남은 화면별 독립 스크립트 분리, 범용 이벤트 시스템,
        CI 기반 테스트 자동화
```

## Phase 0. Godot 프로젝트 부트스트랩

- [x] Godot 4.7 프로젝트 설정
- [x] `project.godot` 메인 씬 설정
- [x] `DataManager`, `GameState`, `TimeManager`, `ActionResolver` Autoload 등록
- [x] `scenes/main/Main.tscn` 생성
- [x] JSON 전체 파싱 검증
- [x] Godot headless 프로젝트 로딩 검증

구현 위치:

- `project.godot`
- `scenes/main/Main.tscn`
- `scripts/autoload/*.gd`

남은 작업:

- [ ] 릴리즈용 프로젝트 설정 정리
- [x] 기본 해상도/스케일 정책 명시

## Phase 1. 1주 단위 시간/자유행동

- [x] 1주 단위 시간 진행
- [x] 52주 경과 시 나이 증가
- [x] 30세부터 맞선 준비 보너스에 연령 페널티 적용
- [x] 35세 도달 시 연령 한계 게임오버 처리
- [x] `free_actions.json` 기반 행동 목록 표시
- [x] 행동 요구조건/비용/효과 처리
- [x] 피로/스트레스 비용은 100 초과 여부로 제한
- [x] 행동 로그 표시
- [x] 행동별 생활 서술·최종 변화·경과 주차를 묶은 육성 결과 장면
- [x] 능력/컨디션 기반 현재 수행감과 최종 예상 효과 표시
- [x] 육성 결과용 거울방·서재·시장 골목 배경 3종과 행동별 데이터 매핑
- [x] 결과 패널 수명과 독립된 배경 정착 애니메이션
- [x] 대시보드 헤더에 주차/나이/자금/피로 표시

구현 위치:

- `scripts/autoload/TimeManager.gd`
- `scripts/autoload/ActionResolver.gd`
- `scripts/ui/Main.gd::_show_free_actions`
- `data/time/free_actions.json`

남은 작업:

- [x] 자유행동 카테고리 필터
- [ ] 행동별 성공/실패 판정이 필요한 행동 분리
- [x] 최대 3개 장기 행동 예약/취소/일괄 실행 UI
- [x] 일정 실행 중 주차별 화면 재생성을 억제하고 완료 후 한 번만 갱신

## Phase 2. 대사 단계/페르소나

- [x] `dialogue_stages.json`, `personas.json`, `choice_tags.json` 로드
- [x] 현재 대사 단계/페르소나 표시
- [x] 페르소나 선택 UI
- [x] 페르소나 해금 조건 일부 적용
- [x] 페르소나 맞선 축 보정 적용
- [x] 대사 단계 표시명 변환
- [x] 스탯과 결혼/미망인/작위 조건 기반 대사 단계 자동 성장
- [x] 대사 단계 맞선 축 보정 적용
- [x] 대사 템플릿 선택 함수
- [~] 상황별 대사 출력
- [x] 페르소나 유지 비용 주간 적용
- [ ] 행동별 페르소나 보정 전면 적용

구현 위치:

- `scripts/ui/Main.gd::_show_personas`
- `scripts/ui/Main.gd::_apply_persona_axes`
- `scripts/autoload/GameState.gd::evaluate_voice_stage`
- `scripts/autoload/GameState.gd::apply_persona_maintenance`
- `data/player/personas.json`
- `data/player/dialogue_stages.json`
- `data/player/dialogue_templates.json`

## Phase 3. 캐릭터/관계 시스템

- [x] `npcs.json` 로드
- [x] 인물 목록 UI
- [x] 관계 축 런타임 초기화
- [x] 관계 변화 API
- [x] 대화/거래/후보 정보 구입/라이벌 견제 완화 버튼
- [x] 관계 변화 로그
- [x] NPC 역할명 한글 표시
- [~] 관계 축 요약 표시
- [x] NPC별 초상화
- [x] 대화/후보 정보 구입/견제 완화를 1주·피로·자원 비용 행동으로 통합
- [x] 인물 행동의 관계 효과를 `ActionResolver` 공통 처리로 연결
- [x] 거래 화면 열기만으로 관계가 상승하던 반복 보상 제거
- [ ] 선물 행동
- [ ] 소문전 전용 상호작용
- [ ] NPC 상세 화면
- [ ] 관계 축별 실제 판정 보정 전면 적용

구현 위치:

- `scripts/autoload/GameState.gd::relationships`
- `scripts/ui/screens/CharactersScreen.gd`
- `scripts/autoload/ActionResolver.gd::apply_action_relationship_effects`
- `data/characters/npcs.json`

## Phase 4. 상점/아이템

- [x] `items.json` 로드
- [x] 상점 UI
- [x] 구매 조건/가격/인벤토리 처리
- [x] 장착 슬롯 처리
- [x] 장착 시 효과 적용
- [x] 장착 해제
- [x] 같은 슬롯 교체 시 이전 효과 제거
- [x] 수치 경계에서 실제 적용된 장비 효과만 해제하고 저장/복원
- [~] 슬롯명 한글 표시
- [x] 일부 아이템 효과는 카운터로 저장 및 판정 참조
- [x] 아이템 효과가 행동/맞선/은폐 전반에 보정으로 연결
- [x] 아이템 보유/장착 상태 전용 UI

구현 위치:

- `scripts/ui/Main.gd::_show_shop`
- `scripts/autoload/GameState.gd::inventory`
- `scripts/autoload/GameState.gd::equipped`
- `data/shop/items.json`

## Phase 5. 소문 조사/유포

- [x] `rumor_actions.json` 로드
- [x] 소문 주제 목록 UI
- [x] 탐문/씨앗 뿌리기/소문 희석 실행
- [x] 성공/실패 판정
- [x] 성공/실패 효과 적용
- [x] 탐문 성공 시 후보 정보 품질 상승
- [x] 데이터에 지정된 대상 NPC 관계 효과 적용
- [ ] 소문 주제 선택 후 작전 대상 지정
- [~] 소문전 결과가 대상 NPC 관계에 직접 누적
- [ ] 소문 위험 이벤트

구현 위치:

- `scripts/ui/Main.gd::_show_rumors`
- `scripts/ui/Main.gd::_run_rumor_operation`
- `scripts/autoload/ActionResolver.gd::run_operation`
- `data/rumors/rumor_actions.json`

## Phase 6. 후보 색출/정보 품질

- [x] `candidate_profiles.json` 로드
- [x] 후보 목록 UI
- [x] 후보 발견 상태 저장
- [x] 정보 품질 수치 저장
- [x] 왕족 제외 계급별 최소 3명 후보 데이터
- [x] 현재 접근 조건 기반 후보 해금
- [x] 정보 품질 30 이상 필드 공개
- [x] 정보 품질 60 이상 필드 공개
- [x] 정보 품질 85 이상 약점/비공개 단서 공개
- [x] 맞선 시작 최소 조건 판정
- [~] 정보 품질 0/90 단계 전체 필드 공개 세분화
- [ ] 맞선 요청 거절 이벤트
- [ ] 거절 시 준비 기간 손실
- [~] 후보별 접근권/작위 시장 제한

구현 위치:

- `scripts/autoload/GameState.gd::known_candidates`
- `scripts/ui/Main.gd::_show_candidates`
- `data/characters/candidate_profiles.json`

## Phase 7. 맞선 레이더 시스템

- [x] 6축 막대 UI
- [x] 맞선 선택지 표시
- [x] 선택지 숫자 스탯 요구치를 잠금 대신 효과 감소/역효과로 처리
- [x] 플래그·자원·서사 조건용 최소 하드 잠금 경로 분리
- [x] 선택지 효과로 축 변화
- [x] 제한 턴 진행
- [x] 축 가중 평균 성공 판정
- [x] 치명 축 낮음 실패 조건
- [x] 페르소나 보정 적용
- [x] 후보 선호 스탯 기반 준비 보너스 적용
- [x] 아이템 보정 반영
- [x] 실제 레이더 차트/6각형 그래프
- [x] 대사 템플릿 출력
- [x] 후보별 고유 선택지
- [x] 실패 사유 상세 표시
- [x] 혼인/결혼식 대기/사건/게임오버 중 중복 맞선 진입 차단
- [x] 화면 예측과 최종 판정이 동일한 준비 보너스 계산 사용
- [x] 선택지 카드에 `충분`/`효과↓`/`역효과`와 조정된 실제 예상 효과 표시
- [x] 선택지 숙련 상태별 주인공 대사·상대 반응·이전 화제 결과 표시
- [x] 40% 경계의 긍정 효과 0 완충과 맞선 중 능력치 변경 시 카드 자동 재계산
- [x] 기사 핵심 후보 3명의 관망/호의/경계 초상 전환과 미보유 후보 기본 초상 폴백
- [x] 동일 화제 반복 이력 저장과 2회째 이후 효과 감쇠·흥미/안심/신뢰 하락
- [x] 반복 단계별 선택지 사전 경고·주인공 대사·후보 지루함 반응
- [x] 기사 맞선 밸런스를 단일 화제 연타 실패·4종 이상 화제 조합 성공 기준으로 회귀 검증

구현 위치:

- `scripts/ui/Main.gd::_show_match`
- `scripts/ui/Main.gd::_start_match`
- `scripts/ui/MatchRadarChart.gd`
- `scripts/ui/Main.gd::_finish_match`
- `data/match/match_config.json`

## Phase 8. 결혼/배우자 대시보드

- [x] 결혼식 옵션 UI
- [x] 결혼식 비용/효과/시간 처리
- [x] 배우자 상태 생성
- [x] `married`, `entered_nobility`, `access_to_household`, `available_event` 플래그 설정
- [x] 배우자 대시보드 표시
- [x] 건강/애정/직접의심/경계도/공개금슬 표시
- [x] 배우자 상태별 초상화 선택
- [x] 결혼 생활 행동 3종
- [x] 배우자별 고유 성향/반응
- [x] 배우자 주변 인물/가문 표시
- [x] 결혼식 결과 이벤트
- [x] 후보 목록의 최소 결혼 준비금·현재 자금 사전 안내

구현 위치:

- `scripts/ui/Main.gd::_show_wedding`
- `scripts/ui/Main.gd::_run_wedding`
- `scripts/ui/Main.gd::_show_spouse`
- `scripts/ui/Main.gd::_add_spouse_actions`
- `scripts/autoload/GameState.gd::create_spouse_from_candidate`
- `scripts/autoload/GameState.gd::apply_wedding_result_event`
- `data/marriage/marriage_config.json`

## Phase 9. 제거/정치처리 MVP

- [x] `removal_methods.json` 로드
- [x] 제거/정치처리 방식 목록 UI
- [x] 요구조건 표시
- [x] 기본 성공률/위험 프로필 표시
- [x] 준비 주 경과
- [x] 성공/실패 판정
- [x] 실패 시 직접의심/경계도/사회적 의심 상승
- [x] 성공/실패 후 사건 파일 생성
- [~] 성공 시 배우자 제거와 남작 후보 접근 일부 연결
- [x] 제거 방식별 구체적 카운터/대응 이벤트
- [x] 비치명 정치처리 결과 분기
- [x] 윤리/위험 경고 UX

구현 위치:

- `scripts/ui/Main.gd::_show_removal`
- `scripts/ui/Main.gd::_add_removal_warning`
- `scripts/ui/Main.gd::_confirm_or_run_removal`
- `scripts/ui/Main.gd::_run_removal`
- `scripts/autoload/GameState.gd::select_removal_counter_event`
- `scripts/autoload/GameState.gd::apply_removal_counter_event`
- `scripts/autoload/GameState.gd::create_case_from_removal`
- `scripts/autoload/GameState.gd::removal_result`
- `data/removal/removal_methods.json`

## Phase 10. 은폐 사건 파일

- [x] `coverup_actions.json` 로드
- [x] 사건 파일 UI
- [x] 조사 진행도/소문 확산도/증거 위험도/알리바이/공개 애도 표시
- [x] 매주 위험 자동 증가
- [x] 은폐 행동 효과 적용
- [x] 게임오버 플래그 처리
- [x] 은폐 행동 성공/실패 판정 분리
- [x] 사건 종결 조건
- [x] 범인 지목 이벤트
- [x] 게임오버 화면
- [x] 반복 미망인 이미지 페널티
- [x] 재혼과 반복 사건 시작 시 현재 회차 플래그 초기화

구현 위치:

- `scripts/ui/Main.gd::_show_coverup`
- `scripts/autoload/GameState.gd::active_case`
- `scripts/autoload/GameState.gd::on_week_elapsed`
- `data/coverup/coverup_actions.json`

## Phase 11. 기사 튜토리얼 수직 절편

- [x] 시작 상태
- [x] 자유행동
- [x] 기사 후보 발견
- [x] 맞선
- [x] 결혼
- [x] 배우자 대시보드
- [x] 처리/은폐
- [x] 남작 후보 접근권 일부 해금
- [~] 처음부터 끝까지 플레이 가능한 흐름은 있으나 밸런스/연출 검증 필요
- [x] 성공/실패/위험 상승 경험의 기본 안내 로그
- [x] 튜토리얼 단계별 목표 UI
- [x] 단계 완료 체크 표시
- [x] 첫 실패/첫 위험 상승을 안내하는 이벤트
- [x] 수직 절편 완료 화면

구현 위치:

- `scripts/systems/ProgressionOverview.gd`
- `data/tutorial/tutorial_flow.json`

## Phase 12. 작위별 중후반 압박 이벤트

- [x] `rank_events.json` 로드
- [x] 결혼 이후 주차 진행 중 작위 이벤트 검사
- [x] 배우자 작위 기반 이벤트 선별
- [x] 후보 특성 일치도 기반 우선순위 보정
- [x] 이벤트 중복 발동 방지 플래그
- [x] 이벤트 효과 적용
- [x] 이벤트 기반 다음 작위 후보 정보 해금
- [x] 대시보드/배우자 화면 최근 작위 압박 표시
- [x] 저장/로드 스모크 테스트 검증
- [~] 계급별 수치 강도 장기 플레이 밸런스 검수

구현 위치:

- `data/nobility/rank_events.json`
- `scripts/autoload/DataManager.gd`
- `scripts/autoload/GameState.gd::select_rank_pressure_event`
- `scripts/autoload/GameState.gd::apply_rank_pressure_event`
- `scripts/ui/Main.gd::_add_rank_event_summary`
- `scripts/tools/SmokeSaveLoad.gd`

## Phase 13. 화면 스크립트 분리

- [x] `scripts/ui/screens/` 디렉터리 생성
- [x] 대시보드 본문을 `DashboardScreen.gd`로 분리
- [x] 자유행동 본문을 `FreeActionsScreen.gd`로 분리
- [x] 상점 본문을 `ShopScreen.gd`로 분리
- [x] 인물 본문을 `CharactersScreen.gd`로 분리
- [x] 맞선 전용 본문을 `MatchBattleScreen.gd`로 분리
- [x] `Main.gd`는 분리된 화면의 라우팅 래퍼만 유지
- [x] 대시보드/자유행동/상점 캡처 회귀 확인
- [~] 후보 화면 분리
- [~] 배우자/처리/은폐 화면 분리

구현 위치:

- `scripts/ui/Main.gd`
- `scripts/ui/screens/DashboardScreen.gd`
- `scripts/ui/screens/FreeActionsScreen.gd`
- `scripts/ui/screens/ShopScreen.gd`
- `scripts/ui/screens/CharactersScreen.gd`
- `docs/PROJECT_STRUCTURE.md`
- `docs/GODOT_PROJECT_STRUCTURE.md`

## UI/비주얼 구현 현황

- [x] 주인공 생활 화면·월간 목표·3칸 일정·능력 장부·하단 행동 리본으로 대시보드 재구성
- [x] 양피지 장부형 공통 날짜·자금·체력 헤더
- [x] 응접실 인물 중심 교섭 화면과 핵심 관계 리본 표현
- [x] 생성 이미지 배경
- [x] 중세풍 UI 구분선/카드 트림/질감 오버레이
- [x] 주인공 초상화
- [x] 반투명 카드 패널
- [x] 버튼 스타일
- [x] 현재 내비게이션 강조
- [x] 핵심 상태 카드
- [x] 대시보드 현재 상태 요약/경보/추천
- [x] 상태·현재 목표·후보/인맥/보유품 정보를 묶은 전략 현황판
- [x] 전략 현황판의 목표별 화면 바로가기와 3열/2열/1열 반응형 배치
- [x] 목표 문구·힌트·진행률·버튼을 단일 진행 스냅샷으로 통합
- [x] 창 크기 변경 중 같은 현황판 인스턴스의 3열/2열/1열 실시간 재배치
- [x] 전체 관계 수 대신 현재 주차에 접근 가능한 인맥 수 표시
- [x] 작은 창에서 기준 캔버스를 축소하지 않는 실제 픽셀 기반 반응형 UI
- [x] 일반 카드 행·스탯 그리드·대시보드 소개 영역의 실시간 재배치
- [x] 현황판 상태 배지·강조선·진행 게이지·브리핑 카드 시각 위계 강화
- [x] 스탯/위험 카드형 그리드
- [x] 내부 id 한글 표시 일부 변환
- [x] 인물 역할군 필터
- [x] 후보 작위 필터/정렬
- [x] 후보/NPC/배우자 초상화
- [x] 배우자 평상/애정/의심/쇠약 초상화
- [x] 기사 후보 3명 실제 초상화
- [x] 남작 후보 3명 실제 초상화
- [x] 자작 후보 3명 실제 초상화
- [x] 백작 후보 3명 실제 초상화
- [x] 후작 후보 3명 실제 초상화
- [x] 공작 후보 3명 실제 초상화
- [x] 초상화 미생성 후보의 준비중 슬롯
- [x] UI 캡처 도구
- [~] 1280x720 기준 주요 화면 검수
- [x] 모바일/작은 창 대응 확대
- [x] 로그 색상 분류
- [x] 효과/관계 칩 UI
- [x] 맞선 6축 판정은 유지하고 화면은 호감·신뢰·체면·정략 가치 리본과 흥미·안심 보조 지표로 재구성
- [x] 맞선 직전 턴 축별 `▲/▼`, 교섭 흐름 해석, 플레이어 화법·후보 반응 상태 강조
- [x] 맞선 반응 상태에 따른 기사 후보 3명 표정 초상 자동 전환
- [x] 맞선 진입 시 이전 화면 일시 배너 정리
- [x] 일반 화면 전환 시 본문 스크롤 상단 초기화
- [x] 맞선 툴팁·혼인 배너·플래그 요구조건의 내부 id 한글화
- [x] 일정 슬롯의 배우자 처리와 혼동되는 `제거` 표현을 `일정 취소`로 변경

구현 위치:

- `scripts/ui/Main.gd`
- `scripts/ui/StrategicOverviewPanel.gd`
- `scripts/systems/ProgressionOverview.gd`
- `scripts/ui/MatchRadarChart.gd`
- `scripts/tools/CaptureUi.gd`
- `assets/art/*.png`
- `docs/UI_WIREFRAME.md`

## 저장/로드/테스트

- [x] 저장/불러오기
- [x] 자동 저장
- [x] 저장 데이터 슬롯 확장
- [x] 세이브/로드 UI 피드백 강화
- [x] 런타임 데이터 마이그레이션
- [~] 단위 테스트 또는 검증 씬
- [x] JSON 파싱 수동 검증
- [x] Godot headless 로딩 검증
- [x] Godot 1초 실행 검증
- [x] 대사 단계 성장/페르소나 유지비/연령 한계 스모크 검증
- [x] 상태 전이/재혼/반복 사건/장비 경계/소문 대상 효과 회귀 검증
- [x] 전략 현황판 상태 전환과 데스크톱/모바일 열 수 회귀 검증
- [x] 배우자 확인→처리 준비 목표 전환과 현황판 CTA 회귀 검증
- [x] 빠른 연속 토스트 제거 후 해제 객체 참조 오류 회귀 검증
- [x] 맞선·결혼·배우자 제거·페르소나 변경을 `GameState` 전이 API로 일원화
- [x] 인물 상호작용 시간·피로·관계 효과와 거래 이동 스모크 검증
- [x] 대시보드 일정 회귀 테스트를 포함한 Godot 4.7 전체 스모크 테스트 12개 일괄 통과
- [x] 숫자 요구 선택지 8개의 네 경계와 대표 선택지 5단계 양방향 전환·저장 왕복 영구 회귀 검증
- [x] Windows Desktop 릴리스 내보내기와 생성 실행 파일 headless 기동 검증
- [x] 실제 자유행동 버튼→결과 장면→화면 재구성 통합 경로 회귀 검증
- [~] UI 캡처 수동 검수

## 우선 구현 권장 순서

1. 후보 화면 스크립트 분리
2. 배우자/처리/은폐 화면 스크립트 분리
3. 세부 밸런스/연출 검수
4. Windows 릴리스 실기기 플레이 검수와 배포 메타데이터 확정
