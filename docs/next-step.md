# 현재 상태와 다음 작업

기록일: 2026-10-19, 한국시간.

## 사용자가 확인한 상태

- Flutter 개발 경험이 있고 기본 개발 환경이 준비되어 있다.
- GitHub richwon-lab 조직에 r-edit 저장소를 만들었다.
- IntelliJ IDEA에서 Windows Flutter 앱을 생성하는 설정을 진행했다.
- 로컬 개발 식별자를 r_edit로 통일했다.

## 초기 기본 프로젝트 확인 기록

- Windows Flutter 기본 프로젝트가 생성되어 있다. SDK는 Flutter 3.44.8 stable, Dart 3.12.2다.
- Git은 초기화되어 있고 첫 커밋 준비 시 브랜치는 master, 기존 커밋은 없었다.
- origin은 https://github.com/richwon-lab/r-edit.git 이다. 원격 브랜치·커밋은 조회하지 않았다.
- 기본 앱 코드와 테스트는 수정하지 않았다. README.md, AGENTS.md와 docs 문서를 함께 기록한다.
- flutter analyze: 종료 코드 0, No issues found! (ran in 2.6s).
- flutter test: 종료 코드 0, Counter increments smoke test 1개 통과, All tests passed!.
- flutter run -d windows: 디버그 빌드와 앱 실행, Dart VM Service 연결을 확인한 뒤 앱 프로세스를 종료했다. 화면 조작은 별도로 검증하지 않았다.
- 샌드박스 안에서는 SDK 캐시 잠금 단계에서 출력 없이 대기하여 중단했고, 위 검증은 샌드박스 밖에서 재실행했다.
- 이번 기록은 기본 프로젝트와 개발 문서의 첫 로컬 커밋에 포함한다. Push는 사용자가 IntelliJ에서 진행하며, 원격 반영은 확인하지 않았다.
- 업무 기능은 아직 구현하지 않았다. 표시 이름 R-edit 적용도 후속 작업이며, 현재 생성 코드의 Flutter Demo와 Windows r_edit 표기는 그대로 보존했다.

위 항목은 첫 커밋 당시 기본 템플릿의 기록이다. 현재 상태는 아래 앱 골격 정리 결과를 따른다.

## 현재 앱 골격과 검증

- 시작 시 작업 트리는 깨끗했고 브랜치는 master였다. 이번 작업에서는 커밋·푸시하지 않는다.
- lib/main.dart는 실행만 담당하고, lib/app/r_edit_app.dart의 REditApp이 MaterialApp·테마·StartPage를 연결한다.
- 공통 테마는 lib/app/r_edit_theme.dart, 시작 안내는 lib/app/start_page.dart에 둔다. 카운터 데모와 실행하지 않는 업무 버튼은 없다.
- 앱·창 제목·Windows 제품명·파일 설명은 R-edit, 회사명은 리치원컴퍼니다. 내부 이름과 실행 파일명은 r_edit / r_edit.exe를 유지한다.
- 개발 버전은 0.1.0+1이다. Flutter 3.44.8 stable / Dart 3.12.2와 기존 SDK 제약 ^3.12.2를 유지한다.
- 실제 참조가 없는 cupertino_icons만 제거했다. 새 의존성이나 전체 패키지 업그레이드는 없고 pubspec.lock의 다른 버전도 유지됐다.
- dart format lib test: 성공, Dart 파일 5개 포맷 적용.
- flutter pub get: 종료 코드 0, cupertino_icons 제거만 반영.
- flutter analyze: 종료 코드 0, No issues found! (ran in 2.6s).
- flutter test: 종료 코드 0, R-edit 시작 화면 위젯 테스트 1개 통과.
- flutter build windows --debug: 종료 코드 0, r_edit.exe 생성. 실행 파일 리소스에서 제품명·설명 R-edit, 회사명 리치원컴퍼니, 버전 0.1.0+1, 내부 이름 r_edit를 확인했다.
- flutter run -d windows --no-pub: 빌드·실행과 Dart VM Service 연결 성공. 실제 MainWindowTitle이 R-edit이고 Responding이 True임을 확인한 뒤 q로 정상 종료했다. 네이티브 화면을 직접 시각적으로 확인하지 못했으므로 글꼴·여백·창 크기별 외관 확인은 남아 있다.
- 검증 명령은 SDK 캐시 접근이 가능한 샌드박스 밖에서 실행했다.
- docs/README.md는 현재 존재하지 않는다. 기존 README와 개발 문서의 경로·구조를 유지했다.
- 업무 흐름·배치 엔진·DXF 작성은 아직 구현하거나 연결하지 않았다. 전체 기능 점검이나 과거 시험을 이번 결과로 완료 처리하지 않는다.
- 첫 업무 상태 연결 시 상태 관리 방식을, 저장 모델 구현 시 JSON 코드 생성을 검토한다. 현재는 관련 패키지·빈 계층을 추가하지 않는다.

## 다음 한 가지 구현 작업

앱 초기 연결을 마친 뒤, 별도 r-edit-workflow 저장소에 r_edit_workflow 순수 Dart 패키지를 만든다.
작업 파일·제품·텍스트 영역·줄바꿈 지정·현재 배치 결과·작업자 확인의 최소 모델과 JSON 왕복부터 구현한다.
필드·클래스 이름은 역할을 검토해 정하고, 기존 문서의 영문 예시를 자동 확정하지 않는다.
두 제품의 합성 예제로 원문 공백·직접 지정 한 줄·판정·사유·확인이 보존되는지 확인한다.
합성 결과를 실제 엔진 계산 결과로 표시하지 않는다. 아직 없는 엔진·DXF 저장소의 의존성을 선언하지 않는다.
