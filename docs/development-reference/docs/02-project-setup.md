> 현재 앱 프로젝트는 로컬에서 r_edit로 생성하는 절차를 진행했다. 기존 앱을 재생성하지 않고 이 문서를 재개 참고로 사용한다.

# 프로젝트 생성 순서

## 1 개발 환경

Flutter/Dart와 Junie를 함께 쓰려면 **IntelliJ IDEA + Flutter/Dart 플러그인 + Junie**를 권한다.
Android Studio도 대안이다. Rust 언어·Rust 프로젝트를 추가할 필요는 없다. 설치한 IDE에서 Dart·Flutter 기술이 활성화됐는지 확인한다.

PowerShell에서 다음을 확인한다.

```powershell
flutter --version
dart --version
git --version
flutter doctor -v
```

Flutter SDK에 포함된 Dart를 기준으로 패키지와 앱의 SDK 범위를 맞춘다. 팀에서 선택한 버전을 README에 기록한다.
Windows 앱 빌드에는 Visual Studio의 `Desktop development with C++` 도구가 필요하다. IntelliJ IDEA를 편집기로 써도 Windows 빌드 도구는 별도다.
현재 순수 Dart 패키지 작업과 나중의 Windows 앱 실행을 구분하고, 앱 단계에서는 `flutter doctor -v`의 Windows·Visual Studio 항목 및 `flutter devices`를 확인한다.

## 2 로컬 작업 폴더

`C:\develop\richwon`은 예시다. GitHub에서 관리하는 소스는 로컬 개발 폴더에 두고, 실제 발주 자료를 공유하는 Drive 기준 폴더와 구분한다.
GitHub 저장소는 하이픈 이름, 로컬 Dart 프로젝트 폴더는 패키지명과 같은 밑줄 이름으로 통일하는 안이다.

| 로컬 폴더 예 | 연결할 GitHub 저장소 |
|---|---|
| `C:\work\richwon\r_edit_docs` | `ORG/r-edit-docs` |
| `C:\work\richwon\r_edit_workflow` | `ORG/r-edit-workflow` |
| `C:\develop\richwon\nameplate_text_layout` | `ORG/nameplate-text-layout` |
| `C:\develop\richwon\nameplate_dxf_export` | `ORG/nameplate-dxf-export` |
| `C:\work\richwon\r_edit` | `ORG/r-edit` |

각 폴더가 별도의 Git 저장소다. 공통 부모 폴더를 하나의 코드 저장소로 만들지 않는다.

## 3 문서 저장소

압축을 푼 자료 폴더의 **내용 전체**를 `r_edit_docs`로 복사한다. 해당 폴더에서 Git을 초기화한다.
예전 문서 원본은 보존하고 현재 결정은 DECISIONS.md에 모은다. 실제 조직명을 확인한 뒤 GitHub에 대응 저장소를 만든다.

## 4 첫 코드 프로젝트

아직 같은 이름의 프로젝트 폴더가 없는 위치에서 실행한다. 아래 명령은 사용자의 로컬에서 실행할 안내이며 이 자료를 작성하며 실행한 결과가 아니다.

```powershell
New-Item -ItemType Directory -Path C:\develop\richwon -Force
Set-Location C:\develop\richwon
dart create -t package r_edit_workflow
Set-Location .\r_edit_workflow
```

이 폴더를 IntelliJ IDEA에서 Open한다. `templates/r_edit_workflow/AGENTS.md`를 이 저장소 루트에 복사하고 Junie Project Settings의 Guidelines path를 `AGENTS.md`로 지정한다.
시작 템플릿의 예제 함수와 시험은 첫 모델 구현에서 교체한다. 실제 프로젝트 목적을 README에 작성하고 사내 전용 패키지는 `pubspec.yaml`에 `publish_to: none`을 지정한다.

```powershell
dart pub get
dart analyze
dart test
git init -b main
```

첫 구현 지시는 [Junie 작업](04-junie-tasks.md)의 작업 1이다. GitHub 조직명·저장소 이름을 확인한 후 원격 저장소를 연결한다.
공유 전에 고객 발주 원본이나 상용 폰트 파일이 예제에 섞여 있지 않은지 실제 포함 내용을 확인한다.

## 5 다음 라이브러리와 앱

모델과 파일 입출력의 작은 완료 단위를 만든 뒤 엔진, 앱, 출력 순서로 연결한다. 각 단계의 시작 시점에 필요한 프로젝트만 생성한다.

```powershell
# 배치 엔진 작업을 시작할 때 부모 폴더에서 실행
dart create -t package nameplate_text_layout

# DXF 출력 작업을 시작할 때 부모 폴더에서 실행
dart create -t package nameplate_dxf_export

# 앱 연결을 시작할 때 부모 폴더에서 실행
flutter create --platforms=windows r_edit
```

## 6 독립 저장소의 의존성

통합 시에는 Git 의존성을 특정 릴리스 또는 커밋으로 고정한다. `main`을 따라가게 해서 모든 앱이 뜻하지 않게 최신 엔진을 받게 하지 않는다.
동시에 수정할 때는 소비하는 패키지의 `pubspec_overrides.yaml`에서 형제 폴더를 지정할 수 있다.
실제 예시는 `templates/dependencies/`에 있다. 조직명·커밋 자리표시자를 실제 값으로 바꾸고, 존재하는 패키지를 연결할 때만 사용한다.
로컬 override 파일은 `.gitignore`에 넣고 배포 확인에서는 override를 제거한 의존성을 확인한다. 앱의 lockfile은 Git으로 관리해 채택한 의존성을 재현한다.

## 7 첫 완료 단위

작업 파일과 제품 두 개를 모델로 표현한다. 자동 줄바꿈 정상 결과 하나와 직접 지정·작업자 확인 결과 하나를 저장하고 다시 읽는다.
공백·줄 경계·영역 연결·판정·사유·확인이 유지되고, 수량 변경과 문구 변경의 영향이 구분되면 첫 단위를 마친다.
순수 Dart 라이브러리의 동작 확인에 Flutter UI를 먼저 만들 필요는 없다.

공식 근거는 [기술 자료](06-official-sources.md)에 모았다.
