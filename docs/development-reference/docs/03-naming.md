# 네이밍 기준

이름만 보고 대상·단위·동작을 예측할 수 있게 한다. 아래 영문명은 후보이며 실제 코드의 뜻과 맞을 때 채택한다.

## 업무 개념

| 업무 개념 | 이름 후보 | 의미 |
|---|---|---|
| 도안 작업 저장 자료 | `DesignWorkDocument` | 파일로 보관하는 완료된 도안 작업 |
| 실행 중 편집 작업 | `DesignWorkSession` | 미저장 편집·계산 진행·변경 영향을 관리 |
| 작업의 제품 항목 | `ProductItem` | 같은 문구여도 별도로 식별하고 수량을 관리 |
| 이번 작업의 적용 도안 | `AppliedDesign` | 실제 형상·영역·제작 조건과 출처 |
| 텍스트 영역 정의 | `TextRegionDefinition` | 위치·크기·역할과 식별 정보 |
| 제품의 영역별 입력 | `TextRegionInput` | 원문과 줄바꿈 지정 |
| 줄바꿈 방식 | `LineBreakMode.automatic`, `.userSpecified` | 줄 구성의 결정 방식 |
| 제품별 배치 결과 | `ProductLayoutResult` | 현재 입력에 대한 영역별 배치와 판정 |
| 결과의 작업자 확인 | `reviewedByOperator` | 해당 배치를 작업자가 확인했는지. 정상 판정이나 생산 보증과 다름 |
| 수량 출력 표현 | `QuantityPresentation` | 수량대로 도안을 복제하거나 도안 하나에 수량 표기 |

`isManual`은 무엇을 직접 정했는지 알 수 없어 사용하지 않는다. 줄바꿈 방식·도형 편집·결과 확인은 서로 다른 개념이다.
입력 방식과 계산 상태, 정상 판정과 작업자 확인을 하나의 `status` 값에 섞지 않는다. 필요한 상태 자체를 없애라는 뜻은 아니다.

## 단위와 원문

| 뜻 | 이름 후보 |
|---|---|
| 명판 가로 길이 mm | `plateWidthMm` |
| 명목 글자 높이 mm | `nominalTextHeightMm` |
| 자폭 배율 0~1 등의 비율 | `horizontalScaleRatio` |
| 홀 가장자리와의 요구 간격 mm | `holeEdgeClearanceMm` |
| 주문 수량 | `orderQuantity` |
| 실제 그린 명판 수 | `drawnPlateCount` |
| Drive 기준 상대 경로 | `driveRelativePath` |

명목 글자 높이와 실제 획의 높이를 같은 값으로 취급하지 않는다. 70과 0.7을 둘 다 `width`로 표현하지 않는다.
문자열 위치 단위는 아직 미정이다. 원문 범위·줄 경계에 쓸 단위를 먼저 고정하고 에디터·저장·엔진이 같은 의미로 사용하게 한다.

## 동작

`calculateTextLayout`, `findAffectedAutomaticGroups`, `encodeDesignWorkDocument`, `writeDesignWorkFile`, `exportManufacturingDxf`처럼 실제 동작을 드러내는 이름을 쓴다.
저장 요청이 계산·확인까지 조율하는 업무 명령과, JSON을 인코딩하거나 디스크에 쓰는 함수를 구분한다.
패턴 미리보기는 현재 작업을 수정하지 않는다는 계약을, 적용 함수는 검토한 결과를 반영한다는 계약을 문서화한다.

`Manager`, `Helper`, `Util`, `Data`만으로 책임을 대신하지 않는다. 클래스마다 인터페이스·팩터리·서비스를 일괄 추가하지 않고 교체·격리의 실제 필요가 있는 경계에 둔다.
파일·패키지는 `lowercase_with_underscores`, 타입은 `UpperCamelCase`, 멤버는 `lowerCamelCase`를 따른다.
