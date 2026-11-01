import 'package:r_edit_workflow/r_edit_workflow.dart';

/// 두 영역과 공유 스냅샷을 갖춘 시험용 실제 업무 값이다. 배치/제작 결과가 아니다.
DesignGeometry circularGeometryWithTextAreas({double radius = 20}) {
  final outline = CircleBoundary(center: Point2(x: 0, y: 0), radius: radius);
  return DesignGeometry(
    coordinateSpace: DrawingCoordinateSpace(lengthUnit: LengthUnit.millimeter),
    outline: outline,
    cutouts: [],
    textAreas: [
      for (final id in ['first', 'second'])
        TextAreaDefinition(
          areaId: id,
          label: '',
          region: TextRegion(outer: outline, exclusions: []),
        ),
    ],
  );
}

/// 영역 정의와 다른 입력 순서, Unicode·공백·지정 한 줄/여러 줄을 명시한다.
ProductDesignConfiguration twoProductsSharingGeometry() =>
    ProductDesignConfiguration(
      appliedGeometries: [
        AppliedDesignGeometry(
          appliedGeometryId: 'original',
          geometry: circularGeometryWithTextAreas(),
        ),
        AppliedDesignGeometry(
          appliedGeometryId: 'unused',
          geometry: circularGeometryWithTextAreas(radius: 30),
        ),
      ],
      products: [
        ProductInput(
          productId: 'A',
          appliedGeometryId: 'original',
          textInputs: [
            TextAreaInput(
              areaId: 'second',
              sourceText: ' A e\u0301🙂 ',
              lineBreak: SpecifiedLineBreak([' A e\u0301🙂 ']),
            ),
            TextAreaInput(
              areaId: 'first',
              sourceText: 'PUMP  A',
              lineBreak: SpecifiedLineBreak(['PUMP ', ' A']),
            ),
          ],
        ),
        ProductInput(
          productId: 'B',
          appliedGeometryId: 'original',
          textInputs: [
            TextAreaInput(
              areaId: 'first',
              sourceText: '한글 B',
              lineBreak: const AutomaticLineBreak(),
            ),
            TextAreaInput(
              areaId: 'second',
              sourceText: '   ',
              lineBreak: SpecifiedLineBreak(['   ']),
            ),
          ],
        ),
      ],
    );

/// 대상·제안 ID를 시험 본문에서 선택하며 유지 영역의 입력을 변경하지 않는다.
ReviseAppliedGeometry reviseSharedGeometry({
  String proposedId = 'revised',
  List<String> productIds = const ['A'],
}) => ReviseAppliedGeometry(
  sourceAppliedGeometryId: 'original',
  proposedGeometry: AppliedDesignGeometry(
    appliedGeometryId: proposedId,
    geometry: circularGeometryWithTextAreas(radius: 25),
  ),
  targets: [
    for (final id in productIds)
      ProductGeometryTarget(
        productId: id,
        areaMappings: [],
        newTextInputs: [],
        removedInputAreaIds: [],
      ),
  ],
);
