# 공식 기술 자료

확인일 2026-10-18. 아래는 기술 사용법의 근거다. 저장소 개수와 업무 경계는 이 프로젝트의 설계 제안이다.

| 내용 | 공식 자료 |
|---|---|
| Flutter 지원 편집기 | https://docs.flutter.dev/tools/editors |
| IntelliJ·Android Studio Flutter 설정 | https://docs.flutter.dev/tools/android-studio |
| Junie IDE 지원·설치 | https://junie.jetbrains.com/docs/junie-ide-plugin.html |
| Junie 프로젝트 Guidelines path | https://junie.jetbrains.com/docs/junie-plugin-project-settings.html |
| Junie AGENTS.md와 기존 형식 | https://junie.jetbrains.com/docs/guidelines-and-memory.html |
| Dart 프로젝트 템플릿 | https://dart.dev/tools/dart-create |
| Flutter 패키지와 플러그인 구분 | https://docs.flutter.dev/packages-and-plugins/developing-packages |
| Git·path 의존성과 로컬 override | https://dart.dev/tools/pub/dependencies |
| 앱 lockfile과 생성 파일 관리 | https://dart.dev/tools/pub/private-files |
| pubspec 이름과 publish_to | https://dart.dev/tools/pub/pubspec |
| 패키지 공개 코드·내부 구현 구조 | https://dart.dev/tools/pub/package-layout |
| Dart 이름과 스타일 | https://dart.dev/effective-dart/style |
| Windows 빌드 환경 | https://docs.flutter.dev/platform-integration/windows/setup |
| Flutter CLI | https://docs.flutter.dev/reference/flutter-cli |

Junie의 현재 IDE 설정은 `AGENTS.md`를 지원한다. 저장소 루트 파일을 만들고 Guidelines path를 명시하는 방식으로 안내했다.
동일한 규칙을 루트와 `.junie/AGENTS.md`에 중복 유지하지 않는다. 현재 공식 문서는 `.junie/AGENTS.md`가 있으면 그 파일을 우선 사용하는 동작을 설명한다.
