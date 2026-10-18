# R-edit

명판 문구 배치 및 제작 파일 작성 프로그램. Flutter와 Dart로 개발하는 Windows 데스크톱 앱이다.

## 저장소 역할

이 저장소는 화면, 사용자 입력, 도안 미리보기, 업무 명령 연결과 Windows 연동을 담당한다.
제품 입력·배치 결과 확인·저장 정책, 문구 배치 알고리즘, DXF 작성은 책임별 독립 Dart 패키지로 개발한다.

| 구분 | 식별자 |
|---|---|
| 프로그램 표시 이름 | R-edit |
| 회사명 | 리치원컴퍼니 |
| 초기 개발 버전 | `0.1.0+1` |
| GitHub 저장소 | https://github.com/richwon-lab/r-edit |
| 로컬 프로젝트·모듈·Dart 패키지 | `r_edit` |
| 초기 대상 플랫폼 | Windows |

## 먼저 읽을 문서

1. [개발 지침](AGENTS.md)
2. [현재 결정 사항](docs/decisions.md)
3. [모듈 경계](docs/module-boundaries.md)
4. [현재 상태와 다음 작업](docs/next-step.md)

## 실행과 확인

프로젝트 루트에서 실행한다. Flutter SDK에 포함된 Dart를 사용한다.

```powershell
flutter --version
dart --version
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build windows --debug
flutter run -d windows
```

현재 SDK는 Flutter 3.44.8 stable / Dart 3.12.2이며, 생성 시 Dart 제약 `^3.12.2`를 유지한다.
실제 검증 결과와 확인 범위는 [현재 상태](docs/next-step.md)에 기록한다.
2026-10-19 앱 골격 검증에서 포맷·의존성 갱신·분석·위젯 테스트 1개·Windows 디버그 빌드가 통과했다.
Windows 실행과 실제 창 제목·제품 리소스를 확인했다. 화면 외관의 직접 시각 확인은 남아 있다.

## 현재 개발 범위

현재 앱은 R-edit 제목과 한국어 안내를 표시하는 시작 화면이다. 업무 기능은 아직 없다.

| 파일 | 책임 |
|---|---|
| `lib/main.dart` | 앱 실행 진입점 |
| `lib/app/r_edit_app.dart` | `REditApp`, MaterialApp과 시작 화면 연결 |
| `lib/app/r_edit_theme.dart` | 공통 ThemeData, Windows 한국어 글꼴 맑은 고딕 |
| `lib/app/start_page.dart` | 시작 안내 화면 |

Windows 창 제목·제품명·파일 설명은 R-edit, 회사명은 리치원컴퍼니다.
실행 파일·내부 식별자는 `r_edit`를 유지한다. 버전 리소스는 Flutter의 버전 설정에 연결한다.
의존성은 Flutter와 개발용 flutter_test·flutter_lints만 사용하며 앱의 pubspec.lock을 관리한다.
첫 업무 상태를 연결할 때 상태 관리 방식을, 저장 모델을 구현할 때 JSON 코드 생성을 검토한다.
라우터·DI·코드 생성 패키지나 빈 계층은 미리 추가하지 않는다.

다음 실제 기능은 별도 순수 Dart 패키지의 작업 데이터 모델과 저장 정책부터 구현한다.
아직 생성되지 않은 라이브러리를 pubspec.yaml에 선언하지 않는다.

전체 요구사항·논리 설계·검증 근거는 기존 개발 참고자료 묶음을 사용한다.
중앙 문서 저장소 r-edit-docs를 구성하면 채택한 기준 문서 경로와 커밋을 이 문서에 연결한다.
현재는 생성되거나 연결된 것으로 가정하지 않는다.
