# 열린 작업과 workflow 편집 세션 연결 계약

현행 구현: 2026-11-01. 2026-10-30의 설계 추천안 중 아래 Provider·명령 기반을 구현했다.
화면·파일 읽기/저장·전체 WorkDocument·탭/에디터·확인 대화상자는 구현하지 않았다.
[공통 기준](development-foundation.md), [개발 기반 보완](development-foundation-additions.md),
[예외·로그 계약](failure-diagnostics-logging.md)을 함께 따른다.

## 실제 패키지 소비

r_edit_workflow를 다음 실제 원격 커밋으로 고정하고 앱 pubspec.lock을 관리한다.
`969253699f28d03db3f2d8d81d5cadad5a6ad5c7`

원격 master 조회와 별도 fetch로 ASCII pubspec·공개 세션 API·생성 소스를 확인했다.
Flutter 3.47.7 / Dart 3.13.5의 새 임시 PUB_CACHE에서 Git 의존성을 해결하고,
생성기 없는 소비자의 open→prepare→apply를 AOT 컴파일·실행했다.
기존 6213a211…의 Windows 한국어 메타데이터 실패는 과거 선행 검증 기록이다.
임시 검증 커밋 ba9f7af…는 앱 의존성으로 사용하지 않는다.

앱은 workflow의 공개 진입점만 import한다. 기본 실행에 형제 폴더가 필요하지 않다.
로컬 override는 만들지 않았으며 최종 검증도 고정 Git 의존성으로 수행한다.
향후 로컬 override가 필요하면 먼저 제외 규칙과 check-ignore를 확인해야 한다.
SDK·기존 도구 버전·CI 권한/실행 조건·workflow 소스는 변경하지 않았다.

## 소유권과 파일 구성

| 파일/타입 | 소유하는 책임 |
|---|---|
| lib/app/work/open_works.dart / OpenWorks | keepAlive 생성 Notifier. private 작업·세션·파일 키 인덱스·확인 대기·선택을 소유 |
| work_execution_ids.dart | OpenedWorkId와 GeometryChangeConfirmationId. private 생성자와 인스턴스 동일성의 실행 토큰 |
| work_file_identity.dart / WorkFileIdentity | 호출자가 제공한 comparisonKey와 originalAccessPath의 불변 값 |
| opened_work_view.dart | Freezed OpenedWorkView / OpenWorksView의 읽기 전용 투영·값 비교·방어 복사 |
| geometry_change_confirmation.dart | 원래 작업/Ready의 private 대기와 공개 정상 결과 타입 |
| open_works.g.dart 및 *.freezed.dart | 공식 생성기가 만든 Git 관리 소스. 직접 편집하지 않음 |

private 접근이 필요한 토큰/확인 결과만 open_works.dart의 part다.
파일 식별 값·관찰값은 독립 library이며 관계없는 앱 모델을 한 library로 묶지 않는다.
추가 Repository·Manager·상태 도구·로그 변환 계층은 없다.

열린 작업 하나가 ProductDesignEditSession 하나를 소유한다.
현재 구성/개정의 정본은 workflow 세션 하나이며 앱이 독자 카운터를 유지하지 않는다.
OpenWorksView는 그 시점의 session.state를 읽은 투영이다. 과거 관찰값은 이후에도 불변이다.
raw 세션 getter·임의 상태 설치·후보 접근·JSON 복원 API는 제공하지 않는다.
Riverpod의 표준 테스트용 provider override는 활성 private 세션의 상태 설치 명령이 아니다.

## 식별 정보의 입력 경계

WorkFileIdentity(comparisonKey:, originalAccessPath:)는 두 필수 문자열이 비면
ArgumentError.value로 인자명·값·위반 조건을 전달한다. 공백·대소문자·Unicode는 보존한다.
comparisonKey는 정확한 문자열 동등성으로만 비교하며 원래 접근 정보는 표시/후속 파일 경계용이다.
이번에는 경로를 해석하거나 소문자화·Unicode 정규화로 동일성을 추정하지 않는다.
이 값이 유효해도 실제 파일의 존재·OS 지원·물리적 동일성이 보장되지 않는다.

실제 Windows 절대경로/UNC·대소문자 구분 디렉터리·장치 경로·별칭/링크·Drive 경로의
지원과 키 생성은 후속 파일 열기 경계에서 결정·검증한다. 이전 설계의 경로 정규화 제안은 구현하지 않았다.
파일명/표시명은 실행 ID가 아니며 같은 파일을 닫고 다시 등록하면 새 작업·새 세션이다.
표시명은 빈 값·중복을 허용하며 trim하지 않는다.

## 공개 명령과 정상 결과

명령은 `container.read(openWorksProvider.notifier)`로 얻는다.
화면은 `openWorksProvider`의 불변 뷰만 관찰하며 세션을 직접 수정하지 않는다.

| 명령 | 입력/결과·보장 |
|---|---|
| registerLoadedWork(fileIdentity:, displayName:, configuration:) | 호출자가 준 유효 ProductDesignConfiguration을 등록하고 OpenedWorkId 반환. 동일 키이면 기존 ID/세션/개정/구성/표시 정보를 유지하고 활성화만 함 |
| activateWork(workId) | 선택만 변경. activated / workNoLongerOpen |
| prepareGeometryChange(workId:, request:) | 특정 세션에서 준비. NeedsConfirmation / Blocked / Unchanged / WorkNotOpen |
| confirmGeometryChange(confirmationId) | 핸들 한 번 소비 후 원래 작업에만 동기 반영. Applied / Rejected / ConfirmationUnavailable |
| cancelGeometryChange(confirmationId) | 대기만 제거. cancelled / confirmationNotPending. 구성·개정·선택 유지 |
| closeWorkAfterDecision(workId) | 닫기 최종 수락 후 호출. session.close→작업/키/관련 대기 제거→최신 관찰 게시. closed / workNoLongerOpen |

이미 폐기된 소유 Notifier에 대한 명령은 StateError다. 내부 결함을 정상 결과로 바꾸지 않는다.
registerLoadedWork는 파일을 읽었다고 가장하지 않는다. 운영용 데모·빈 업무 문서를 공급하지 않는다.

준비의 GeometryChangeNeedsConfirmation은 confirmationId·원래 workId·표시 정보·summary만 공개한다.
Ready와 후보/기준은 private 대기에 남는다. Blocked의 원래 workflow issue·코드·경로·상세는 그대로 보존한다.
Unchanged는 준비 시점의 무변경이며 확인 핸들/과거 baseline 재대입 명령이 아니다.
이 확인은 도안 변경 채택이며 제작 검토/OperatorReview가 아니다.

확인 성공 GeometryChangeApplied의 editState는 해당 호출이 확정한 불변 결과다.
이후 더 최신 화면 상태를 그 결과로 다시 설치하지 않는다.
GeometryChangeRejected의 issues는 workflow가 판단한 정상 반영 거부이며 앱이 세션/개정 비교를 복제하지 않는다.
진단·요약·뷰 목록은 수정 불가다. 원문·Unicode·지정 한 줄/여러 줄·입력 순서는 workflow 그대로 유지한다.

## 동기 반영과 관찰 통지

1. 확인 대기에서 핸들을 먼저 remove한다.
2. 저장한 원래 OpenedWorkId로 private 작업을 조회한다. 현재 선택이나 같은 파일의 새 작업으로 바꾸지 않는다.
3. 그 작업의 세션에 원래 Ready를 그대로 apply한다.
4. 정상 결과를 준비하고 **현재 모든 private 세션의 state를 다시 읽어** 뷰를 게시한다.
5. 호출 결과를 반환하며 게시 후 과거 outcome.state로 다시 대입하지 않는다.

중간 await·I/O·호출자 comparator·콜백은 없다. listener 재진입은 세션 확정/핸들 소비 후 게시에서만 일어난다.
재진입 명령이 더 최신 구성을 만들었으면 이후 과거 결과로 덮어쓰지 않는다.
독립 작업을 전역 잠금/대기열로 막지 않는다. 준비·취소는 구성/선택을 바꾸지 않아 뷰를 교체하지 않는다.
성공·거부·선택·등록·닫기에서 필요 뷰를 최신 소유 세션으로부터 게시한다.

| 상황 | 결과 |
|---|---|
| A 준비 중 B 선택 | A 확인은 A만 반영, B와 선택 B 유지 |
| 같은 기준 P/Q | 먼저 수락된 변경 이후 다른 핸들은 workflow가 오래된 기준으로 거부 |
| 중복 확인/취소 후 확인 | confirmationNotPending. 완료 핸들의 영구 이력은 보관하지 않음 |
| 원래 작업이 없음 | workNoLongerOpen. 준비 요청은 GeometryChangeWorkNotOpen |
| 닫기 후 같은 키 재등록 | 새 ID/세션. close가 대기를 제거하므로 옛 확인은 confirmationNotPending |
| 취소·Blocked·Unchanged·Rejected | 구성/개정 유지. 자동 재준비/재반영 없음 |
| 비선택 작업 닫기 | 기존 선택 유지 |
| 선택 작업 닫기 | 선택 해제. 다른 작업 자동 선택 정책은 없음 |

## 수명과 후속 UI 경계

Notifier는 다른 provider를 watch하지 않으며 화면 구독 변화로 재생성되지 않는다.
keepAlive는 열린 작업의 명시 수명을 보호한다. owner invalidate/refresh를 작업 초기화 수단으로 사용하지 않는다.
파생 provider/위젯의 구독 해제는 session.close가 아니다.
소유 ProviderScope/ProviderContainer의 최종 dispose에서 모든 잔여 세션을 close하고 맵/키/대기를 해제한다.
과거 반환 state는 불변이므로 dispose 후 닫힘 표시로 변하는 객체가 아니다.

closeWorkAfterDecision은 저장 질문/종료 허용 판단이 완료됐다는 입력 경계다.
판단이 취소됐으면 호출하지 않는다. 확인 UI는 원래 핸들을 보존하고 응답 후 동기 명령을 호출해야 한다.
실제 파일 읽기/저장·미저장 판정·앱 종료 질문·대화상자 수명은 아직 연결하지 않았다.

```dart
final commands = container.read(openWorksProvider.notifier);
final workId = commands.registerLoadedWork(
  fileIdentity: verifiedIdentity, // 후속 파일 경계가 제공할 식별 정보
  displayName: displayName,
  configuration: loadedValidConfiguration,
);
final result = commands.prepareGeometryChange(workId: workId, request: request);
if (result case GeometryChangeNeedsConfirmation(:final confirmationId)) {
  // UI의 사용자 동의 뒤 호출. 현재 선택 ID로 대상을 바꾸지 않는다.
  final confirmation = commands.confirmGeometryChange(confirmationId);
  // 실제 화면 관찰은 openWorksProvider를 watch한다.
}
```

호출 예시의 로더/사용자 확인 UI는 구현됐다는 뜻이 아니다.

## 실패·로그 경계

Blocked·Rejected·취소·닫힘·중복 확인은 정상 반환값이다. AsyncError/SEVERE로 바꾸지 않는다.
명령에서 catch/로그를 추가하지 않으므로 예상 밖 실패의 원인/스택은 그대로 호출자에게 전달된다.
UI 최종 오류 전달·workflow 오류의 선택적 로그 진단 매핑은 이번 범위에서 구현/검증하지 않았다.
기존 AppLogging/전역 핸들러/ProviderObserver 정책은 유지한다.
원문·전체 구성·후보·Provider 상태를 로그로 덤프하지 않으며 새 이벤트/출력 대상을 만들지 않았다.

## 검증과 남은 범위

책임별 테스트는 test/work/open_works_registration_test.dart,
geometry_change_confirmation_test.dart, open_works_lifetime_test.dart다.
반복되는 실제 구성 준비만 test/support/work_configurations.dart로 공유한다.
실제 ProviderContainer와 고정 기대 전체 구성으로 등록/선택·원래 작업 반영·수명·재진입을 검증한다.

다음 한 가지는 **실제 파일 열기 경계의 식별·읽기/유효 구성 공급 계약 설계**다.
지원 경로와 작업 파일 형식·검증 책임을 정하기 전에 임의 로더/파일 선택 UI를 추가하지 않는다.
저장·동기화·UI·전체 탭/에디터·배치/제작 판정·결과 무효화는 미구현이다.

실제 로컬 검사: 앱 tool/verify.dart 성공(생성 시작 일치·반복 안정성·포맷·fatal-infos 분석·전체 68개 테스트).
새 파일 단독 실행: 확인 9개, 수명 4개, 등록/식별 6개 모두 성공.
문서의 로컬 링크 누락 0건, git diff --check 통과. 앱의 화면/네이티브 변경이 없어 Windows 빌드·시각 검사는 반복하지 않았다.
원격 Actions·최종 UI 오류 전달·실제 OS 파일 동일성은 미검증이다.

독립 checkout 검증도 성공했다. 현재 미커밋 구현/생성 소스를 격리 seed에 반영한 뒤 새 clone과 새 PUB_CACHE에서
고정 원격 Git SHA로 tool/verify.dart를 실행했다. 첫 생성 일치·반복 안정성·포맷·strict 분석·68개 테스트가 통과했고
clone의 Git 상태는 깨끗했다. SDK만 기존 고정 설치를 연결했으며 workflow 형제 경로나 override는 사용하지 않았다.
로컬 로그는 .tooling/open-works-verify.log 및 .tooling/open-works-independent-verify.log에 있다.
