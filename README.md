# R-edit

명판 문구 배치 및 제작 파일 작성 프로그램. Flutter와 Dart로 개발하는 Windows 데스크톱 앱이다.

## 저장소 역할

이 저장소는 화면, 사용자 입력, 도안 미리보기, 업무 명령 연결과 Windows 연동을 담당한다.
제품 입력·배치 결과 확인·저장 정책, 문구 배치 알고리즘, DXF 작성은 책임별 독립 Dart 패키지로 개발한다.

| 구분 | 식별자 |
|---|---|
| 프로그램 표시 이름 | R-edit |
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
flutter analyze
flutter test
flutter run -d windows
```

현재 채택한 SDK 버전과 실제 실행 결과는 로컬에서 확인한 후 기록한다.
이 README가 추가됐다는 이유만으로 기능 구현이나 실행 검증이 완료된 것은 아니다.

## 현재 개발 범위

초기 작업은 Flutter 기본 프로젝트와 Git 연결, 개발 문서 정리다.
다음 실제 기능은 별도 순수 Dart 패키지의 작업 데이터 모델과 저장 정책부터 구현한다.
아직 생성되지 않은 라이브러리를 pubspec.yaml에 선언하지 않는다.

전체 요구사항·논리 설계·검증 근거는 기존 개발 참고자료 묶음을 사용한다.
중앙 문서 저장소 r-edit-docs를 구성하면 채택한 기준 문서 경로와 커밋을 이 문서에 연결한다.
현재는 생성되거나 연결된 것으로 가정하지 않는다.
