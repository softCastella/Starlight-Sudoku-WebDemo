# 별빛 스도쿠 — 웹 데모

GitHub Pages 공개 웹 데모 전용 저장소입니다. Easy 5판, `WEB_DEMO=true`.

- 제품 라인: Tyche Spark
- 개발사: Tyche works
- 앱(APK) 저장소: https://github.com/softCastella/Starlight-Sudoku
- 웹 플레이: https://softcastella.github.io/Starlight-Sudoku-WebDemo/
- 랜딩: https://softcastella.github.io/Starlight-Sudoku-WebDemo/landing/
- Google Play 체험판(앱)은 Easy 10판. 이 웹 데모는 Easy 5판입니다.

## 배포

`main`에 푸시하면 Actions가 Flutter 웹 릴리스를 빌드하고 GitHub Pages에 올립니다.

```text
flutter build web --release --base-href "/Starlight-Sudoku-WebDemo/" --dart-define=WEB_DEMO=true
```

랜딩 CTA는 같은 Pages 안의 게임으로 `../?lang=` 상대 경로를 씁니다.

## 로컬

```powershell
flutter pub get
flutter test --dart-define=WEB_DEMO=true
flutter run -d chrome --dart-define=WEB_DEMO=true
```

## 앱과의 관계

- APK·Play·`sample-v1`은 앱 리포 `Starlight-Sudoku`의 `main`만.
- 웹 전용 오디오 스트리밍·유저 ID 없음·5판 데모는 이 리포.
- 공통 UI(모달 여백 등)는 양쪽에서 맞춘 뒤 각각 반영한다.
