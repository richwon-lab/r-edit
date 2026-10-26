# R-edit 개발 문서 전체 목록

2026-10-19, 한국시간. 현재 요구사항과 구현 상태를 구분해 개발할 때 사용하는 전체 자료다.
앱용 초기 문서만 제공한 묶음의 누락을 보완했다. XLSX 원본을 텍스트 요약으로 대체하지 않았다.

## 먼저 읽을 순서

1. [현재 결정 사항](decisions.md): 이후 대화에서 확정한 저장 정책·줄바꿈·제조·공유 기준.
2. [기능 활용 점검표 XLSX](development-reference/reference/current/리치원_기능활용_점검표_v0.1.xlsx): 60개 기능, 17개 연결·지원 범위 항목과 이후 합의 메모. 실제 개발 대상과 사용 흐름 확인.
3. [데이터 논리 설계 DOCX](development-reference/reference/current/리치원_도안데이터_논리설계_초안_v0.1.docx): 데이터 관계·작업 파일·저장 단위 확인.
4. [요구사항 정의서 v0.7](development-reference/reference/current/리치원컴퍼니_업무소프트웨어_요구사항정의서_v0.7.docx): 전체 업무 범위 확인.
5. [핵심 요구사항 설계 검토 v0.13](development-reference/reference/current/리치원_핵심요구사항_설계검토_v0.13.docx): 계산·검사·후보 선택 등 검토 근거 확인.
6. [현재 모듈 경계](module-boundaries.md), [다음 작업](next-step.md).

## 개발 안내와 읽기용 추출본

| 자료                     | 위치                                                                                 |
|--------------------------|--------------------------------------------------------------------------------------|
| 저장소·패키지 구조       | [구조 안내](development-reference/docs/01-repositories.md)                           |
| 프로젝트 생성·환경       | [설정 안내](development-reference/docs/02-project-setup.md)                          |
| 변수·클래스·단위 네이밍  | [네이밍 기준](development-reference/docs/03-naming.md)                               |
| 독립 패키지 첫 구현 지시 | [Junie 작업](development-reference/docs/04-junie-tasks.md)                           |
| 최근 14개 독립 시험 목록 | [시험 목록](development-reference/docs/05-verification-inventory.md)                 |
| 공식 기술 자료           | [출처](development-reference/docs/06-official-sources.md)                            |
| Flutter·Dart 선택        | [기술 결정](development-reference/docs/07-technology-decision.md)                    |
| XLSX 읽기용 원문 추출    | [점검표 셀 값](development-reference/reference/text/리치원_기능활용_점검표_v0.1.txt) |
| 참고자료 구성           | [자료 분류와 폴더 안내](development-reference/README.md)                              |

별도 전체 파일 목록 CSV는 현재 저장소에 포함되어 있지 않다.

DOCX·XLSX를 직접 읽지 못하는 개발 도구는 reference/text의 추출본을 함께 읽는다.
문단·표·셀의 글을 옮긴 자료이며 도형·이미지·서식은 원본을 확인한다.

## 현재 기준과 과거 자료

- 사용자 최신 결정 → docs/decisions.md → 최신 데이터 설계 → 요구사항·설계 검토 순서로 해석한다.
- 점검표의 기존 Python 시험 통과를 새 Dart 제품의 구현 완료로 표시하지 않는다.
- 예전 첫 구현 계획의 단일 저장소와 이전 초안 저장 기능은 현재 초기 구현 방향과 다르다.
- previous-plans는 이전 첫 구현 계획·수동 작업/패턴 화면 흐름이며, archive는 요구사항·검토서·점검표의 이전 버전이다.
- verification은 최근 시험 기록, verification-supplement는 추가로 수집한 기존 시험 안내·결과다. 이번에 재실행하지 않았다.
- related-projects의 Illustrator·Type3 연구 자료는 별도 프로젝트 기록이다.
- 클래스·필드 예시, 미정 알고리즘, 지원하지 않은 형상·Type3 동작을 확정된 계약으로 간주하지 않는다.

이 전체 문서는 현재 앱 저장소에 함께 보관할 수 있다. 향후 문서 저장소를 분리할 때 경로와 채택 버전을 명시해 이동한다.
코드 패키지의 독립 저장소 원칙은 유지한다.
현재 개발 환경·기술 기준: [공통 개발 기반](development-foundation.md).

- [예외·진단·로깅 기준](failure-diagnostics-logging.md): 처리 소유권·기술 비교·로컬 파일 한도·전역 오류·실제 검사.
