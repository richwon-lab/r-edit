# 공통 개발 기반

결정·공식 자료 확인일: 2026-10-26. 앱 r_edit와 순수 Dart r_edit_workflow의 공통 기준이다.
각 저장소에 독립적으로 보관한다. 과거 비교·전환 기록보다 이 문서와 현재 pubspec/분석 설정이 우선한다.

## 기술·버전·책임

| 기술 | 채택 버전 | 적용 위치와 책임 | 중복시키지 않는 책임 |
|---|---|---|---|
| Flutter / 포함 Dart | 3.47.7 / 3.13.5 | 앱 실행, 두 저장소 개발·생성·검증 | workflow runtime에 Flutter 금지 |
| FVM | 4.3.2 | .fvmrc SDK 고정, 저장소별 도구·캐시 | 전역 PATH·다른 프로젝트 SDK 수정 금지 |
| Freezed / annotation | 4.0.3 / 3.1.0 | 불변 값 비교·복사 생성 | 업무 검증을 assert로만 구현하지 않음 |
| json_serializable / annotation | 6.15.2 / 4.12.0 | JSON 필드 변환 | 생성기 오류 문자열 분석·업무 검증 대체 금지 |
| build_runner | 2.16.2 | 개발 시 생성 실행 | 소비자에게 생성 작업 전가 금지 |
| flutter_riverpod | 3.4.3 | 앱 객체 제공·화면 상태 연결 | workflow 상태·업무 정책 소유 금지 |
| riverpod_annotation / generator | 4.0.7 / 4.0.9 | 앱 Provider 선언·생성 | 별도 DI 프레임워크 중복 도입 금지 |
| 생성자 주입 | Dart 언어 기능 | workflow의 실제 외부 협력 객체 전달 | 전역 컨테이너·빈 Repository 금지 |
| go_router | 17.1.0 | 앱 화면 이동 | 라우터에 업무 흐름 구현 금지 |
| logging | 1.3.0 | 앱 진입점 root 처리, 기능별 Logger | 업무 오류 반환·원문 저장 대체 금지 |
| very_good_analysis | 11.0.0 | 공통 분석 + strict 3종 | flutter_lints/lints 중복 include 금지 |
| Fake 우선 / mocktail | 1.0.5 검토, 미추가 | 실제 협력 객체 필요 시 작은 Fake, 상호작용 검증 필요 시 mocktail | 사용처 없는 대역·Mockito 직접 도입 금지 |

앱의 Freezed/JSON 도구는 기준만 준비했다. 가짜 업무 모델을 만들지 않았다.
workflow runtime에는 기존 annotation 두 개만 필요하다. 앱 상태·라우터·플랫폼·logging 의존성을 추가하지 않았다.
향후 실제 로그가 필요하면 logging과 생성자 전달 책임을 검토하고 라이브러리에서 root handler를 설치하지 않는다.
Riverpod 생성기의 전이 개발 의존성 mockito는 자체 테스트 도구 채택을 뜻하지 않는다.

## 호환성·선택 이유

- 공식 최신 stable Flutter 3.47.8 / Dart 3.13.7도 검토했다. 기존 workflow에서 검증한 3.47.7 / 3.13.5로 앱을 통일해 변경을 제한했다. beta 3.50은 채택하지 않았다. 다음 SDK 변경은 생성기 교집합·전체 검증·Windows 실행을 함께 확인하는 별도 변경으로 한다.
- Dart 하한은 ^3.13.5, 앱 Flutter 하한은 3.47.7이다. FVM은 실제 실행 SDK를 고정한다.
- Freezed 4.0.3과 Riverpod generator 4.0.9의 analyzer 교집합은 14.x다. 실제 해결 결과는 analyzer 14.6.0, build 4.0.11, source_gen 4.3.1, source_helper 1.4.0이다.
- 최신 build_runner 2.17.1의 build >=5 <5.1과 Riverpod generator의 build <5가 충돌한다. 2.16.2를 유지하며 dependency_overrides로 숨기지 않는다.
- json_serializable 6.14.1은 source_helper 1.4 계열 생성 충돌이 있었고 공식 6.15.1에서 수정했다. 6.15.2로 실제 생성 성공을 확인했다. 오래된 source_helper 고정에 의존하지 않는다.
- go_router 18.1.1은 material_ui/cupertino_ui 분리 의존성을 도입한다. 현재 단일 화면에는 전환 이득이 없어 17.1.0을 선택했다. SDK >=3.9, Flutter >=3.35 조건을 충족한다.
- 앱 lock은 추적한다. workflow 라이브러리 lock은 추적하지 않으며 실제 해결 결과를 기록한다. 미래 해결 결과가 영구히 같다고 주장하지 않는다.

## 공식 자료와 라이선스

2026-10-26 선택 버전 pubspec·공식 changelog/저장소·LICENSE를 확인했다.
발행일만으로 유지 상태를 판단하지 않는다. logging처럼 안정된 작은 패키지의 오래된 발행일 자체가 교체 근거가 아니다.

| 공식 자료 | 라이선스 | 확인 내용 |
|---|---|---|
| [Flutter stable 목록](https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json) | BSD-3-Clause | 3.47.7/Dart3.13.5와 최신 stable |
| [Freezed](https://pub.dev/packages/freezed/versions/4.0.3) | MIT | SDK·analyzer 제약 |
| [json_serializable 변경 기록](https://pub.dev/packages/json_serializable/changelog) | BSD-3-Clause | source_helper 충돌 수정 |
| [Riverpod 생성](https://riverpod.dev/docs/concepts/about_code_generation), [generator](https://pub.dev/packages/riverpod_generator/versions/4.0.9) | MIT | runtime/annotation/generator 번호는 서로 다름, build/analyzer 제약 |
| [go_router 17.1.0](https://pub.dev/packages/go_router/versions/17.1.0), [변경 기록](https://pub.dev/packages/go_router/changelog) | BSD-3-Clause | Flutter 팀 라우터, 18.x 전환 |
| [logging](https://pub.dev/packages/logging/versions/1.3.0) | BSD-3-Clause | Logger·Level·구독 책임 |
| [FVM 설정](https://fvm.app/documentation/getting-started/configuration), [패키지](https://pub.dev/packages/fvm/versions/4.3.2) | MIT | 프로젝트 고정·로컬 캐시 |
| [very_good_analysis](https://pub.dev/packages/very_good_analysis/versions/11.0.0), [엄격 분석](https://dart.dev/tools/analysis) | MIT | SDK ^3.13, strict 3종 |
| [build_runner](https://pub.dev/packages/build_runner/versions/2.16.2) | BSD-3-Clause | build 4 계열 |
| [mocktail](https://pub.dev/packages/mocktail/versions/1.0.5), [라이선스](https://pub.dev/packages/mocktail/license) | MIT | SDK·test_api 제약, 아직 의존성 아님 |

배포 시 패키지 저작권·라이선스 고지를 보존한다. 이 목록은 전체 전이 의존성의 배포 고지 산출물을 대신하지 않는다.

## 저장소 단독 설치·IntelliJ

Windows PowerShell에서 저장소 루트에서 실행한다. 최초 FVM에 bootstrap Dart가 필요하다.
Dart 3.13.5 이상 설치 경로를 명시할 수 있다. 이후에는 프로젝트 SDK를 사용한다.

~~~powershell
# 최초: 실제 설치된 Dart 경로로 바꾼다.
./tool/fvm.ps1 -BootstrapDart 'C:\개발SDK\bin\cache\dart-sdk\bin\dart.exe' use 3.47.7 --force --skip-pub-get
# 이후
./tool/fvm.ps1 flutter --version
./tool/fvm.ps1 dart --version
./tool/fvm.ps1 dart tool/verify.dart
# 앱의 Windows 네이티브 확인
./tool/fvm.ps1 dart tool/verify.dart --windows
./tool/fvm.ps1 flutter run -d windows
~~~

tool/fvm.ps1은 FVM 4.3.2를 .tooling/pub-cache에 설치하고 .tooling/fvm을 사용한다.
프로세스에서만 PUB_CACHE/FVM_CACHE_PATH를 설정하고 복구한다. 전역 PATH·사용자 전역 패키지를 변경하지 않는다.
bootstrap 경로를 생략하면 프로젝트 Dart, 없으면 PATH의 Dart를 사용한다. 낮은 SDK로 실패하면 호환 경로를 명시한다.
이미 FVM이 있으면 fvm use 후 fvm dart tool/verify.dart로 같은 검증이 가능하다.

IntelliJ Flutter SDK는 각 저장소 .fvm/flutter_sdk, Dart SDK는 .fvm/flutter_sdk/bin/cache/dart-sdk다.
workflow는 Dart SDK만 지정한다. 로컬 IDE 설정은 Git에 추가하지 않는다.
[공식 IntelliJ 안내](https://fvm.app/documentation/guides/android-studio)를 함께 따른다.

이번 설치는 기존 영구 workflow .toolchains/flutter-3.47.7을 저장소별 FVM 캐시 junction으로 재사용했다.
임시 SDK를 영구 경로로 지정하지 않았다. 현재 두 연결은 같은 SDK 실체이므로 flutter upgrade를 하지 않는다.
SDK 변경은 새 버전 FVM 경로를 설치하고 검증 후 각 .fvmrc/연결을 변경한다.
fresh clone은 형제 저장소 없이 FVM 다운로드로 설치된다. wrapper·CI에는 형제 경로가 없다.
기존 SDK tag 3.47.7의 해시는 공식 stable 목록의 abaf9c523780a608bd46686fd5e53740a07077f8와 일치한다.
tag checkout의 channel은 user-branch로 표시된다. 공식 해시를 대조했으며 archive SHA 검증을 했다고 주장하지 않는다.

## 지속 적용 규칙

- very_good_analysis와 strict-casts, strict-inference, strict-raw-types를 적용한다. 생성 소스·SDK·캐시·빌드·독립된 과거 비교 자료를 제외한다.
- 명시적 기존 스타일 예외: public_member_api_docs, lines_longer_than_80_chars, unnecessary_type_name_in_constructor, sort_constructors_first, unnecessary_lambdas, cast_nullable_to_non_nullable, no_default_cases, prefer_foreach, cascade_invocations.
- 문서 lint 예외는 기존 누락 추적용이며 신규 API 설명 면제가 아니다. nullable cast는 구조/타입 검사 뒤 JSON 경계와 의도적 오류 테스트에서만 허용한다. implicit dynamic·unchecked downcast를 추가하지 않는다.
- 영어 식별자/Dart 표기, 한국어 중심 주석·API·테스트 설명을 사용한다. 공개 생성자·필드·변환은 단위·불변식·실패 조건·검사하지 않는 책임을 설명한다.
- 공개 진입점만 소비한다. 오류는 책임별 전용 파일에 발생 조건·경로·형식 있는 진단을 둔다. 임의 Map·범용 오류 프레임워크·utils/common을 늘리지 않는다.
- 전용 변환·검증은 모델 가까이 두고 실제 공유 코드만 책임별로 분리한다. 모든 파일을 part로 묶지 않는다.
- test는 책임별 폴더, group은 대상·행동, test는 한국어 조건·기대 결과다. 독립 사례를 실행 이름으로 구분하고 파일 단독 실행을 유지한다. 키/issue 순서가 계약이 아니면 고정하지 않는다.
- 실제 객체로 충분하면 그대로 사용한다. 협력 객체는 Fake 우선, 상호작용 검증이 필요할 때만 mocktail 검토를 남긴다.
- .freezed.dart/.g.dart는 추적하고 직접 편집하지 않는다. 소비자가 생성 없이 사용할 수 있어야 한다.
- tool/verify.dart는 pub get → 생성 → 포맷 검사 → 최종 재생성 안정성 → 분석 → 전체 테스트다. workflow는 5개 assert 비활성 AOT·생성기 없는 별도 path 소비자도 실행한다. 앱 --windows는 네이티브 debug 빌드다. 시각 확인은 별도다.
- 포맷 수정은 프로젝트 Dart로 실제 변경 디렉터리·도구에 적용한다. 검증 명령은 포맷 불일치 시 실패하며 인덱스를 변경하지 않는다.
- 의존성 추가·교체는 실제 사용처/소유 모듈/역할 중복, 공식 유지·라이선스·SDK/생성기 제약, 대안·확인일을 기록한다. 해결·생성·분석·테스트와 필요한 AOT/Windows/소비자 검증을 실행한다.
- 임의 전체 업그레이드·overrides·빈 계층으로 문제를 숨기지 않는다. 업무 API/오류/JSON 의미 변경은 기반 설정에 섞지 않는다.
- 합성 예제·실제 실행·과거 기록·미실행을 구분한다. 미구현 저장·배치·제작을 완료처럼 표현하지 않는다.

## GitHub Actions와 무료 운용

.github/workflows/verify.yml은 로컬 tool/verify.dart를 재사용한다.
PR/main/master에서 Ubuntu 표준 러너, 앱은 수동 선택 Windows 빌드만 추가했다.
read-only token, SHA 고정 actions, 시간 제한, 중복 취소를 적용했다. 예약·배포·아티팩트/캐시 업로드는 없다.

[공식 과금 기준](https://docs.github.com/en/billing/concepts/product-billing/github-actions)에 따라 공개 저장소 표준 hosted runner는 무료다.
비공개는 플랜 무료 분량·Windows 비용 배수가 있으므로 기본 job을 건너뛴다.
소유자가 무료 잔량·지출 한도 0을 확인한 뒤 저장소 변수 ENABLE_PRIVATE_CI=true로만 활성화한다.
이번 작업은 계정 예산/변수 설정·원격 실행을 하지 않았다. 무제한 무료라고 보장하지 않는다.
[setup-dart](https://github.com/dart-lang/setup-dart)로 bootstrap을 설치하고 FVM으로 실제 고정 SDK를 연결한다.
Linux CI는 구성 검토이며 실제 Windows 로컬 실행과 구분한다.

## 보류 기술과 결정 시점

| 보류 기술 | 결정 조건·시점 | 결정 전 금지 |
|---|---|---|
| 작업 파일 저장·버전 | WorkDocument/미완료 상태/원자 저장·복구 계약 후 schema·파일 전략 비교 | 조각 JSON을 전체 파일로 사용 |
| 로컬 DB·검색 | 실제 조회·데이터량·검색 요구와 저장 소유권 후 SQLite/FTS 등 비교 | 임의 DB/Repository 도입 |
| 공용 등록·동기화 | 원본/스냅샷·충돌·오프라인·권한 정책 후 | 클라우드 SDK/자동 원본 재조회 |
| DXF·출력·인쇄 | 결과·정밀도·좌표/폰트/설비 요구 후 독립 패키지 선정 | 위젯에 출력/배치 로직 |
| 배치·폰트 측정 | 요청·문자 위치·지원 형상·진단 계약 후 | 형상 생성 성공을 제작 판정으로 사용 |
| 3D·렌더러 | 실제 2D 업무 필요·성능·플랫폼/라이선스 검토 후 | 임의 엔진/플러그인 추가 |
| 원격 로그·인증 | 운영 요구·문구 정보 보존/전송 정책 후 | 원문/토큰 자동 수집 |

보류는 구현자의 임의 선택을 허용한 것이 아니다. 조건 충족 시 비교 근거를 제시하고 사용자 결정 후 도입한다.

## CI 캐시 컨텍스트 수정 (2026-10-26)

이전 YAML 구조 검사만으로는 컨텍스트 사용 위치 오류를 검출하지 못했다.
workflow/job env에서는 runner 컨텍스트를 사용할 수 없어 실행 전에 검증이 실패했다.
[공식 context availability](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#context-availability)를 기준으로 수정했다.

고정 setup-dart 소스는 PUB_CACHE를 사용자 홈으로 다시 export하고 그 bin을 PATH에 추가한다.
따라서 setup-dart 직후에 RUNNER_TEMP 기준 pub-cache/fvm을 GITHUB_ENV로 등록하고,
pub-cache/bin을 GITHUB_PATH에도 추가한다. 이후 단계부터 적용되므로 초기화 단계 안에서
새 환경변수가 이미 설정됐다고 가정하지 않는다.
[공식 환경 파일 규칙](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#setting-an-environment-variable),
[고정 액션 구현](https://github.com/dart-lang/setup-dart/blob/6afc89df92d6eb3834022f73cd65adc8cdfcb92d/lib/main.dart)을 대조했다.

Ubuntu는 bash의 인용한 RUNNER_TEMP/GITHUB_ENV/GITHUB_PATH를 사용한다.
앱 Windows job은 pwsh의 Join-Path와 UTF-8 Out-File을 사용한다.
bootstrap Dart 다운로드는 setup-dart의 기존 SDK 설치 위치를 유지하며,
이후 pub global activate FVM, FVM의 Flutter SDK 설치, verify.dart의 pub get/생성/검증은
동일한 PUB_CACHE/FVM_CACHE_PATH를 상속한다. tool/fvm.ps1은 로컬 개발용이며 CI에서 호출하지 않는다.

실제 로컬 검사:
- actionlint 1.7.12로 수정 전 컨텍스트 오류 재현, 수정 후 두 workflow의 표현식·컨텍스트/스키마 검사 통과.
- 외부 ShellCheck/Pyflakes는 설치하지 않아 actionlint에서 비활성화했다.
- 추출한 Ubuntu 초기화 스크립트를 Windows Git Bash에서 구문 검사·실행하고,
  Windows 초기화는 PowerShell 파서·실행으로 검사했다. 공백·한글 경로에서 env/PATH 출력값을 확인했다.
- YAML 의미 비교로 SDK/패키지 버전, 권한, 무료 활성화 조건, 실행 조건/기존 명령 유지 확인.
- FVM 4.3.2의 환경설정 로더와 verify.dart의 PUB_CACHE 상속을 소스 대조했다.
- git diff --check와 기존 인덱스 보존 확인.

원격 Actions/실제 Ubuntu 러너의 전체 SDK 설치·검증은 재실행하지 않았다.
업무 코드 변경이 없어 생성·분석·Dart/Flutter 테스트·AOT·앱 빌드도 반복하지 않았다.
로컬 shell 초기화 검사를 원격 CI 성공으로 기록하지 않는다.
