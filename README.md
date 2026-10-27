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

프로젝트별 FVM Flutter 3.47.7 / Dart 3.13.5를 사용한다.
[공통 개발 기반](docs/development-foundation.md)에 기술·라이선스·호환성·초기 설치·CI 조건을 기록했다.
IntelliJ Flutter 경로는 .fvm/flutter_sdk, Dart는 그 아래 bin/cache/dart-sdk다.
최초 bootstrap 경로는 실제 설치된 Dart 3.13.5 이상 경로로 바꾼다.

~~~powershell
./tool/fvm.ps1 -BootstrapDart 'C:\개발SDK\bin\cache\dart-sdk\bin\dart.exe' use 3.47.7 --force --skip-pub-get
./tool/fvm.ps1 dart tool/verify.dart --windows
./tool/fvm.ps1 flutter run -d windows
~~~

2026-10-26 생성·포맷·재생성 안정성·분석·위젯 테스트 4개와 Windows debug 빌드가 통과했다.
실제 r_edit.exe의 R-edit 창 제목·한국어 시작 안내를 실행·시각 확인했다.
원격 Actions/Linux 실행은 하지 않았다. 결과·다음 작업은 [현재 상태](docs/next-step.md)를 따른다.
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
현재 의존성·역할은 [공통 기준](docs/development-foundation.md)을 따른다.
앱은 Riverpod ProviderScope 아래 객체 제공/ThemeMode 상태, go_router 시작 경로와 오류 화면,
logging의 개발 콘솔·제한된 로컬 파일 로그를 연결했다. 업무 버튼·엔진·저장 모델은 추가하지 않았다.

| 파일 | 기반 연결 책임 |
|---|---|
| lib/app/providers/app_logger.dart | 앱 Logger 제공 |
| lib/app/providers/app_theme_mode.dart | 앱 표시 테마 상태·변경 로그 |
| lib/app/providers/app_router.dart | 시작/없는 경로·수명 종료 |
| lib/app/logging/app_logging.dart | 로그 수명·전역 오류·Provider 실패·정상 종료 |
| lib/app/logging/app_log_event.dart | 고정 이벤트·안전한 JSONL 레코드 |
| lib/app/logging/rotating_file_log.dart | 크기/버퍼/OS lock을 가진 고정 파일 슬롯 |
| build.yaml | Provider·실제 값 모델 생성 범위 |
| tool/fvm.ps1 / tool/verify.dart | 프로젝트 SDK·공통 검증 |
| .github/workflows/verify.yml | 무료 운용 경계를 둔 CI |

테마 상태는 UI 표시 책임이며 업무 상태가 아니다. 빈 서비스/Repository/DI 계층은 만들지 않았다.
앱 lock·필요한 생성 소스는 추적하고 .fvm/.tooling/build/IDE 설정은 제외한다.
workflow는 독립 저장소의 값·참조 계약을 제공한다. 앱 runtime 연결은 첫 실제 명령 설계 후 수행하며
로컬 형제 경로 의존성·가짜 업무 모델은 추가하지 않았다.
전체 요구사항·논리 설계·검증 근거는 기존 개발 참고자료 묶음을 사용한다.
중앙 문서 저장소 r-edit-docs를 구성하면 채택한 기준 문서 경로와 커밋을 이 문서에 연결한다.
현재는 생성되거나 연결된 것으로 가정하지 않는다.

생성 소스 검증은 시작 상태와 첫 생성 결과의 일치, 반복 생성 안정성을 따로 검사한다.
CI에서는 생성 소스의 Git 포함 상태도 검사하며 로컬 기본 실행은 HEAD와 비교하지 않는다.
실패 후 재생성·검토·재검사 절차와 실제 결과는 [개발 기준](docs/development-foundation.md)의 생성 소스 검증 계약을 따른다.

## 실행 후 로컬 로그

[예외·진단·로깅 기준](docs/failure-diagnostics-logging.md)을 따른다.
Windows의 path_provider Application Cache 아래 logs에 JSONL을 기록한다.
현재 리소스 기준 위치는 %LOCALAPPDATA%\리치원컴퍼니\R-edit\logs다.
활성 파일 포함 총 15MiB(5MiB × 3슬롯)이며 캐시 정리/강제 종료의 마지막 기록 보존은 보장하지 않는다.
파일에는 고정 이벤트·시각·레벨·pid·경과 시간, 원래 오류/wrapper 타입·소스 위치와 처리 경계가 선택한 진단만 기록한다.
업무 원문·전체 상태·외부 오류 메시지·작업 이력은 기록하지 않는다.

PowerShell에서 -d가 공통 Debug 매개변수로 소비되지 않도록 실행 인자를 배열로 전달할 수 있다.
~~~powershell
./tool/fvm.ps1 -FvmArguments @('flutter', 'run', '-d', 'windows')
~~~

## 개발 기반 보완

현재 도구·호환성·명령·검사 범위는 [개발 기반 보완](docs/development-foundation-additions.md)을 따른다.
Flutter 3.47.7/Dart 3.13.5와 기존 Freezed/생성기 기준은 유지한다.
로컬 전체 검증: ./tool/fvm.ps1 dart tool/verify.dart
분석은 --fatal-infos를 사용해 안내 수준의 채택 lint도 실패로 처리한다.
