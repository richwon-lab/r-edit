# DXF의 Flutter Windows 재현 실험 — 합성 샘플 실행 결과

2026-11-01. 최신 사용자 결정: **기존 DXF는 CAD·Type3에서 정상 동작이 확인된 기준 출력이다.**
이 경로를 유지하며 Type3 직접 입력·명목 크기 대응 재시험을 사용자에게 선행 조건으로 요구하지 않는다.
과거 글꼴 probe 문서의 외부 재시험 계획보다 이번 결정이 우선한다.
후속 사용자 결정으로 회사 파일 대신 새 합성 샘플 r_edit_flutter_text_probe.dxf와 명시한 H2GTRE.TTF를 사용했다. 회사 파일/생성 코드는 더 이상 대기 조건이 아니다.
기존 검증 사실과 새 Flutter 렌더링 성공·정밀 일치는 별도로 판단한다.

## 이전 회사 자료 조사 기록 — 현재 대기 조건 아님

두 저장소에서 DXF/TTF/OTF/TTC와 Python 생성 코드를 찾았으나 실제 입력은 확보하지 못했다.
SDK/캐시/빌드는 제외했으며 사용자 디스크 전체를 검색하지 않았다.
형제 workflow의 글꼴 probe가 조사한 설치 H2GTRE.TTF는 현장 파일과 동일성이 확인되지 않아 자동 연결하지 않는다.

| 기록상 파일/위치 | 실제 확인 |
|---|---|
| docs/development-reference/reference/verification-supplement/req_work/dxf_export_v07/package/01_Quick12_R2000.dxf | 없음. 안내문과 results.json만 존재 |
| 같은 폴더 experiment.py·requirements.txt·source_design.dxf | 없음 |
| req_work/type3_title_border_r02/package/Type3_title_border_R02_R2000.dxf | 없음. 확인방법.txt 존재 |
| 해당 수정본의 (리)HY견고딕_3.TTF / 내부 이름 (리)HY견고딕 | 안내문에 기록되어 있으나 파일 없음 |
| req_work/font_size_probe_v01/package/01_FontSize_Check_R2000.dxf·make_probe.py | 없음. 안내문만 존재 |

현행 요구사항 추출본 v0.13에는 v0.7의 정렬·폰트·크기·자폭 사용자 확인과 v0.10 출력 정상 확인이 기록되어 있다.
과거 개별 package 안내의 '재확인 못함'을 최신 사용자 확인보다 우선하지 않는다.
기존 결과 JSON의 해시/좌표/재읽기 기록만으로 실제 DXF의 엔티티·인코딩·STYLE을 조사했다고 하지 않는다.
새 유사 DXF를 만들어 검증된 원본으로 대체하지 않았다.

이전 조사에서 요청했던 회사 DXF/생성 코드는 현재 작업의 선행 조건에서 제외했다. 사용자가 제공한 합성 샘플을 아래 위치에서 직접 읽었다.
CAD/Type3 재시험·글꼴 업로드·고객 자료 외부 전송은 요구하지 않는다.

## 후보 소스 조사와 격리 실험의 선택

공식 pub.dev 배포 archive를 Git 제외 `.tooling/dxf-render-research/`에만 내려받아 읽었다.
운영 pubspec은 보존했다. 아래 소스 조사 후 별도 실험 pubspec에만 dxf 3.1.3을 추가해 고정 SDK의 의존성 해결·분석·테스트·Windows 실행을 확인했다.

| 접근 | 실제 조사 | 판단 |
|---|---|---|
| dxf_viewer 0.0.3 | BSD-3-Clause. 2025-02-12 배포. SDK >=3.0.5 <4, Flutter >=1.17.0. DxfText.draw는 height×1.5, 기본 TextStyle, TextAlign.justify 및 삽입점 기반 오프셋을 사용 | 파일별 글꼴·폭 비율·회전·DXF 수평/수직 정렬·정렬점을 처리하지 않는 현재 구현을 정확한 TEXT 렌더러로 채택하지 않음 |
| dxf 3.1.3 + 별도 Canvas/FontLoader | MIT. 2023-11-30 배포. SDK >=2.17 <4, 직접 runtime 의존성 없음. AcDbText의 공개 속성은 위치/높이/문구 중심이며 STYLE/자폭/정렬점 등 별도 대조 필요 | 샘플이 실제 사용하는 group 값을 손실 없이 전달할 수 있는지 먼저 확인. 소규모 파서 보완과 renderer를 분리하는 방향을 우선 검토 |

배포 SDK 제약을 확인한 뒤 dxf 3.1.3+공식 Canvas/FontLoader 방식을 실제 고정 SDK에서 해결·빌드했다. viewer의 Windows 호환 실행은 하지 않았다.
확인 당시 pub.dev 표시는 viewer 2 likes/145 downloads, dxf 30 likes/2.52k downloads였다.
이는 기간·집계가 바뀌는 참고치이며 정확성/유지보수 보장이 아니다. 마지막 배포일만으로 유지 종료를 단정하지 않는다.
기존 dart_dxf_probe02/dxf_feasibility 기록에도 dxf 3.1.3의 속성 보존·이동·INSERT 제한이 있다.
읽기 전용 실험에서도 숨은 손실 여부를 실제 샘플과 고정 기대 group 값으로 확인해야 한다.

출처(2026-11-01): [viewer 배포](https://pub.dev/packages/dxf_viewer),
[viewer 공식 소스](https://github.com/micruo/dxf_viewer),
[dxf 배포](https://pub.dev/packages/dxf), [dxf 공식 소스](https://github.com/chuyentt/dxf).
확인 archive SHA-256:
- viewer 0.0.3: 528FACA5565502E045371150C3680983E331418CF05B467AEECCACA3ADB0D15B
- dxf 3.1.3: 4955E955B3F471B5441237F0B9B95D4955F094E8FE6B90F5810AC9FEB30A712B

## 실제 입력과 이동 위치

원래 `C:\work\richwon\r_edit\r_edit_flutter_text_probe.dxf`를 다음 위치로 이동했다.

[tool/experiments/dxf_flutter_probe/fixtures/r_edit_flutter_text_probe.dxf](../tool/experiments/dxf_flutter_probe/fixtures/r_edit_flutter_text_probe.dxf)

이동 전후 SHA-256은 `5a731d652c82d3ea46ebac5dfb14c56397dcefb0dd028ca2cc31fdf21c3eddc7`로 동일하다.
DXF bytes·인코딩·원문은 수정하지 않았다. 이 샘플을 회사의 검증 DXF 자체라고 표현하지 않는다.
기존 CAD·Type3 검증 경로는 유지하며 이번 성공을 그 외부 경로의 새 정밀 검증으로 확대하지 않는다.

실제 읽은 내용: AC1015/R2000, INSUNITS=4(mm), DWGCODEPAGE=ANSI_1252.
파일 bytes는 ASCII이고 한글은 `\U+D55C\U+AE00`로 저장되어 있다. group value는 trim하지 않는다.
ENTITIES에는 LINE 16개와 TEXT 10개가 있다. 프레임은 (0,0)~(240,140).
사용 중 STYLE PROBE_HY_GOTHIC은 H2GTRE.TTF, 높이 0·폭 1·기울임/반전 0이다.
미사용 Standard의 txt 참조를 텍스트 글꼴로 대신 선택하지 않는다.

실제 글꼴은 `C:\Windows\Fonts\H2GTRE.TTF`를 읽기 전용으로 명시 로드했다.
내부 HY견고딕/HYGothic-Extra, Regular, Version 1.00, PostScript H2gtrE를 확인했다.
SHA-256은 `820d3212f688b546a327ea43a7202e3379cdbbd767ebac9753997e3f3d285171`, UPEM=1024.
이 연결은 사용자의 명시적 지정과 실제 메타데이터에 근거하며, 과거 `(리)HY견고딕_3.TTF`와 동일하다고 추정하지 않았다.
글꼴을 복사·수정·Git 등록·외부 전송하지 않았다. 임베딩/배포 허가는 별도 검토이며 이번 로컬 로드로 확정하지 않는다.

## 구현과 수치 해석

독립 프로젝트는 [tool/experiments/dxf_flutter_probe](../tool/experiments/dxf_flutter_probe/README.md)다.
이전의 `.tooling/experiments/` 계획 대신 재현 소스를 남길 수 있는 tool/experiments에 두고,
해당 프로젝트의 build/.dart_tool/IDE 파일과 앱 `.tooling/dxf-render-results/` 실행 자료를 Git 제외했다.
운영 앱 세션·라우트·공개 API, workflow는 연결하거나 수정하지 않았다.

실험에만 dxf 3.1.3(MIT), crypto 3.0.7(BSD-3-Clause, 파일 식별), flutter_lints 6.0.0 및
고정 Flutter SDK의 flutter_test/integration_test를 사용했다. 후자는 실제 Windows UI/프레임 검사에 사용한다.
Windows runner는 고정 SDK의 flutter create로 만들었고 실험 창 이름만 변경했다. 전역 PATH/SDK·루트 의존성/lock·CI는 그대로다.

| 책임 | 실제 구현 |
|---|---|
| DXF 입력 | 기존 dxf 공개 groupCodes 재사용, 필요한 HEADER/STYLE/LINE/TEXT만 좁게 해석. 일반 CAD parser나 writer를 새로 만들지 않음 |
| 글꼴 | 해당 bytes를 SHA별 고유 family의 FontLoader로 로드. sfnt name/metrics/cmap format4로 사용 문자 glyph 검사 |
| 크기 | DXF height를 cap-height로 해석. 이 font에는 OS/2.sCapHeight가 없어 A.yMax−x.yMin=784 font units를 명시적으로 사용 |
| em 변환 | TextPainter 기준 fontSize=UPEM(1024), Canvas 배율=height/784. 문구별 재맞춤이나 눈대중 배수 없음 |
| 자폭 | Text 엔티티 폭×STYLE 폭을 X 좌표/advance/글자 형상에 함께 적용. Y 유지 |
| 정렬 | baseline 좌/중/우(72=0/1/2, 73=0). 좌측은 group10, 중앙/우측은 group11, 실제 TextPainter advance로 이동 |
| 회전·좌표 | DXF 도면 X 오른쪽/Y 위쪽. 화면으로 Y를 한 번 뒤집고 회전 부호도 변환. mm와 화면 배율 분리 |
| 화면 | 경로 입력·불러오기·확대/축소·드래그 이동·전체 보기·기준점/정렬점/논리 경계·상태/진단·새 경로 캡처 |

cap-height 해석의 근거는 [ezdxf TEXT 설명](https://ezdxf.readthedocs.io/en/stable/dxfentities/text.html),
기준 glyph 메트릭의 선행 예는 [ezdxf ttfonts 소스](https://github.com/mozman/ezdxf/blob/master/src/ezdxf/fonts/ttfonts.py)다.
이 Python 도구를 설치/실행하거나 기존 출력 경로를 바꾼 것은 아니다.
실제 Flutter API는 [FontLoader](https://api.flutter.dev/flutter/services/FontLoader/load.html),
[TextPainter baseline](https://api.flutter.dev/flutter/painting/TextPainter/computeDistanceToActualBaseline.html)을 사용했다.
공식 근거 확인일은 2026-11-01이며 이 규약만으로 특정 CAD/Type3와의 정밀 일치가 증명되지는 않는다.

높이 2/3/5의 em 길이는 각각 2.6122448979591835 / 3.9183673469387754 / 6.530612244897959 mm다.
이는 **이번에 명시한 cap-height 모델로 계산한 값**이며 외부 프로그램의 실측값은 아니다.
UI의 '높이=em 가정'은 다른 의미를 비교하기 위한 명시적 모드로 구분했다.
원문 공백·끝 공백·한글을 보존하고 줄바꿈/자동 맞춤을 하지 않는다. 첫 시험은 kerning/liga off다.
청록 상자는 실제 advance×cap-height의 **논리 상자**이며 glyph 잉크·충돌 판정 경계가 아니다.

## 실제 검증과 화면

- 고정 Flutter 3.47.7 / Dart 3.13.5로 실험 pub get·format·strict analyze --fatal-infos 성공(No issues found).
- 관련 단독 테스트 20건 성공: 샘플 해시, LINE/TEXT/STYLE, 고정 높이/폭/좌표/한글/공백,
  내부 font 식별·UPEM·cmap, 누락 glyph, 정렬/자폭/회전/Y 변환, 미지원 도형/정렬·인코딩·잘못된 파일 구조.
- Windows debug 빌드 및 실제 exe 실행 성공. 실제 Windows 통합 테스트 1건 성공:
  지정 font+10TEXT 표시, 확대/드래그/전체 보기, 기준 입력·상대 배치 유지, 없는 font 경로에서 이전 장면 유지,
  임시 DXF 복사본의 ALIGNED 정렬 거부·위치 진단, 원본 재로드와 캡처를 확인했다.
- 첫 통합 검사에서는 Z축까지 포함하는 getMaxScaleOnAxis를 2D 배율로 잘못 비교해 검사 실패했다.
  화면의 X/Y 배율을 검사하도록 테스트를 수정한 뒤 재실행 성공했다. 실패를 성공으로 기록하지 않았다.
- 실제 Windows 렌더 직전 입력 JSON을 원본의 고정 기대값과 대조했다. 높이/폭/한글/끝 공백/좌·중·우 anchor,
  fontSize 기준 1024와 DXF/font 해시가 유지됐다. 파서 왕복만으로 판단하지 않았다.

실행 자료는 별도의 새 경로에 저장했다. 각 폴더에 screen.png와 render-inputs.json이 있다.

| 관찰 | 로컬 경로 |
|---|---|
| 최종 정상 표시 | [.tooling/dxf-render-results/1793531131668438/screen.png](../.tooling/dxf-render-results/1793531131668438/screen.png) |
| 확대·드래그 후 | [.tooling/dxf-render-results/1793531129319788/screen.png](../.tooling/dxf-render-results/1793531129319788/screen.png) |
| 파일 오류·이전 도면 유지 | [.tooling/dxf-render-results/1793531130177458/screen.png](../.tooling/dxf-render-results/1793531130177458/screen.png) |
| 미지원 정렬·거부 1건 | [.tooling/dxf-render-results/1793531130902443/screen.png](../.tooling/dxf-render-results/1793531130902443/screen.png) |
| 최종 수치/원문 근거 | [.tooling/dxf-render-results/1793531131668438/render-inputs.json](../.tooling/dxf-render-results/1793531131668438/render-inputs.json) |

위 캡처는 **실제 Windows 실행 앱의 RepaintBoundary**에서 얻었다. OS 창 테두리 캡처나 합성 그림이 아니다.
컴퓨터 사용 도구의 OS 화면 접근 승인은 두 번 시간 초과되어 OS 입력 자동화는 실행하지 못했다.
대신 공식 Windows integration_test가 실제 실행 창에서 앱의 버튼/gesture를 구동했고, 저장한 프레임을 직접 시각 확인했다.
외곽과 텍스트가 같이 보이며, 한글·영문이 뒤집히거나 임의로 줄바꿈되지 않았고, 좌/중/우 정렬과 폭 차이가 보였다.
확대·이동 화면에서 viewport 밖 영역이 잘리는 것은 이동에 따른 화면 clipping이며 텍스트의 줄 레이아웃 잘림과 구분한다.
캡처에는 로컬 경로가 보일 수 있어 Git 제외 상태로만 두며 자동 전송하지 않는다.

## 실패·미확인 범위

- FontLoader 성공과 sample cmap coverage는 확인했지만 Flutter가 실제 사용한 face를 glyph별로 반환하는 검사는 없다.
  fallback 부재의 완전한 증명·복잡한 script/결합 문자 지원을 주장하지 않는다.
- 회사 도면·기존 CAD 화면/윤곽 비교 자료를 사용하지 않았다. 기존 외부 검증은 유지하되 **이번 Flutter 정밀 일치는 미검증**이다.
  사용자에게 Type3 직접 입력·크기 대응 재시험을 필수로 요구하지 않는다.
- 현재 전체 보기의 drawingSize/화면 원점은 이 240×140 mm 합성 샘플 문맥에 고정되어 있다. 다른 도면 범위의 자동 extent 맞춤까지 검증/지원한다고 하지 않는다. 선 색·두께도 관찰용 표현이며 DXF layer별 모든 표시 속성을 재현한 것은 아니다.
- 실제 샘플은 회전 0·baseline 정렬이다. 회전 변환은 수치 테스트만 했으며, 회전된 외부 자료의 시각 정확성은 별도다.
- LINE/TEXT 외 엔티티, SHX, MTEXT, bigfont, ALIGNED/FIT/MIDDLE, 비baseline 수직 정렬, 기울임/반전,
  고정 높이 STYLE, 3D/다른 단위·비ASCII 코드페이지는 정상 표시로 보정하지 않는다.
  현재 시험에서 ALIGNED와 POINT는 위치/handle이 있는 진단을 확인했다. 미지원 전체 목록을 실제로 하나씩 검증한 것은 아니다.
- 글꼴/파일 실패 시 기본 font·0폭·가짜 사각형으로 대체하지 않는다. 일부 미지원은 화면에 거부 건수/위치를 표시한다.
- 앱 운영 코드·workflow가 그대로여서 운영 전체 verify/AOT·원격 CI는 반복하지 않았다.

## 재현과 다음 한 가지

```powershell
# r_edit 루트, 기존 고정 SDK를 사용하고 실험 디렉터리에서만 명령 실행
./tool/experiments/dxf_flutter_probe/run.ps1 -Action get
./tool/experiments/dxf_flutter_probe/run.ps1 -Action analyze
./tool/experiments/dxf_flutter_probe/run.ps1 -Action test
./tool/experiments/dxf_flutter_probe/run.ps1 -Action windows-test
./tool/experiments/dxf_flutter_probe/run.ps1 -Action run
```

화면에서 기본 두 경로 확인 → 불러오기 → 확대/이동/전체 보기로 확인한다. 화면·입력 근거 저장은 새 결과 폴더를 만든다.
Windows 통합 테스트용 entrypoint와 일반 lib/main.dart 실행 파일은 구분하며 마지막 일반 빌드로 대화형 실행 파일을 준비했다.

이번 결과에서 좁은 DXF 읽기와 텍스트 배치/좌표 변환은 분리해 재사용 후보로 남길 수 있다.
운영 미리보기가 매번 DXF를 다시 읽는 구조나 이 제한된 parser를 운영 표준으로 확정하지 않는다.
다음 한 가지는 **이 합성 샘플 화면의 크기 해석·정렬·보조 표시를 검토해 운영 미리보기에서 재사용할 최소 렌더링 입력을 정하는 것**이다.
저장·재출력·배치 엔진·작업 세션 연결은 이번에 구현하지 않았다. 커밋·푸시·스테이징하지 않았다.