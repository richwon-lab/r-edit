import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'font_evidence.dart';
import 'probe_drawing.dart';

/// TextPainter의 실제 advance와 baseline을 사용하고 최종 배율/회전은 Canvas에만 적용한다.
class PlacedText {
  PlacedText(
    this.input,
    this.font,
    String family, {
    bool emComparison = false,
  }) {
    font.checkCoverage(input);
    painter = TextPainter(
      text: TextSpan(
        text: input.text,
        style: TextStyle(
          fontFamily: family,
          fontFamilyFallback: const [],
          fontSize: font.unitsPerEm.toDouble(),
          color: const Color(0xff13223d),
          fontFeatures: const [
            ui.FontFeature.disable('kern'),
            ui.FontFeature.disable('liga'),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout();
    scale = input.height / (emComparison ? font.unitsPerEm : font.capHeight);
    baseline = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    left = -painter.width * input.horizontal / 2;
  }
  final ProbeText input;
  final FontEvidence font;
  late final TextPainter painter;
  late final double scale, baseline, left;
  double get advanceMm => painter.width * scale * input.width;

  /// baseline 좌표의 논리 advance/cap 높이 상자이며 잉크/충돌 경계가 아니다.
  Rect get logicalBox => Rect.fromLTRB(
    left * scale * input.width,
    -input.height,
    (left + painter.width) * scale * input.width,
    0,
  );
  Offset get anchor => input.anchor;
  double get radians => input.rotation * math.pi / 180;
  void dispose() => painter.dispose();
}

class ProbeScene {
  ProbeScene(
    this.drawing,
    this.font,
    this.texts,
    this.issues,
    this.emComparison,
  );
  final ProbeDrawing drawing;
  final FontEvidence font;
  final List<PlacedText> texts;
  final List<ProbeFailure> issues;
  final bool emComparison;
  void dispose() {
    for (final text in texts) {
      text.dispose();
    }
  }
}

class ProbePainter extends CustomPainter {
  ProbePainter(this.scene, {required this.helpers});
  final ProbeScene scene;
  final bool helpers;
  static const drawingSize = Size(1120, 680);
  static const unitScale = 4.0;
  static Offset project(Offset point) =>
      Offset(80 + point.dx * unitScale, 620 - point.dy * unitScale);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.white, BlendMode.src);
    for (final line in scene.drawing.lines) {
      canvas.drawLine(
        project(line.point(10, 20)),
        project(line.point(11, 21)),
        Paint()
          ..color = line.optional(8) == 'FRAME'
              ? const Color(0xff1b3850)
              : const Color(0xffcbd7e3)
          ..strokeWidth = 1,
      );
    }
    for (final text in scene.texts) {
      canvas.save();
      final p = project(text.anchor);
      canvas.translate(p.dx, p.dy);
      canvas.rotate(-text.radians);
      canvas.scale(
        unitScale * text.scale * text.input.width,
        unitScale * text.scale,
      );
      text.painter.paint(canvas, Offset(text.left, -text.baseline));
      canvas.restore();
      if (helpers) {
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(-text.radians);
        canvas.scale(unitScale, unitScale);
        canvas.drawRect(
          text.logicalBox,
          Paint()
            ..color = const Color(0xff53a8a0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.15,
        );
        canvas.drawLine(
          const Offset(-1, 0),
          const Offset(1, 0),
          Paint()
            ..color = Colors.red
            ..strokeWidth = 0.2,
        );
        canvas.drawLine(
          const Offset(0, -1),
          const Offset(0, 1),
          Paint()
            ..color = Colors.red
            ..strokeWidth = 0.2,
        );
        canvas.restore();
        // group10과 실제 적용 정렬점 group11을 서로 다른 표식으로 보존한다.
        canvas.drawCircle(
          project(text.input.insertion),
          2,
          Paint()
            ..color = Colors.orange
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ProbePainter oldDelegate) =>
      oldDelegate.scene != scene || oldDelegate.helpers != helpers;
}
