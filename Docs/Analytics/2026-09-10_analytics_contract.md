# Starlight Sudoku WebDemo Analytics Contract

Analytics는 게임 로직과 분리된 fire-and-forget 계층이다. `web/analytics.js`가 브라우저
식별자·세션·UTM과 전송 큐를 소유하고 Flutter는 화면 및 게임 문맥만 전달한다.
collector URL이 비어 있거나 요청이 실패해도 게임에는 예외가 전달되지 않는다.

## 런타임 설정

배포 시 `web/analytics-config.js`를 환경별 값으로 교체한다. 저장소의 기본 파일은
collector와 GA4를 비활성 상태(빈 ID/URL)로 둔다.

- `collectorUrl`: 자체 Analytics `POST /api/v1/events/batch`
- `gaMeasurementId`: 선택적 GA4 Measurement ID
- `enabled`: 전체 계측 on/off
- `debug`: 개발자 콘솔 이벤트 로그

## 이벤트

퍼널: `landing_view`, `landing_cta_click`, `game_open`, `game_ready`,
`puzzle_start`, `stage_1_start` … `stage_5_clear`, `demo_complete`,
`store_cta_click`.

상호작용: `cell_select`, `number_input`, `wrong_input`, `erase`,
`memo_toggle`, `memo_input`, `hint_open`, `hint_used`, `restart`, `pause`,
`resume`, `settings_open`, `language_open`, `language_change`, `home_click`,
`next_stage_click`, `village_click`, `store_cta_click`.

수명주기: `screen_view`, `screen_exit`, `session_end`, `game_exit`,
`pointer_tap`.

## 화면과 오버레이

화면: `landing`, `splash`, `opening_1`, `opening_2`, `opening_3`, `title`,
`difficulty`, `stage_select`, `village`, `village_missions`, `game`.

오버레이: `pause`, `settings`, `result`, `demo_complete`. 언어 선택기는 현재
개발용 title dropdown에만 존재하므로 `language_open`/`language_change` 이벤트를
보내며, 정식 모달로 승격할 때 `language` overlay를 연결한다.

## Pointer 좌표

브라우저 capture listener가 모든 pointer down을 잠시 보류한다. Flutter의
`AnalyticsTapRegion`이 80ms 안에 target 문맥을 제공하면 interactive click으로
합쳐지고, 그렇지 않으면 `canvas`의 non-interactive click으로 저장된다. 좌표는
viewport 대비 `x_ratio`, `y_ratio`(0–1)이며 원본 픽셀 좌표는 저장하지 않는다.

## 개인정보

가입 정보, IP, 사용자 입력 텍스트를 보내지 않는다. 익명 user ID는 localStorage,
session ID와 UTM 5종은 sessionStorage에 저장한다. GA4에는 주요 퍼널·화면·세션·
engagement 이벤트만 보내고 cell 및 pointer 좌표는 자체 collector에만 보낸다.
