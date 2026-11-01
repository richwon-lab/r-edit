# DXF / 실제 글꼴 Flutter Windows 격리 실험

운영 앱·workflow와 연결되지 않은 읽기 전용 실험이다. [실행·제한 기록](../../../docs/dxf-flutter-render-probe.md)을 따른다.
이 프로젝트 루트에서 실행해야 상대 fixture와 결과 경로가 맞는다. 아래 runner가 작업 위치를 고정한다.

```powershell
# r_edit 루트에서. 전역 PATH/SDK를 사용하지 않는다.
./tool/experiments/dxf_flutter_probe/run.ps1 -Action get
./tool/experiments/dxf_flutter_probe/run.ps1 -Action analyze
./tool/experiments/dxf_flutter_probe/run.ps1 -Action test
./tool/experiments/dxf_flutter_probe/run.ps1 -Action windows-test
./tool/experiments/dxf_flutter_probe/run.ps1 -Action run
```

Flutter 3.47.7 / Dart 3.13.5의 기존 `.fvm/flutter_sdk`를 재사용한다. 별도 SDK나 override를 만들지 않는다.
실험 pubspec/lock·Windows runner·소스·합성 fixture는 Git 관리 대상, build/.dart_tool/IDE 설정은 제외한다.
실제 TTF는 넣지 않는다. 기본 경로는 `C:\Windows\Fonts\H2GTRE.TTF`이며 없으면 명시적으로 실패한다.
테스트는 이 지정 파일의 SHA/name/UPEM/glyph 고정값을 사용하므로 파일이 다른 환경에서는 현장 글꼴 성공으로 대체하지 않는다.

실험 파일은 루트 `r_edit_flutter_text_probe.dxf`에서 `fixtures/r_edit_flutter_text_probe.dxf`로 이동했다.
바이트를 수정하지 않았으며 SHA-256은 `5a731d652c82d3ea46ebac5dfb14c56397dcefb0dd028ca2cc31fdf21c3eddc7`이다.
사용자가 제공한 합성 샘플이며 회사 검증 DXF 자체가 아니다. 회사 자료/생성 코드는 더 이상 선행 조건이 아니다.

불러오기 → 전체 보기/확대/축소/마우스 이동 → 필요 시 보조 표시 끄기 → 화면·입력 근거 저장을 사용한다.
저장 결과는 앱 루트 `.tooling/dxf-render-results/<새 실행 식별>/screen.png`, `render-inputs.json`이며 기존 결과를 덮어쓰지 않는다.
원본 DXF/TTF는 읽기만 한다. 화면 캡처에는 입력 경로가 보이므로 외부 공유 전 확인한다. 자동 업로드하지 않는다.

## 범위

- dxf 3.1.3 공개 groupCodes 사용. LINE, 평면 TEXT, mm(INSUNITS=4), ASCII 전송+`\U+XXXX`만 지원.
- 스타일 파일명과 명시 로드 파일명, 내부 family/PostScript 이름을 검사하고 bytes hash를 표시 근거에 기록한다.
- FontLoader에 해당 bytes를 고유 family로 로드. cmap format4와 sample ASCII/완성형 한글 glyph 확인.
  엔진이 실제 사용한 face를 glyph별로 조회하는 기능은 없으므로 fallback 부재의 완전한 증명은 아니다.
- TEXT 높이/자폭/회전, baseline 좌/중/우(72=0/1/2,73=0), 삽입점/정렬점 적용. 특별 정렬·반전·기울임·고정 높이 STYLE/bigfont/SHX·MTEXT·다른 엔티티는 미지원 진단.
- 전체 보기는 현재 240×140 mm 샘플 문맥에 고정되어 있다. 임의 도면의 extent/레이어 색/선 두께 전체 재현은 범위 밖이다.
- 화면 좌표는 `(80+4*x, 620-4*y)`에 viewport 변환을 적용한다. 4는 화면 확대 기준이며 글꼴 크기 보정 계수가 아니다.
- DXF height는 cap-height 규약으로 해석하며 em 배율은 `height / fontCapHeight`.
  해당 font는 sCapHeight가 없어 A.yMax−x.yMin=784 font units를 명시적 기준으로 사용한다(ezdxf 방식).
  TextPainter fontSize는 기준 UPEM=1024이고 Canvas로 배율을 적용한다. 별도 눈대중 배수는 없다.
  이 해석의 CAD/Type3 정밀 일치는 미검증이다. 비교용 height=em 모드는 명시적 가정이다.
- 문구마다 배율을 재맞춤하지 않는다. 공백·한글·끝 공백 보존, 자동 줄바꿈/자동 맞춤 없음.
- kerning/liga를 비활성화한 첫 시험 범위이며 복잡한 셰이핑 지원을 주장하지 않는다.
- 청록 상자는 실제 advance와 cap-height의 논리 상자다. 실제 잉크/충돌 경계라고 표시하지 않는다.
- 미지원 내용은 위치/handle과 함께 표시하고 부분 표시/파일 실패를 정상 전체 성공과 구분한다.
  파일 읽기 실패는 이전 표시를 유지하고 실패 상태를 명시한다. 입력 복구/저장/재출력 없음.

## 파일 책임

- lib/probe_drawing.dart: 기존 DXF 파서에서 필요한 header/STYLE/LINE/TEXT를 읽고 보존/미지원 진단.
- lib/font_evidence.dart: 실험용 sfnt 메트릭·내부 이름·cmap·glyph bbox/advance 읽기. 범용/보안 검증된 글꼴 parser 아님.
- lib/probe_scene.dart: baseline/advance/정렬/회전/자폭과 화면 좌표 변환.
- lib/main.dart: 경로 입력·FontLoader·표시·확대/이동·보조 표시·새 경로 캡처.
- test/probe_contract_test.dart: fixture·메트릭·수치 변환·실패·최소 UI.
- integration_test/probe_windows_test.dart: 실제 Windows 실행/텍스트/확대/이동/실패 보존과 렌더 화면 캡처.

운영 미리보기가 매번 DXF를 다시 읽는 구조로 채택된 것은 아니다. 성공/제한을 보고 파서와 좌표/텍스트 렌더링의 재사용을 따로 판단한다.
## 운영 CI와의 분석 경계

루트 pub get은 이 독립 패키지의 의존성을 설치하지 않는다. 루트 analysis_options.yaml에서
이 실험 경로만 제외하며 실험 자체의 분석 규칙이나 진단을 끄지 않는다.
로컬에 실험 package_config가 있어서 루트 분석까지 성공하는 상태를 CI 재현으로 간주하지 않는다.
실험은 위 get/analyze/test/windows-test 명령으로 따로 검증한다.
Windows·지정 로컬 글꼴이 필요한 실험을 운영 Ubuntu CI에 자동 연결하지 않는다.