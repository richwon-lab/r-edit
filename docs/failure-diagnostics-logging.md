# 예외·진단·로깅 계약

결정일: 2026-10-27. 두 저장소의 현재 실패 처리 기준이다. 구현/검증 결과는 마지막 절에 별도 기록한다.

## 분류와 소유권

| 실패 | 현재 발생/처리 경계 | 변환·기록 |
|---|---|---|
| 검증 진단 목록 | validateTextAreaInputs / validateProductDesignConfiguration | 독립 issue 수집, UI가 수정 안내로 해석. 함수마다 로그 금지 |
| 유효 값 생성/JSON 거부 | TextAreaInput·기하·도안·제품 생성/복원 | 도메인 예외 + 구조화 상세. 소비자가 code/fieldPath/details로 분기 |
| 배치 없음/계산 불가/탐색 미완료 | 아직 구현 안 됨 | 정상값·null로 대체하지 않으며 향후 엔진 결과 계약에서 구분 |
| 외부 작업 실패 | 현재는 앱 로그 경로·파일 I/O만 존재 | 제한된 로깅 대체 경로. 업무 I/O/명령은 추가하지 않음 |
| 내부 결함 | ArgumentError/StateError 등 Error 및 예상 밖 예외 | 일반 검증 실패로 바꾸지 않음. 앱 최종 오류 경계에서 기록, 성공/복구로 간주하지 않음 |

진단 객체 생성 자체에 잘못된 code/detail 조합을 주면 ArgumentError다. 이는 사용자 입력 거부가 아닌 호출 코드 결함이다.
workflow에는 logging 의존성·root 설정·출력 구독·경로·Flutter 핸들러·파일 I/O를 넣지 않는다.
현재 값/참조 검사에 내부 로그 발생 지점이 없으므로 Logger 추상화도 만들지 않는다.
실제 외부 협력이 생기면 기존 logging Logger의 생성자 주입과 구체 콜백 전달을 비교한다.
전자는 레벨/계층을 재사용하고 후자는 정해진 이벤트만 허용한다. 현재는 둘 다 도입할 사용처가 없다.
Result 패키지는 업무 결과 표현용이며 예외 진단/로그의 대체물이 아니다. 현재 추가하지 않는다.

## 진단과 원인

invalidType은 기대/실제 타입, 미지원 태그/방식은 원래 값과 지원 목록이 필수다.
빈 값은 코드/필드 경로, 수치 오류는 수치/연산, 중복은 ID/두 0 기반 위치,
참조 오류는 제품/적용 ID/일치 위치, 문구 불일치는 길이·줄 수로 판단한다.
원문·전체 입력 객체·전체 JSON을 예외에 보관하지 않는다. 상세는 도메인별 작은 sealed 타입으로 제한한다.
코드별 필수 상세와 허용 타입을 런타임에서 검사하며 assert에 의존하지 않는다.

같은 실패는 rethrow, 문맥/코드 변환은 catch의 StackTrace와 Error.throwWithStackTrace를 사용한다.
문맥 예외는 root cause 객체·causeStackTrace를 보존하고 contextStackTrace로 문맥 추가 위치를 구분한다.
경로 접두 추가는 매번 기존 상세를 복제하거나 원래 예외를 반복 포장하지 않는다.
ProductDesignNestedException은 다른 오류 계열을 한 번 연결하며 후속 접두 추가에서도 같은 cause를 유지한다.
Error를 도메인 예외로 잡지 않는다. toString 분석은 금지한다. 한국어 description은 개발자 진단이며 UI 확정 문구가 아니다.

## 기술 선택 근거

공식 자료/선택 버전 확인일 2026-10-27. SDK는 기존 Flutter 3.47.7/Dart 3.13.5다.

| 후보 | 확인한 SDK/의존성·라이선스 | 선택 |
|---|---|---|
| logging 1.3.0 | 기존 BSD-3-Clause, Dart Logger/레벨/오류·스택 인자 | 유지 |
| logging_appenders 2.0.0+1 | MIT, Dart >=3.8, logging/meta/intl/clock/http | 미채택. 소스는 시간 간격 후 회전, 무제한 초기화 버퍼, 큰 한 건/프로세스 lock 부재. 엄격한 용량·동시 실행을 추가로 구현해야 함 |
| 작은 앱 파일 출력기 | dart:io의 비동기 파일/OS lock, 별도 패키지 없음 | 위 한도·다중 프로세스 요구에 한정. 일반 로깅/파일 프레임워크로 확장하지 않음 |
| Talker/Talker Flutter 5.2.0 | MIT, 최근 공식 배포. core는 talker_logger, Flutter는 group_button/path_provider/share_plus/web 추가 | 조회/공유 UI·Provider 상태 수집이 필요 없고 logging과 역할 중복. 미채택/실행 검증 안 함 |
| path_provider 2.1.6 | BSD-3-Clause, Dart ^3.10 / Flutter >=3.38, 공식 Flutter 팀 | 앱에만 추가. Windows 2.3.0은 ffi/path/platform_interface 기반 Dart plugin. 임시 경로 resolver 주입으로 테스트 |

공식 소스:
- https://pub.dev/packages/logging
- https://pub.dev/packages/logging_appenders
- https://github.com/hpoul/dart_logging_appenders/blob/master/lib/src/rotating_file_appender.dart
- https://pub.dev/packages/talker
- https://pub.dev/packages/talker_flutter
- https://pub.dev/packages/path_provider
- https://github.com/flutter/packages/tree/main/packages/path_provider/path_provider_windows
- https://api.flutter.dev/flutter/foundation/FlutterError/onError.html
- https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/onError.html
- https://api.flutter.dev/flutter/widgets/AppLifecycleListener/onExitRequested.html

pub.dev 선택 버전 archive의 LICENSE/pubspec/실제 소스를 대조했다. 미채택 도구를 설치·실행했다고 주장하지 않는다.
Windows Application Support는 RoamingAppData다. Application Cache가 LocalAppData이므로 후자 하위 logs를 선택한다.
캐시 정리/비정상 종료로 로그가 사라질 수 있으며 업무 저장 데이터가 아니다. Drive 공용 작업 폴더를 사용하지 않는다.

## 기록 정책

앱의 고정 AppLogEvent만 영속 기록한다. 외부 String 메시지·JSON·Provider 상태·외부 error.toString은 기록하지 않는다.
레코드는 UTC 시각/고정 이벤트명/레벨/등록 로거명/pid/Stopwatch 경과 시간으로 구성한다.
실행은 기존 pid와 시작 시각으로 연결하며 새 업무 ID 체계를 만들지 않는다.
실제 업무 연결 전이므로 제품/영역 ID 필드를 미리 만들지 않는다. 향후 해당 경계에서 원래 ID만 명시적으로 전달한다.
오류 객체와 스택은 Logger의 error/stackTrace 인자로 전달하고 출력 경계가 안전한 타입명·제한된 프레임만 선택한다.
스택 경로/임의 문자열은 마스킹/절단한다. 로그에 sourceText·전체 JSON·Provider 상태를 자동 덤프하지 않는다.
debug 기본 FINE, profile/release INFO다. 비싼 메시지는 logging의 지연 콜백과 isLoggable로 보호한다.
예상 입력 거부/취소는 기능 경계에서 처리하며 SEVERE로 자동 기록하지 않는다. 실제 그런 명령은 아직 없다.
전역/Provider 경계의 같은 오류 객체는 중복 기록하지 않는다. 기능 경계가 처리하고 기록한 실패를 다시 던지는 패턴은 피한다.

## 파일 한도와 동시 실행

기본 데이터 한도는 활성 파일 포함 5MiB × 3개 = 15MiB다. 별도 0바이트 lock 파일의 파일시스템 메타데이터는 제외한다.
공유 디렉터리의 고정 3슬롯에 OS exclusive lock을 두고 각 활성 프로세스는 다른 슬롯만 쓴다.
회전은 잠기지 않은 가장 오래된 슬롯을 재사용한다. 셋 모두 활성일 때는 자기 슬롯을 비우고 계속 쓴다.
네 번째 동시 writer는 파일 출력을 포기하고 제한된 대체 신호만 제공한다. 프로세스별 디렉터리로 총량을 무한 증가시키지 않는다.
정확한 시간순 보관은 보장하지 않는다. mtime은 재사용 선택에만 쓰고 경과 시간은 Stopwatch로 측정한다.

한 건은 최대 16KiB, 대기열은 64건(최대 1MiB + 처리 중 한 건)이다.
큰 기록은 제한된 요약으로 바꾸고, 큐 초과는 기록을 버리며 bounded drop 수를 제공한다.
파일/회전 I/O는 비동기이며 반복 동기 쓰기로 UI를 막지 않는다.
정상 종료 요청은 구독 해제→대기 기록 배출→flush/close/lock 해제 후 exit 응답한다.
강제 종료/충돌/전원 차단의 마지막 기록은 보장하지 않는다.
파일 생성/쓰기 실패는 해당 출력기를 중지하고 고정된 개발자 대체 신호를 한 번만 보낸다.
원래 오류 문자열을 다시 logging으로 보내지 않아 재귀를 막고, 무한 재시도하지 않는다.

## Flutter·Riverpod 경계

FlutterError.onError는 프레임워크가 잡은 오류를 기록한 뒤 기존 핸들러(기본 presentError)를 호출한다.
기존 프레임워크 콘솔 진단은 원문을 포함할 수 있으므로 개발/지원 시 별도 취급한다. 영속 파일에는 이를 복사하지 않는다.
PlatformDispatcher.onError는 root isolate의 미처리 오류를 기록한 뒤 기존 콜백의 반환을 유지하고, 없으면 false다.
기록만 하고 true로 바꾸지 않으며 VM fallback/종료 가능성을 유지한다.
Riverpod providerDidFail은 초기화/Future/Stream 실패를 관찰한다. 상태/오류 객체를 변환하지 않고 이름·상태를 덤프하지 않는다.
현재 앱 Provider 실패는 예상하지 못한 실패 경계다. 향후 예상 업무 거부는 기능 경계에서 issue로 처리하도록 설계한다.
동일 오류 객체의 중복은 약한 identity 표식으로 막는다. Riverpod ProviderException은 공개 exception 필드로 원인 동일성을 확인하며 문자열을 분석하거나 반환 예외를 바꾸지 않는다. 원시 String/숫자를 throw하는 패턴은 사용하지 않는다.
초기화/종료는 직렬화하고 구독·기존 handler/root level을 복구하여 테스트/재초기화 누적을 막는다.
runZonedGuarded를 겹치지 않는다. 자식 isolate는 생성자가 별도 오류 포트를 연결할 후속 책임이며 worker를 만들지 않는다.

## 검증 결과

계약을 먼저 기록한 뒤 아래 실제 검증 결과에 구현/실행 범위를 구분했다.
## 공개 예외 API의 변경과 소비자 처리

2026-10-27 변경이다. 업무 값의 허용 조건·JSON·기하 계산은 바꾸지 않았다.
예외/issue 생성자는 코드에 맞는 상세를 런타임 검사하므로 const 생성자가 아니다.
invalidType은 각 계열 TypeDetails의 expectedType/actualType이 필수이며 빈 타입 이름을 거부한다.
GeometryTagDetails는 supportedValues를 필수로 받아 방어 복사한다.
TextInputModeDetails는 actualValue와 고정 지원 목록을 제공한다.
빈 ID/빈 문구/필수 키 누락처럼 코드와 경로만으로 원인이 정해지는 문구 오류에는 상세를 추가하지 않는다.
문구 CR/LF는 UTF-16 위치/코드 단위, 불일치는 원문·연결 길이/줄 수만 보존한다.
이는 문자열 오프셋 편집 API나 원문 보관 기능이 아니다.

| 오류 계열 | 필수 상세/허용 조합 | 원인/문맥 |
|---|---|---|
| 문구 | 타입, 미지원 mode, CR/LF, 불일치는 해당 TextInputDetails. 다른 코드는 null | 제품 중첩 경계가 원래 예외와 스택을 연결 |
| 기하 | 타입/태그/수치/구간/원호 계산/극점 중 코드별 타입. 구조 오류는 null | prefixed가 최초 예외/스택과 같은 diagnostic을 유지 |
| 도안 | 타입/빈 ID·미지정 참조/중복 위치, 구조 오류는 null | prefixed가 원래 issue 상세와 최초 예외/스택을 유지 |
| 제품 | 타입/ID/중복/참조/하위 영역 issue, 구조 오류는 null | 목록은 수정 불가·최소 한 건. 중첩 예외는 하위 타입과 스택을 유지 |

타입명만 맞는 진단은 입력 데이터의 재검증 결과가 아니다.
코드별 상세의 존재/유형과 명백한 잘못(빈 타입명, 지원 mode의 미지원 보고, CR/LF가 아닌 코드 등)을 막는다.
진단의 ID·인덱스와 전체 외부 자료의 사실 관계까지 예외 생성자가 재조회하지 않는다.
소비자는 예외를 만들기보다 모델/검증 API가 제공하는 진단을 처리한다.

~~~dart
try {
  TextAreaInput.fromJson({
    'areaId': 'title',
    'sourceText': 123,
    'lineBreak': {'mode': 'automatic'},
  });
} on TextInputValidationException catch (error) {
  if (error.details case TextInputTypeDetails(:final expectedType, :final actualType)) {
    // error.code, error.fieldPath, expectedType, actualType으로 분기한다.
    // 개발자용 toString/description을 UI의 확정 문구로 사용하지 않는다.
  }
}
~~~

상위 ProductDesignNestedException의 fieldPath는 products[...].textInputs[...] 같은 실제 소유 위치다.
cause는 원래 TextInputValidationException/GeometryValidationException/DesignValidationException이다.
causeStackTrace는 최초 실패, contextStackTrace는 문맥 연결 경계다. 같은 실패 스택을 문자열 분석하지 않는다.
중첩이 여러 단계여도 이전 cause와 상세 객체를 유지한다.
직접 prefixed를 호출하는 소비자는 catch의 stackTrace를 전달해야 최초 스택을 연결할 수 있다.
기존 코드·JSON·필드 경로 의미는 유지하며 예외 생성자 const 사용 및 상세 없는 생성은 수정이 필요하다.
호환 별칭은 추가하지 않았다.

## 현재 파일 책임

- workflow: lib/src/text_input_errors.dart, geometry/geometry_errors.dart,
  design/design_errors.dart, product/product_design_errors.dart — 각 오류 계열의 상세/설명/조합 검사.
- workflow의 모델/JSON 문맥 catch — 처리 가능한 해당 예외만 잡고 Error.throwWithStackTrace로 변환.
  geometry_path의 환산 퇴화 재분류는 원인 객체/스택을 함께 보존하며 다른 코드는 rethrow.
- 앱 app_log_event.dart — 허용 이벤트와 안전한 출력 변환. 임의 문구/외부 메시지는 받지 않음.
- 앱 app_logging.dart — root 레벨/구독/Flutter·Platform·Provider 경계/정상 종료 수명.
- 앱 rotating_file_log.dart — 앱 전용 고정 슬롯·한도·OS lock·비동기 쓰기.
  stdout/원격 전송/로그 조회 UI/업무 이력은 구현하지 않음.

path_provider 추가 해결 결과(앱만): 2.1.6, Windows 2.3.0.
다중 플랫폼 전이 의존성으로 code_assets/ffi/hooks/jni/jni_flutter/jni_util/objective_c,
각 플랫폼 path_provider 구현/platform_interface/platform/plugin_platform_interface/record_use/xdg_directories가
pubspec.lock에 추가됐다. Windows는 실제 path_provider_windows 경로를 사용한다.
jni는 다른 플랫폼 구현에서 따라온 FFI 등록 정보이며 앱 업무 의존성을 추가한 것이 아니다.
일괄 업그레이드/SDK 변경/overrides는 하지 않았다. 라이브러리 의존성은 그대로다.



## 실제 검증 결과 (2026-10-27)

- 프로젝트 전용 Flutter 3.47.7/Dart 3.13.5를 사용했다. SDK/업무 값 조건/JSON/기하 계산은 변경하지 않았다.
- workflow: 명시적 코드 생성 후 전체 verify 성공. 첫 생성 일치·반복 생성 안정성·포맷·analyze(No issues)·전체 447개 테스트.
  새/보완 진단 파일 단독 실행(문구 10개·제품 8개) 성공.
  assert 비활성 AOT 6개 실행과 생성기 없는 독립 소비자 컴파일/실행 성공.
  소비자는 기존 참조·지정 한 줄과 새 공개 타입 진단을 함께 확인했다.
- 앱: 명시적 생성 후 전체 verify와 --windows 성공. 생성 일치·반복 안정성·포맷·analyze(No issues)·28개 테스트.
  app_logging_test.dart 7개와 rotating_file_log_test.dart 5개 단독 실행 성공.
  Windows debug/release 빌드·실제 시작 화면 실행 확인. 실제 로컬 JSONL의 시작/정상 종료 이벤트를 확인했다.
  debug는 FINE routeChecked도 기록하고 release는 INFO 시작/종료만 기록했다.
  테마 변경은 UI가 없으므로 테스트로만 확인했다.
- 격리 임시 디렉터리에서 작은 한도로 실제 회전, 각 파일/총 보관 한도, 큰 UTF-8 한 건 요약, bounded 큐,
  쓰기 실패 한 번 대체/중단, close flush와 반복 close를 검사했다.
- 별도 Dart 프로세스 4개로 동시 lock을 실행했다. 앞 3개는 다른 슬롯, 네 번째는 unavailable이고 데이터 파일은 3개다.
- Flutter/Platform 기존 처리/반환 유지, Riverpod 동기 wrapper 및 Future 실패 원인 보존, 동일 원인 중복 방지,
  반복 초기화 구독/레벨/handler 복구, 원문/임의 메시지/로컬 경로 미출력을 검사했다.
- 원격 GitHub Actions·Linux/macOS/모바일 실행·강제 종료/디스크 고장/전원 차단 실험은 하지 않았다.
  자식 isolate·업무 I/O·배치 결과·저장·로그 조회/공유·원격 수집은 미구현이다.
- 기존 스테이징은 비어 있었으며 유지했다. 실제 저장소에 stage/commit/push/reset/checkout을 수행하지 않았다.

