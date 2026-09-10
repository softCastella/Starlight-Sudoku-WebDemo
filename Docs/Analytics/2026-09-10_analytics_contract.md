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

기능 요소는 `AnalyticsTapRegion`이 `target_id`와 `target_type`을 제공한다. Flutter
Canvas의 장식 요소는 현재 대부분 `target_id=canvas`, `is_interactive=false`로 남기
때문에 화면 단위 Expectation Click은 계산할 수 있지만 캐릭터·로고·램프를 요소별로
구분하는 작업은 후속 보강 범위다. 보강 시에도 기존 버튼 hit test와 게임 입력을
가로채지 않아야 한다.

## Threads 유입 규칙

Threads 게시물은 다음 UTM 규칙을 사용한다.

- `utm_source=threads`
- `utm_medium=organic_social`
- `utm_campaign`: 캠페인 단위의 고정 이름
- `utm_content`: 게시물 또는 소재마다 다른 값
- `utm_term`: 필요한 경우에만 사용

현재 GitHub Pages 주소의 예시:

```text
https://softcastella.github.io/Starlight-Sudoku-WebDemo/landing/?utm_source=threads&utm_medium=organic_social&utm_campaign=starlight_webdemo_launch&utm_content=post_01
```

Landing은 UTM을 sessionStorage에 보존하고 CTA의 WebDemo URL에도 다시 붙인다.
따라서 Landing 조회, CTA 클릭, 퍼즐 시작, 단계 완료, Demo 완료를 같은 유입 문맥으로
집계할 수 있다. Threads 내부 노출·좋아요·플랫폼 링크 클릭 수는 사이트에서 측정하지
않으며 Threads Insights와 별도로 비교한다.

현재 배포에서는 랜딩과 게임이 Tyche 호스트와 `softcastella.github.io`로 나뉠 수
있어, UTM 문맥은 이어지더라도 `anonymous_user_id`가 같은 사용자임을 보장하지
못한다. UTM은 캠페인 구분값이지 사용자 식별자가 아니다.

## 확정한 같은 Origin 공개 구조

목표 공개 주소는 다음과 같다.

```text
https://starlight.tycheworks.com/       랜딩
https://starlight.tycheworks.com/play/  Flutter WebDemo
```

정적 파일은 GitHub Pages에 유지하되 랜딩과 `/play/` 빌드를 하나의 배포 산출물로
합친다. 같은 Origin의 `localStorage`를 사용하므로 랜딩과 게임이 동일한
`anonymous_user_id`를 공유한다. Analytics collector와 관리자 대시보드만 Tyche
서버가 담당하며, collector가 일시적으로 응답하지 않아도 게임 진행은 계속된다.

현재 새 창 CTA에서는 `sessionStorage`의 `session_id`가 새로 만들어질 수 있다.
랜딩부터 게임까지 하나의 방문 세션으로 묶어야 하면 CTA를 같은 탭으로 이동시키거나
짧은 수명의 `journey_id` 쿠키/일회용 token을 별도로 사용한다. 지속 사용자 ID를
URL에 직접 넣지 않는다.

후속 작업 순서는 다음과 같다.

1. Pages workflow에서 랜딩 루트와 Flutter `/play/` 빌드를 하나로 조립한다.
2. Flutter를 `--base-href /play/` 기준으로 빌드하고 자산·새로고침을 검증한다.
3. 랜딩 CTA를 `/play/`로 연결하고 다섯 UTM과 익명 ID 연속성을 검증한다.
4. `starlight.tycheworks.com` custom domain과 HTTPS를 연결한다.
5. 서버 migration, collector CORS/기능 플래그와 보관 정책을 적용한 뒤 제한된
   테스트 트래픽으로 실데이터 전환을 확인한다.

## 현재 측정상의 주의점

- Rage Click은 현재 같은 사용자·화면·target의 2초 내 반복을 판정하는 1차 규칙이다.
- Dwell/Attention은 실제 시선 추적이 아니라 클릭 당시 화면 경과 시간의 가중 표현이다.
- Retry는 `restart` 이벤트로 수집하지만 전용 Heatmap 필터는 아직 없다.
- Landing 실제 화면 캡처는 별도 카탈로그 asset으로 연결해야 한다.
- 공개 실수집은 저장소 기본 설정만으로 활성화되지 않는다.

## 공개 실수집 활성화

Threads 링크를 배포하기 전에 다음을 완료한다.

1. Collector를 공개 HTTPS 주소에 배포한다.
2. Collector의 `STARLIGHT_ANALYTICS_ALLOWED_ORIGINS`에 최종 주소 `https://starlight.tycheworks.com`을 등록한다.
3. 배포용 `analytics-config.js`에 collector URL을 넣고 `enabled: true`로 전환한다.
4. UTM 테스트 링크로 Landing → WebDemo 전환과 대시보드 실데이터 수신을 확인한다.
5. GA4를 사용할 경우 Measurement ID를 배포 설정으로 주입한다.

## 개인정보

가입 정보, IP, 사용자 입력 텍스트를 보내지 않는다. 익명 user ID는 localStorage,
session ID와 UTM 5종은 sessionStorage에 저장한다. GA4에는 주요 퍼널·화면·세션·
engagement 이벤트만 보내고 cell 및 pointer 좌표는 자체 collector에만 보낸다.
