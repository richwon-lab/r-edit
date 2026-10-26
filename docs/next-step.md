> 최신 상태(2026-10-27): [예외·진단·로깅 계약](failure-diagnostics-logging.md)을 적용했다. 아래 2026-10-26 누락/다음 작업은 당시 기록이며 현재 기준은 마지막 절이다.

# 현재 상태와 다음 작업

기록일: 2026-10-26. [공통 개발 기반](development-foundation.md)을 현재 기술 기준으로 따른다.

## 구현한 기반

FVM 4.3.2와 .fvmrc로 Flutter 3.47.7/Dart 3.13.5를 고정했다. 전역 PATH는 바꾸지 않았다.
Riverpod 객체 제공/앱 테마 상태·생성 Provider, go_router의 시작/없는 경로, logging 로컬 로그를 연결했다.
Freezed/json_serializable을 구성했으며 가짜 앱 업무 값 모델은 만들지 않았다.
very_good_analysis 11.0.0과 strict 타입 3종, 로컬 검증·GitHub Actions를 적용했다.
앱 lock·필요한 생성 소스를 관리하고 캐시/빌드/IDE 설정은 제외한다.

## 실제 검증

Windows에서 생성·포맷·최종 재생성 안정성·flutter analyze·위젯 테스트 4개 성공.
flutter build windows --debug 성공.
build/windows/x64/runner/Debug/r_edit.exe를 실행하여 창 제목 R-edit,
중앙 프로그램 이름·한국어 시작 안내를 시각 확인했다. 확인 화면에 잘림/오버플로는 보이지 않았다.
Provider 테마 변경/컨테이너 독립성·경로 복귀·Logger 교체는 테스트로 확인했다.
테마 조작 UI는 없으므로 사용자 조작 화면의 다크 모드 검증으로 보고하지 않는다.
원격 GitHub Actions·Linux 러너는 실행하지 않았다. CI 무료 운용 조건은 공통 기준을 따른다.

초기 2026-10-19 Flutter 3.44.8/Dart 3.12.2의 앱 골격 확인은 과거 기록이다.
이번 검증은 배치·제작·저장·출력 성공이 아니다.
커밋·푸시·기존 스테이징 변경은 하지 않았다.

## 다음 한 가지 작업

workflow의 개별 공개 API 설명 누락 141건을 기존 계약에 맞게 보완한다.
이후 실제 업무 명령과 입력/적용 형상 변경 계약을 확인하고 앱 연결 범위를 별도 결정한다.
앱에는 아직 실제 업무 패키지 연결/명령이 없다.
저장·동기화·검색·출력·3D는 공통 기준의 조건 충족 시 사용자 결정 후 도입한다.

## 생성 소스 검증 보완 (2026-10-26)

시작 생성 소스와 첫 생성 결과의 경로/내용 일치, 반복 생성 안정성을 분리했다.
CI는 생성 소스만 Git과 대조하며 로컬 기본 검증은 HEAD와 비교하지 않는다.
[개발 기준](development-foundation.md)의 생성 소스 검증 계약과 재생성 절차를 따른다.
실제 작업 트리의 전체 verify 성공: 앱 16개·workflow 429개 테스트, workflow AOT 5개·독립 소비자 성공.
workflow 분석의 기존 document_ignores info 1건은 남아 있다. 원격 CI/앱 빌드는 미실행이다.
업무 API/JSON/SDK/의존성·실행 조건을 바꾸지 않았고, 다음 업무 작업 범위도 기존 기록을 유지한다.


## 예외·진단·파일 로그 기반 (2026-10-27)

앱이 로그 구독·레벨·Flutter/Platform/Riverpod 오류 경계와 정상 종료를 소유한다.
AppLogEvent만 영속 기록하며 5MiB × 3슬롯·16KiB/건·64건 큐·OS lock으로 한도를 둔다.
path_provider 2.1.6으로 앱 전용 LocalAppData를 사용한다. 업무 원문·전체 JSON·상태/외부 오류 메시지는 출력하지 않는다.
전체 verify --windows(28개·생성 일치/안정성·분석)와 Windows debug/release 빌드·시작 화면·실제 시작/종료 JSONL을 확인했다.
세 슬롯/네 프로세스 분리·파일 실패 격리·Provider wrapper 중복·초기화/해제는 격리 테스트로 확인했다.
원격 CI/다른 OS·강제 종료 내구성은 미검증이다. 자세한 범위는 위 계약의 결과 절을 따른다.

다음 한 가지 작업은 제품 입력/적용 형상 변경의 안전한 반영 계약을 검토하여 앱에 연결할 첫 실제 명령 범위를 정하는 것이다.
아직 업무 명령·배치·저장·원격 수집·로그 UI는 없다. 공개 설명 141건은 이전 workflow 작업에서 해소됐으므로 다음 작업으로 되살리지 않는다.
