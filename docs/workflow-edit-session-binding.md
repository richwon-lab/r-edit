# 앱의 열린 작업·workflow 편집 세션 연결 계약 — 설계

작성·검토일: 2026-10-30. **앱 연결은 미구현이며 이 문서의 새 앱 타입/메서드는 추천안이다.**
이번에는 코드·의존성·화면·로그 매핑을 추가하지 않았다.
[공통 개발 기반](development-foundation.md), [기반 보완](development-foundation-additions.md),
[모듈 경계](module-boundaries.md), [오류·로그 계약](failure-diagnostics-logging.md)을 함께 따른다.

## 1. 실제 구현과 패키지 연결 상태

확인한 앱 파일: AGENTS.md, README.md, pubspec.yaml/lock, lib/main.dart,
lib/app/r_edit_app.dart, providers/app_router.dart·app_theme_mode.dart·app_logger.dart,
routing/app_routes.dart, logging/app_logging.dart·app_log_event.dart·app_log_diagnostic.dart.
workflow의 AGENTS·개발 기준, 편집 세션 계약 12절과 실제 세션/준비/반영 결과·공개 진입점도 읽었다.

- 앱은 Flutter 3.47.7/Dart 3.13.5, flutter_riverpod 3.4.3,
  riverpod_annotation 4.0.7/generator 4.0.9, go_router 17.3.0/builder 4.5.2를 사용한다.
- 현재 ProviderScope에 로깅 관찰자가 있고 생성 Provider로 라우터/테마/로거만 연결한다.
  타입 라우트는 StartRoute 하나이며 열린 작업·편집 화면·파일 읽기·저장은 없다.
- **앱 pubspec.yaml과 pubspec.lock에 r_edit_workflow 의존성이 없다.**
  아래 명령·Provider 설계가 이미 연결/실행됐다고 해석하지 않는다.
- 최종 대조한 workflow 로컬 HEAD는 6213a211095ba6fc869d42abcfce542c986ca217이다.
  해당 커밋에 실제 세션 API가 포함됨을 git show로 확인했다.
  원격 게시/참조 도달 여부는 조회하지 않았으므로 즉시 원격 소비 가능하다고 주장하지 않는다.
- 실제 로컬 workflow API:
  ProductDesignEditSession.open(configuration:), state, prepareGeometryChange(request),
  applyPreparedGeometryChange(ReadyProductGeometryChange), close().
  state는 불변 configuration/sessionId/revision/isClosed 관찰값이다.
  공개 순수 prepare는 제거됐으며 Ready의 후보는 비공개다.

workflow 기준 파일의 실제 확인 위치는 형제 저장소의
../r_edit_workflow/docs/product-design-edit-session.md 및 lib/src/product/ 아래다.
독립 앱 checkout에 형제 폴더가 반드시 존재한다고 가정하는 실행 경로나 코드 의존성을 만들지 않는다.

## 2. 소유권과 서로 다른 식별 정보

| 대상·추천 이름 | 소유자 | 의미와 금지되는 혼용 |
|---|---|---|
| OpenedWorkId | 앱의 열린 작업 소유자 | 열기 한 번의 실행 식별자. 닫은 ID는 재사용하지 않는다. 파일 경로/표시명/세션 토큰이 아니다. |
| WorkFileIdentity | 앱 파일 연결 경계 | 지원하는 Windows 경로 비교 키와 원래 접근 경로. 같은 파일 중복 열기 판단용이며 업무 제품 ID가 아니다. |
| displayName | 앱 | 화면 표시명. 동명/변경 가능하며 조회 키로 사용하지 않는다. |
| ProductDesignEditSessionId | workflow | open 때 발급한 단일 isolate 수명 토큰. 앱이 발급/직렬화/최신 값으로 재결합하지 않는다. |
| ProductDesignEditSession | workflow, 객체 수명은 앱 | 구성·개정 정본 및 수락 조건 소유자. 앱 private 열린 작업 항목 하나가 인스턴스 하나를 보유한다. |
| OpenedWorkView.editState | 앱의 파생 관찰값 | session.state에서 읽은 불변 뷰. 별도 구성/카운터 정본이나 복원 입력이 아니다. |
| GeometryChangeConfirmationId | 앱 명령 경계 | 확인 대기 한 건의 불투명 실행 핸들. 두 준비/중복 클릭을 구분하며 JSON/업무 이력 ID가 아니다. |

OpenedWorkId/확인 핸들은 열린 작업 소유자가 새로 발급하는 실행 객체를 추천한다.
시간/파일명/문구/내용 해시에서 추정하지 않으며 같은 파일을 닫고 다시 열면 새 작업 ID다.
앱의 열린 작업 등록 시점에만 세션을 open한다. 같은 파일을 활성화할 때 세션을 다시 만들지 않는다.
아직 전체 WorkDocument·WorkSession을 로드/구현한 것이 아니다.
첫 연결에서 넘길 수 있는 것은 **출처가 명확한 유효 ProductDesignConfiguration**까지다.

### 열기·선택·닫기 API 추천

- openFile(path): 후속 실제 파일 경계. 지원 경로 해석 → 기존 열린 작업 조회/활성화 →
  필요한 경우 파일 읽기/유효 구성 로드 → 등록 직전 중복 재확인 → 새 작업/세션 등록.
- registerLoadedWork(fileIdentity:, displayName:, configuration:):
  이미 로드·검증된 구성의 동기 등록 경계. 파일을 읽었다고 가장하지 않는다.
- activateWork(workId): 선택만 변경. 세션·개정은 건드리지 않는다.
- prepareGeometryChange(workId:, request:): 특정 작업 조회 후 그 세션의 prepare 호출.
- confirmGeometryChange(confirmationId): 원래 작업 조회 후 동기 apply와 표시 갱신.
- cancelGeometryChange(confirmationId): 해당 확인 대기만 제거.
- closeWorkAfterDecision(workId): 닫기 판단이 최종 수락된 뒤에만 수명 종료/등록 제거.

이름은 추천이며 현재 공개 앱 API가 아니다.
파일 읽기·저장·파일 선택 도구·미지원 형식 처리의 구현/기술 선정은 후속이다.
openFile을 실제로 만들기 전에는 운영 UI에서 파일을 읽는 척하는 빈 구성/데모 문서를 공급하지 않는다.
실제 파일 포맷 전체와 WorkDocument를 이번 연결 계약으로 확정하지 않는다.

## 3. 같은 파일 중복 열기의 첫 지원 범위

추천 첫 범위는 일반적인 대소문자 비구분 Windows 경로 환경의
완전한 드라이브 절대경로/UNC 경로를 이용한 **앱 실행 내 경로 키 대조**다.
파일명만 비교하지 않고 루트/디렉터리를 포함한다.

- 경로 경계에서 구분자를 통일하고 일반적인 . / .. 구간을 루트 범위 안에서 해석한다.
- 드라이브 문자와 ASCII 영문 대소문자 차이는 비교 키에서만 동일하게 다룬다.
  원래 접근 경로/화면 표시와 고객 원문·업무 ID를 정규화하지 않는다.
- 비ASCII 문자의 임의 소문자화·Unicode 정규화로 동일성을 만들어내지 않는다.
  정확히 같은 비ASCII 표기 외의 대소문자/Unicode 별칭 동일성은 첫 범위에서 보장하지 않는다.
- 상대경로·C:folder 같은 드라이브 상대형·장치/확장 경로·모호한 루트는 조용히 추정하지 않는다.
  후속 파일 경계에서 지원 여부를 확인/거부하고 키를 생성해야 한다.
- 대소문자를 구분하도록 설정된 디렉터리는 위 첫 범위 밖이다.
  해당 지원 여부를 실제 파일 경계에서 확인하기 전 모든 Windows 파일에 안전하다고 주장하지 않는다.
- symlink/junction/hard link, 짧은 파일명, 네트워크 이름 별칭, Drive/동기화 별칭,
  파일 이동/이름 변경을 OS 파일 ID로 완전히 식별하는 계약은 아니다.
  하나의 실제 파일이 지원 밖 별칭으로 별도 열릴 수 있다는 한계를 남긴다.

같은 지원 키가 이미 열려 있으면 기존 OpenedWorkId를 활성화하고 세션/state를 그대로 쓴다.
나중에 다른 displayName을 받았다고 새 작업으로 만들지 않는다.
중복 open이 비동기 파일 읽기를 동시에 통과할 수 있으므로, **로드가 끝난 뒤 등록 직전에도 동기 재조회**한다.
이미 등록됐으면 기존 작업을 활성화하고 두 번째 세션은 만들지 않는다.
다른 파일의 열기/확인을 전역 잠금으로 막거나 별도 작업 큐를 만들지 않는다.

이 경로 규약은 추천이며 경로 코드/OS 검증은 이번에 실행하지 않았다.
여러 프로세스 동시 편집·외부 변경 감지·Drive 잠금까지 보장하지 않는다.

## 4. Riverpod 소유 위치와 관찰값 통지

### 추천 최소 구조

| 파일·역할 후보 | 책임 |
|---|---|
| lib/app/work/open_works.dart | 생성 Notifier OpenWorks. 현재 ProviderScope 안의 열린 작업 목록/선택·private 세션/확인 대기와 명령을 소유 |
| lib/app/work/opened_work_view.dart | 불변 목록·선택 ID·작업별 표시/파일 정보·ProductDesignEditState의 읽기 전용 투영 |
| lib/app/work/geometry_change_confirmation.dart | 원래 작업 ID와 Ready를 연결한 private 확인 대기 및 UI용 불투명 핸들/요약 |
| lib/app/work/work_file_identity.dart | 지원 Windows 비교 키의 책임. 실제 파일 읽기 구현과 혼동하지 않음 |
| lib/app/work/workflow_log_diagnostic.dart | 실제 오류 연결 시 필요한 명시적 로그 진단 변환 위치 후보. 이번에 빈 파일/매핑 코드를 만들지 않음 |

OpenWorks는 기존 AppThemeMode처럼 **@Riverpod(keepAlive: true) 생성 Notifier**를 추천한다.
앱 루트 ProviderScope 수명 안에서 필요한 열린 작업 모음 한 개이며,
정적 singleton/다른 앱 컨테이너까지 공유하는 전역 관리자/Repository/새 DI는 만들지 않는다.
한 Notifier가 작업 ID를 명시적으로 받는 명령을 처리해 첫 범위의 소유/게시 경계를 단순하게 한다.
작업마다 별도 session Provider와 명령 소유자를 추가해 소유 정본을 둘로 나누지 않는다.

private 작업 항목 맵이 실제 세션을 보유한다. 파일 키 인덱스는 그 항목의 중복 조회용 파생 인덱스다.
공개 Notifier state에는 불변 OpenWorksView와 OpenedWorkView만 담는다.
**raw session 객체나 session을 반환하는 getter/Provider를 화면에 제공하지 않는다.**
위젯은 읽기 전용 관찰값을 watch하고 notifier의 명시 명령만 호출한다.
Notifier state를 위젯에서 직접 설치하는 경로도 허용하지 않는다.
workflow 내부 src를 앱에서 import하지 않는다.

### 실제로 통지가 일어나는 순서

세션 객체의 내부 변경 자체에는 Riverpod 자동 통지가 없다.
명령 소유자가 다음을 명시 수행한다.

1. private 맵에서 대상 작업의 세션을 찾는다.
2. 동기 prepare/apply/close를 호출한다.
3. 반환된 결과 종류에 맞춰 private 작업/확인 대기를 정리한다.
4. **현재 private 항목들의 session.state를 다시 읽어** 새 불변 목록/작업 뷰를 만들고
   생성 Notifier의 state에 게시한다. 독자 카운터를 +1하거나 별도 configuration을 설치하지 않는다.

성공 apply 뒤에 게시한다. 거부/무변경은 편집 state를 바꾸지 않으며 정상 결과로 호출자에게 반환한다.
확인 대기와 선택 같은 앱 메타데이터 변경을 게시하는 경우에도 최신 세션 뷰에서 파생한다.
outcome.state를 보관했다가 후속 await 뒤 화면 정본에 덮어쓰지 않는다.
반영/목록 수정→투영 준비→state 게시 사이에는 await나 사용자 콜백을 두지 않는다.
게시 listener의 동기 재진입이 생겨도 workflow 채택과 확인 핸들 소비는 이미 끝난 상태여야 한다.
게시 후에는 과거 outcome 기반의 두 번째 state 대입을 하지 않는다.
뷰에 담긴 과거 editState도 불변이며 이후 명령의 current 인자가 될 수 없다.

work별 select/파생 family Provider는 OpenWorksView에서 해당 작업만 투영할 수 있다.
그 파생 Provider의 auto-dispose/구독 해제는 관찰 수명일 뿐 작업 close가 아니다.
구독 변화로 workflow 세션을 재생성/종료하는 onDispose를 붙이지 않는다.
실제 세션 종료는 명시 close 또는 소유 ProviderScope의 최종 폐기에서만 일어난다.

Notifier는 위젯/테마/라우터 watch 변화로 private 소유 맵이 재생성되지 않게 한다.
로그/협력 객체는 필요 시 명령에서 read하고, 소유 Provider의 invalidate/refresh를 작업 초기화 수단으로 쓰지 않는다.
소유 컨테이너 자체가 실제 폐기되면 ref.onDispose의 마지막 정리에서 모든 잔여 세션을 close한다.
이는 화면 구독 해제와 다르며 사용자 저장/앱 종료 판단을 대체하지 않는다.

현재 Router Provider의 ref.onDispose(router.dispose)는 Router 수명이다.
OpenedWork의 수명으로 전용하지 않는다. StartRoute는 그대로 두고 새로운 탭/작업 라우트나 URL ID를 확정하지 않는다.

## 5. 확인 대기와 특정 작업의 반영

여기서 확인은 **준비한 도안 변경의 채택 동의**다.
배치 결과에 연결된 제작 검토/OperatorReview나 저장 가능 판정이 아니다.

Ready를 얻으면 명령 소유자가 확인 대기 한 건을 만든다.
private 대기 값은 confirmationId → (원래 OpenedWorkId, 원래 Ready)다.
UI에는 핸들·원래 작업의 표시 정보·준비 요약만 넘긴다.
기준/후보/세션을 임의로 다시 묶을 수 있는 생성/수정 API는 제공하지 않는다.

confirmGeometryChange는 한 동기 호출에서:
1. 확인 핸들을 private 대기에서 **한 번 꺼내 소비**한다.
2. 저장된 원래 작업 ID로 여전히 열린 항목을 조회한다.
3. 없다면 앱의 정상 workNoLongerOpen 결과로 끝낸다. 같은 파일/표시명으로 재조회하지 않는다.
4. 있으면 그 항목이 현재 소유한 세션에 **원래 Ready 그대로** apply한다.
5. 반환된 정상 결과를 분류하고 현재 소유 값에서 관찰 뷰를 게시한다.

중복 실행은 이미 소비/취소된 핸들이므로 confirmationNotPending으로 정상 종료한다.
완료 핸들을 영구 보관하는 tombstone/이력 저장소는 만들지 않는다.
두 다른 준비의 핸들은 별개이므로 둘 다 대기할 수 있다.
먼저 수락된 것 이후의 오래된 것은 workflow의 개정/내용 검사로 거부한다.
앱은 세션·개정 비교 알고리즘을 다시 구현하거나 자동 재준비/자동 재반영하지 않는다.

UI가 선택 작업을 바꿔도 이 명령의 조회 키는 원래 workId다.
원래 작업을 닫고 같은 파일을 열어도 **새 workId**여서 옛 대기가 새 작업에 붙지 않는다.
같은 workId의 세션을 제자리 교체하는 API도 허용하지 않는다.
수명 배선 결함 등으로 다른 토큰이 전달되면 workflow differentEditSession 방어를 그대로 처리한다.

서로 다른 작업의 확인은 전역 busy 플래그로 막지 않는다.
확인 대기 개수/보관 UI 정책은 후속이나, 취소/완료/닫힘 때 관련 Ready 참조를 즉시 해제한다.

### 상태 전이와 기대 결과

아래는 미구현 계약 표이며 실제 앱 실행 결과가 아니다.

| 상황 | 앱 처리 | workflow/관찰값 |
|---|---|---|
| 같은 지원 파일 다시 열기 | 기존 workId 선택 | 기존 세션/개정 유지, 선택 뷰만 변경 |
| 확인 중 B로 전환 | A의 핸들은 계속 A를 참조 | 확인하면 A에만 적용. B를 자동 수정하거나 선택을 강제로 A로 되돌리지 않음 |
| A에서 다른 변경 먼저 수락 | 원래 핸들/Ready 그대로 전달 | staleEditRevision, 필요 시 baselineConfigurationMismatch. A 최신 상태 유지 |
| A 닫기 확정 | close·등록/관련 대기 제거 | 옛 확인은 workNoLongerOpen 또는 confirmationNotPending. 다른 작업에 대체 적용하지 않음 |
| 같은 파일 닫고 재열기 | 새 workId/새 workflow 토큰 | 옛 핸들로 새 작업을 조회하지 않음 |
| 같은 기준의 두 Ready | 서로 다른 확인 핸들 | 첫 수락 이후 둘째는 workflow 거부. 자동 병합/재준비 없음 |
| 같은 확인 버튼 중복 | 첫 호출에서 핸들 소비 | 나머지는 confirmationNotPending, 두 번 apply하지 않음 |
| 사용자 취소 | 해당 핸들만 제거 | 구성/개정·선택 작업 유지 |
| Blocked | 구조화 진단 반환, 요청 수정 | 반영 핸들 만들지 않음. 구성/개정 유지 |
| Unchanged | 즉시 무변경 결과 반환 | 과거 baseline 대입 없음. 지연된 결과를 현재 판단으로 재사용하지 않음 |
| Rejected | 핸들 소비 후 기준 진단 반환 | 현재 state 유지. 명시적 새 요청/검토가 필요 |
| Applied | 원래 작업의 최신 뷰 게시 | 실제 확정 구성·개정 통지. 별도 구성/개정 정본은 만들지 않음 |

confirm 중복 방지는 사용자 실수의 중복 호출 계약이고 workflow의 기준 검사를 대체하지 않는다.
앱은 이런 정상 결과를 AsyncError/예상 밖 예외로 던져 ProviderObserver에 전달하지 않는다.
Blocked/Unchanged 자체를 기다렸다가 ‘확인 반영’하는 절차는 없다.
나중에 여전히 같은 요청을 원하면 현재 작업에서 사용자가 명시적으로 다시 준비한다.

## 6. 닫기 수락과 동기 반영의 접점

닫기 여부를 결정하는 저장/사용자 선택 절차는 후속 책임이다.
**닫기 수락 전에는 session.close를 호출하지 않는다.**
결정을 기다렸다 취소했다면 작업/세션/대기를 그대로 유지한다.

closeWorkAfterDecision(originalWorkId)는 최종 판단이 완료된 뒤 동기적으로:
- 원래 실행 ID로 항목을 다시 조회한다. 이미 닫힌 ID로 재열린 작업을 닫지 않는다.
- 해당 session.close를 호출한다.
- 파일 키 인덱스/작업 항목/그 작업의 대기를 제거한다.
- 선택 작업이 닫혔다면 선택을 해제하는 최소안을 추천한다. 다음 작업 자동 선택 UX는 후속이다.
- 남은 현재 세션에서 뷰를 만들고 알린다.

저장 질문을 띄운 동안 해당 작업이 변경됐다면 닫기 결정을 최신 조건으로 다시 확인할 책임이
후속 닫기 정책에 있다. 지금 새 dirty/save 플래그나 저장 명령을 발명하지 않는다.
현재 AppLogging.bindApplicationExit는 로그 flush/종료만 연결한다.
향후 종료 허용 판단은 그 최종 수명 정리 **이전**에 구성해야 하며 현재 코드가 작업 닫기를 처리한다고 보지 않는다.
앱 종료 정책 전체·저장 여부·강제 종료 복구는 이번 설계 밖이다.

확인 완료 뒤 원래 작업 조회→세션 선택→동기 apply에는 await가 없다.
workflow 반환 뒤 앱 관찰값을 게시하며, 게시 전 대기 핸들도 이미 소비했다.
이 구조에서는 listener가 재진입해 같은 버튼을 눌러도 다시 apply할 Ready가 없다.

## 7. 최소 호출 예시 — 미구현 설계용 의사 Dart

아래 앱 API/형식은 추천안이며 컴파일·실행하거나 생성한 코드가 아니다.
workflow 메서드 이름만 실제 API와 대조했다.

~~~dart
// 작업 소유자 내부. 화면에 이 session 맵을 노출하지 않는다.
final owned = findOwnedWork(originalWorkId);
final preparation = owned.session.prepareGeometryChange(request);
switch (preparation) {
  case ReadyProductGeometryChange():
    final ticket = storeConfirmation(originalWorkId, preparation);
    return ChangeNeedsConfirmation(ticket.id, preparation.summary);
  case BlockedProductGeometryChange():
    return ChangeBlocked(preparation.issues);
  case UnchangedProductGeometryChange():
    return ChangeUnchanged(); // 과거 baseline 설치 없음
}
~~~

~~~dart
// UI: 선택 작업은 준비를 시작할 때 한 번 특정하며 이후 대상 결정에 쓰지 않는다.
final decision = commands.prepareGeometryChange(workId: originalWorkId, request: request);
if (decision case ChangeNeedsConfirmation(:final id, :final summary)) {
  final accepted = await askToAdoptGeometryChange(summary);
  if (!accepted) {
    commands.cancelGeometryChange(id);
    return;
  }
  // commands는 같은 앱 소유 컨테이너의 명령 포트이며 작업별 세션 자체가 아니다.
  commands.confirmGeometryChange(id); // 내부에서 원래 작업 조회·apply·게시까지 동기 수행
}
~~~

~~~dart
// 명령 소유자 내부: 중간 await/외부 콜백 없음.
final pending = takePendingConfirmationOnce(id);
if (pending == null) return ConfirmationNotPending();
final owned = findOpenWork(pending.workId);
if (owned == null) return WorkNoLongerOpen();
final outcome = owned.session.applyPreparedGeometryChange(pending.ready);
publishViewsFromCurrentOwnedSessions(); // outcome.state를 나중에 덮어쓰는 대입 없음
return switch (outcome) {
  AppliedProductGeometryChange() => ChangeApplied(outcome.summary),
  RejectedProductGeometryChange() => ChangeRejected(outcome.issues),
};
~~~

위 예시는 UI 위젯의 구체 수명 코드를 생략했다.
실제 후속 구현은 확인 중 원래 위젯이 사라져도 열린 작업/핸들을 화면 구독과 함께 폐기하지 않고,
앱 소유의 확인 진행 경계에서 취소/완료를 연결해야 한다.
닫힘으로 핸들이 제거된 뒤 도착한 응답은 정상 종료하며 새 작업에서 다시 살리지 않는다.

## 8. 실패·진단·기록 경계

현행 로그는 AppLogging.reportUnexpected, FlutterError.onError, PlatformDispatcher.onError,
ProviderObserver.providerDidFail 경계다. 원래 오류 identity의 중복 방지가 있다.
기록 가능한 이벤트/로거와 AppLogDiagnostic 필드는 이미 제한되어 있다.
앱에 workflow 오류 실사용 매핑은 현재 없다.

| 결과/실패 | 앱 명령 경계 처리 | 로깅 계약 |
|---|---|---|
| Blocked/Rejected | 구조화 결과/원래 하위 진단을 UI에 반환 | 자동 SEVERE/예상 밖 실패 보고 금지 |
| 취소/닫힘/중복 확인 | 앱 정상 결과 | 오류 객체/Provider 실패로 바꾸지 않음 |
| 유효 값 생성의 알려진 입력 예외 | 처리 가능한 해당 입력 경계에서 수정 안내 | code/fieldPath/details를 보존, 화면용 안내와 개발자 진단을 분리 |
| 예상 밖 Exception/Error | 원인·스택을 보존하고 기존 최종 오류 경계에 전달 | 같은 실패를 명령 계층에서 먼저 기록한 뒤 다시 던져 중복 기록하지 않음 |

향후 workflow_log_diagnostic 경계가 **의미를 아는 오류만** AppLogDiagnostic으로 명시 변환한다.
기록을 승인한 code.name, 실제 필드/0 기반 인덱스 경로, 타입 이름 쌍, 고정 operation 이름만 선택한다.
작업/제품/영역 ID, 파일 경로, 세션 토큰 문자열, 실제 미지원 입력값·개정 비교 객체 전체는 자동 기록하지 않는다.
진단 상세의 원문/전체 구성/후보/요청/Provider 상태를 toString/toJson으로 펼치지 않는다.
UI에서 필요한 식별 정보와 파일 로그 공개 정보는 별도다.

현재 providerError 최종 관찰자는 진단을 추측하지 않는다.
실제 명령 실패가 어느 경로로 최초 전달되는지 먼저 정하고,
해당 최초 최종 경계가 매핑된 선택 진단을 전달하도록 후속 배선을 검토한다.
기존 ProviderObserver가 먼저 기록한 뒤 다시 진단을 붙여 재기록하는 방식은 허용하지 않는다.
추천 접점은 세 전역/Provider 전달 경로가 모이는 기존 AppLogging.reportUnexpected의 최초 기록 직전이다.
후속 구현에서 원래 public workflow 예외 타입에 명시 등록한 선택 함수만 호출하고,
이미 전달된 diagnostic이 있으면 이를 존중한다. 정상 결과는 이 경로에 보내지 않고,
모르는 오류는 현재처럼 diagnostic 없이 기록한다. operation은 알려진 연산명만 선택하고 외부 메시지에서 복원하지 않는다.
이것은 기존 final 경계의 후속 배선 제안이지 이번에 자동 매핑을 구현했다는 뜻이 아니다.
그 배선 없이 모든 명령 오류에 구조화 진단이 이미 보존된다고 주장하지 않는다.
일반 사용자 명령 메서드가 던진 오류가 자동으로 Provider 실패가 된다고도 가정하지 않는다.
새 로그 이벤트·출력 대상·매핑 코드·예외를 성공값으로 덮는 catch는 이번에 추가하지 않는다.

## 9. 후속 패키지 소비와 검증 계획

배포/공유 개발 기준은 실제 세션 구현이 포함된 workflow Git 커밋 또는 릴리스를
원격에 게시하고 **확인한 고정 ref**로 앱 pubspec에 직접 선언하는 것이다.
브랜치 최신값이나 확인하지 않은 임의 SHA를 지정하지 않는다. 앱 lock도 관리한다.
생성 소스를 포함한 패키지를 소비하며 앱에서 workflow 생성기를 다시 실행하지 않는다.
현재 미커밋/미게시 내용을 원격 ref로 가져오는 명령을 예시로 만들지 않는다.

로컬 공동 개발은 필요할 때 pubspec_overrides.yaml의 path override를 사용할 수 있다.
이는 제약 충돌을 감추는 dependency_overrides 채택이 아니라 같은 패키지 소스 위치 전환에 한정한다.
**현재 앱에는 override 파일이 없고, check-ignore 결과도 무시 대상이 아니다.**
후속 생성 전에 해당 로컬 파일의 Git 제외 규칙을 먼저 마련하고 실제 check-ignore로 검증해야 한다.
기존 원칙 문구만 보고 이미 제외됐다고 가정하지 않는다. 이번에는 ignore/의존성 파일을 바꾸지 않았다.

후속 테스트는 책임별 값/명령/ProviderContainer 시험을 우선한다. 가짜 업무 화면/엔진을 만들지 않는다.

| 검증 책임 | 기대 |
|---|---|
| 열린 작업·경로 | 같은 지원 키 재열기는 기존 ID/세션 활성화, 다른 키는 독립. 동명 파일을 합치지 않음 |
| 동시 로드 완료 | 등록 직전 재조회로 같은 파일의 세션 중복 생성 방지. 실제 파일 로더 도입 시 격리 입력으로 시험 |
| 확인 중 작업 전환 | B 선택 상태에서 A의 확인을 완료해도 A만 변경하고 B/선택을 보존 |
| 원래 작업의 다른 변경 | 같은 핸들/Ready를 전달해 workflow가 오래된 기준 거부. 앱이 비교를 복제하지 않음 |
| 닫기·재열기 | 닫힘 취소는 세션 보존. 확정 close 후 옛 핸들은 같은 파일의 새 workId에 적용 불가 |
| 두 준비·중복 확인 | 서로 다른 핸들 중 하나 수락 뒤 다른 것은 기준 거부. 같은 핸들은 한 번만 apply |
| 취소/Blocked/Unchanged/Rejected | 구성/개정 보존, 자동 재시도·과거 baseline 대입 없음 |
| 성공과 Provider 통지 | session.state의 실제 최신 구성·개정이 관찰값으로 게시되고 watch 대상이 갱신됨 |
| 게시 중 후속 명령 | 핸들 선소비·workflow 확정 이후 listener 재진입해도 중복 적용/과거 outcome 덮어쓰기 없음 |
| 구독 수명 | 화면/파생 family 구독 해제·재구독이 세션 close/reopen을 만들지 않음 |
| 컨테이너 격리 | 다른 ProviderContainer의 작업/토큰/대기와 혼용하지 않음. 최종 소유 컨테이너 정리는 모든 세션 close |
| 실패/로그 | 정상 거부는 SEVERE 아님. 원문/전체 상태 비출력, 예상 밖 실패 최초 최종 경계 한 번 기록 |

첫 구현의 관찰 통지는 실제 ProviderContainer listener로 시험하고,
공개 명령 이후 view.editState.configuration/revision을 session 결과의 고정 기대 전체 값과 대조한다.
관찰값 카운터만 증가시키는 테스트로 대체하지 않는다.
명령 경계 우회용 raw session 노출, 과거 뷰 설치 API가 없는지도 소비 관점에서 확인한다.
실제 파일/OS 경로 지원 범위 시험, Windows 빌드/실행은 해당 기능을 도입할 후속 변경에서 수행한다.

## 10. 확정 요구·추천안·남은 결정

확정 요구는 열린 작업 1개/세션 1개, 같은 지원 파일의 기존 작업 활성화,
원래 실행 ID에 묶인 확인, 단일 workflow 정본, 명시적 관찰 통지와 명령 경계,
구독 수명과 작업 close 분리, 정상 거부/오류/로그 분리다.

추천은 keepAlive 생성 Notifier 하나가 private 소유 목록과 확인 대기를 관리하는 가장 작은 구조다.
추가 Repository·전역 관리자·명령 큐·이벤트 버스·상태 도구는 필요하지 않다.

구현 전 남은 결정:
- 추천 앱 타입/명령 이름과 첫 Windows 경로 키 지원 범위 채택.
- 실제 작업 파일 해석/읽기의 계약과 검증된 초기 구성의 공급 경계.
- 실제 세션 구현을 포함해 게시할 workflow 고정 Git ref.
- 확인 진행 UI 수명·닫힘 후 선택 UX, 향후 저장/종료 허용 판단의 연결.
이 항목을 구현자가 임의 기술/정책으로 채워도 된다는 뜻으로 남기지 않는다.

다음 최소 구현은 **계약 검토와 workflow 고정 ref 준비 후, 파일 I/O·화면 추가 없이
로드된 유효 구성 등록→소유/활성화→준비 핸들→확인/취소→관찰 통지→명시 close의 명령/Provider 기반 연결**이다.
초기 구성은 호출 경계에서 명시적으로 받으며 운영 데모/빈 WorkDocument를 만들지 않는다.
실제 openFile·저장·전체 탭/에디터·동기화·새 로그 이벤트는 별도 후속 범위다.

## 11. 이번 검토 기록

두 저장소의 지침/기술 기준과 앱 Provider·Router·오류/로그, workflow 실제 공개 세션 API를 대조했다.
패키지 미연결·로컬 override 미제외와 최종 workflow 로컬 커밋/원격 미확인 상태를 구분해 기록했다.
문서의 소유 흐름·식별 정보·대기/반영/게시 순서와 실제 API 이름을 대조했다. 로컬 링크도 확인했다.
의사 코드는 실행 결과가 아니다. 문서 전용이므로 생성·분석·테스트·Windows 빌드를 반복하지 않는다.
코드·workflow·SDK·의존성·CI·Git 설정/스테이징을 변경하거나 커밋/푸시하지 않는다.
