# GitHub Pages 공개 배포 (WebDemo)

## 공개 링크

- 게임: https://softcastella.github.io/Starlight-Sudoku-WebDemo/
- 랜딩: https://softcastella.github.io/Starlight-Sudoku-WebDemo/landing/

## 사용 방법

1. 위 링크를 휴대폰 또는 PC 브라우저에서 연다.
2. 랜딩이면 CTA로 게임에 들어간다. 직접 게임 URL이면 BGM ON/OFF 후 플레이한다.
3. Easy 5판 데모. 이어하기·유저 ID 없음.

## 배포 방식

- 저장소: `softCastella/Starlight-Sudoku-WebDemo`
- 호스팅: GitHub Pages (이 리포의 Pages)
- 배포 브랜치: `main`
- 자동화: `.github/workflows/deploy-pages.yml`
- 빌드: `--base-href "/Starlight-Sudoku-WebDemo/" --dart-define=WEB_DEMO=true`

`main`에 푸시하면 Actions가 웹 릴리스를 빌드하고 Pages에 올린다.

앱 APK는 https://github.com/softCastella/Starlight-Sudoku 의 `main`만.

## 배포 후 확인

1. Actions에서 `Deploy Flutter web to GitHub Pages` 성공
2. 공개 링크를 시크릿 창에서 연다
3. 랜딩 CTA → 같은 오리진 게임 `?lang=`
4. BGM ON, Easy 스테이지, 나가기 문구(저장 안 됨)

## 참고

- 옛 URL `…/Starlight-Sudoku/` 는 앱 리포 Pages이며 더 이상 웹 데모 소스가 아니다.
- 커스텀 도메인 `starlight-sudoku.tycheworks.com` 연결은 추후.
