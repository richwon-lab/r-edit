import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'font_evidence.dart';
import 'probe_drawing.dart';
import 'probe_scene.dart';

void main() {
  runApp(const ProbeApp());
}

class ProbeApp extends StatelessWidget {
  const ProbeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'R-edit DXF 격리 실험',
    theme: ThemeData(
      colorSchemeSeed: const Color(0xff24536b),
      useMaterial3: true,
    ),
    home: const ProbePage(),
  );
}

class ProbePage extends StatefulWidget {
  const ProbePage({super.key});
  @override
  State<ProbePage> createState() => _ProbePageState();
}

class _ProbePageState extends State<ProbePage> {
  final dxfPath = TextEditingController(
    text: File('fixtures/r_edit_flutter_text_probe.dxf').absolute.path,
  );
  final fontPath = TextEditingController(text: r'C:\Windows\Fonts\H2GTRE.TTF');
  final transform = TransformationController();
  final captureKey = GlobalKey();
  ProbeScene? scene;
  String status = 'DXF와 실제 글꼴 파일 경로를 확인한 뒤 불러오세요.';
  String? fileHash;
  bool loading = false, helpers = true, emComparison = false;
  Size viewport = Size.zero;
  final loadedFonts = <String>{};

  Future<void> load() async {
    if (loading) return;
    setState(() => loading = true);
    final requestedDxfPath = dxfPath.text;
    final requestedFontPath = fontPath.text;
    ProbeScene? prepared;
    try {
      final bytes = await File(requestedDxfPath).readAsBytes();
      final drawing = ProbeDrawing.read(bytes);
      final fontBytes = await File(requestedFontPath).readAsBytes();
      final font = FontEvidence(fontBytes);
      final family = 'probe_${font.hash}';
      if (!loadedFonts.contains(family)) {
        final loader = FontLoader(family)
          ..addFont(Future.value(ByteData.sublistView(fontBytes)));
        await loader.load();
        loadedFonts.add(family);
      }
      final placed = <PlacedText>[], issues = <ProbeFailure>[...drawing.issues];
      for (final input in drawing.texts) {
        try {
          final expected = input.style.font;
          final actual = requestedFontPath.split(RegExp(r'[/\\]')).last;
          if (expected.toUpperCase() != actual.toUpperCase() ||
              expected.toUpperCase() != 'H2GTRE.TTF') {
            throw ProbeFailure(
              'fontReferenceMismatch',
              input.record.location,
              'STYLE=$expected, 지정 파일=$actual; 대체하지 않음',
            );
          }
          placed.add(
            PlacedText(input, font, family, emComparison: emComparison),
          );
        } on ProbeFailure catch (issue) {
          issues.add(issue);
        }
      }
      prepared = ProbeScene(
        drawing,
        font,
        placed,
        List.unmodifiable(issues),
        emComparison,
      );
      if (!mounted) {
        prepared.dispose();
        return;
      }
      scene?.dispose();
      setState(() {
        scene = prepared;
        fileHash = sha256.convert(bytes).toString();
        status =
            'LINE ${drawing.lines.length} / TEXT ${placed.length}/${drawing.texts.length} 렌더링 · 거부 ${issues.length}';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) fit();
      });
    } on ProbeFailure catch (error) {
      if (mounted) setState(() => status = '거부: $error · 이전 표시 유지');
    } on FileSystemException catch (error) {
      if (mounted) {
        setState(
          () => status =
              'fileAccessFailure: ${error.osError?.errorCode ?? "파일 접근 실패"} · 이전 표시 유지',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void fit() {
    if (viewport.isEmpty) return;
    final scale =
        (viewport.width / ProbePainter.drawingSize.width <
                viewport.height / ProbePainter.drawingSize.height
            ? viewport.width / ProbePainter.drawingSize.width
            : viewport.height / ProbePainter.drawingSize.height) *
        0.96;
    transform.value = Matrix4.identity()
      ..translateByDouble(
        (viewport.width - ProbePainter.drawingSize.width * scale) / 2,
        (viewport.height - ProbePainter.drawingSize.height * scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void zoom(double factor) {
    final current = transform.value.clone();
    final center = Offset(viewport.width / 2, viewport.height / 2);
    final point = transform.toScene(center);
    current.translateByDouble(point.dx, point.dy, 0, 1);
    current.scaleByDouble(factor, factor, 1, 1);
    current.translateByDouble(-point.dx, -point.dy, 0, 1);
    transform.value = current;
  }

  Future<void> capture() async {
    final current = scene;
    if (current == null) return;
    // 결과는 새 실행 디렉터리에만 기록한다. 원본 DXF/글꼴은 쓰지 않는다.
    final repository = Directory.current.parent.parent.parent;
    final folder = Directory(
      '${repository.path}/.tooling/dxf-render-results/${DateTime.now().microsecondsSinceEpoch}',
    );
    await folder.create(recursive: true);
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final png = File('${folder.path}/screen.png');
    await png.create(exclusive: true);
    await png.writeAsBytes(data!.buffer.asUint8List());
    final evidence = {
      'sample': 'synthetic user-supplied DXF',
      'dxfSha256': fileHash,
      'fontSha256': current.font.hash,
      'fontNames': current.font.names,
      'unitsPerEm': current.font.unitsPerEm,
      'capHeight': current.font.capHeight,
      'capSource': current.font.capSource,
      'emComparison': current.emComparison,
      'coverage': 'cmap checked; Flutter per-glyph actual-face introspection unavailable',
      'codePage': current.drawing.codePage,
      'units': 'mm',
      'issues': current.issues.map((e) => e.toString()).toList(),
      'texts': current.texts
          .map(
            (p) => {
              'handle': p.input.record.optional(5),
              'rawText': p.input.rawText,
              'text': p.input.text,
              'height': p.input.height,
              'widthFactor': p.input.width,
              'rotation': p.input.rotation,
              'style': p.input.style.name,
              'fontReference': p.input.style.font,
              'horizontal': p.input.horizontal,
              'vertical': p.input.vertical,
              'insertion': [p.input.insertion.dx, p.input.insertion.dy],
              'alignment': p.input.alignment == null
                  ? null
                  : [p.input.alignment!.dx, p.input.alignment!.dy],
              'anchor': [p.anchor.dx, p.anchor.dy],
              'fontSizeReference': p.painter.text!.style!.fontSize,
              'emMm': p.scale * current.font.unitsPerEm,
              'advanceMm': p.advanceMm,
              'baselineReference': p.baseline,
              'leftReference': p.left,
            },
          )
          .toList(),
    };
    final json = File('${folder.path}/render-inputs.json');
    await json.create(exclusive: true);
    await json.writeAsString(
      const JsonEncoder.withIndent('  ').convert(evidence),
    );
    if (mounted) {
      setState(
        () => status =
            '저장 완료'
            ' ${folder.path}',
      );
    }
  }

  @override
  void dispose() {
    scene?.dispose();
    dxfPath.dispose();
    fontPath.dispose();
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: captureKey,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('R-edit · DXF / 실제 글꼴 격리 실험'),
        actions: [
          TextButton(
            onPressed: scene == null ? null : capture,
            child: const Text('화면·입력 근거 저장'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dxfPath,
                    decoration: const InputDecoration(
                      labelText: 'DXF 경로',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: fontPath,
                    decoration: const InputDecoration(
                      labelText: '실제 TTF 경로',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: loading ? null : load,
                  child: Text(loading ? '읽는 중' : '불러오기'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                TextButton(onPressed: fit, child: const Text('전체 보기')),
                IconButton(
                  tooltip: '확대',
                  onPressed: () => zoom(1.25),
                  icon: const Icon(Icons.add),
                ),
                IconButton(
                  tooltip: '축소',
                  onPressed: () => zoom(0.8),
                  icon: const Icon(Icons.remove),
                ),
                Checkbox(
                  value: helpers,
                  onChanged: (value) => setState(() => helpers = value!),
                ),
                const Text('기준점·논리 경계'),
                const SizedBox(width: 16),
                DropdownButton<bool>(
                  value: emComparison,
                  items: const [
                    DropdownMenuItem(
                      value: false,
                      child: Text('DXF cap-height 해석'),
                    ),
                    DropdownMenuItem(value: true, child: Text('비교: 높이=em 가정')),
                  ],
                  onChanged: loading
                      ? null
                      : (value) {
                          setState(() => emComparison = value!);
                          if (scene != null) load();
                        },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(status),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      viewport = constraints.biggest;
                      return ClipRect(
                        child: InteractiveViewer(
                          transformationController: transform,
                          constrained: false,
                          minScale: 0.05,
                          maxScale: 20,
                          boundaryMargin: const EdgeInsets.all(2000),
                          child: SizedBox.fromSize(
                            size: ProbePainter.drawingSize,
                            child: scene == null
                                ? const Center(child: Text('경로를 지정하고 불러오세요.'))
                                : CustomPaint(
                                    painter: ProbePainter(
                                      scene!,
                                      helpers: helpers,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  width: 310,
                  color: const Color(0xfff2f5f8),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: scene == null
                        ? const Text('읽기 전')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '실행 상태',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'mm · Y 위쪽 → 화면 Y 아래\nASCII / ${scene!.drawing.codePage} + Unicode escape',
                              ),
                              const SizedBox(height: 8),
                              Text(scene!.font.names.join(' / ')),
                              Text(
                                'UPEM ${scene!.font.unitsPerEm} · cap ${scene!.font.capHeight}\n${scene!.font.capSource}',
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '확인: 지정 bytes를 FontLoader로 로드, sample cmap glyph 모두 검사.\n미확인: Flutter가 실제 선택한 face의 glyph별 조회·CAD/Type3 정밀 일치.',
                                style: TextStyle(color: Color(0xff845500)),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '빨강 +: 적용 baseline/정렬점\n주황 ○: 원래 group10\n청록: advance × cap 높이 논리 상자\n잉크/충돌 경계가 아님.\nkerning/liga off, 자동 줄바꿈/맞춤 없음.',
                              ),
                              for (final issue in scene!.issues)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    issue.toString(),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              const Divider(),
                              for (final text in scene!.texts)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    '${text.input.record.optional(5)} · h=${text.input.height} w=${text.input.width} rot=${text.input.rotation}\n'
                                    '72/73=${text.input.horizontal}/${text.input.vertical} @${text.anchor}\n'
                                    'advance ${text.advanceMm.toStringAsFixed(4)} mm\n${text.input.text}',
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
