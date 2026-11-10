import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:usisa/features/scan/ocr_service_native.dart';
import 'package:usisa/features/scan/scan_models.dart';

Future<Uint8List> imageBytes(int width, int height, {bool text = true}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawColor(Colors.white, BlendMode.src);
  final painter = TextPainter(
    text: const TextSpan(
      text: 'GCash: Send your OTP immediately.\nhttps://gcash.com.evil.test',
      style: TextStyle(color: Colors.black, fontSize: 38),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width - 80);
  if (text) painter.paint(canvas, const Offset(40, 60));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
    painter.dispose();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native OCR handles offline text, limits, blank/corrupt images and copy cleanup',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('OCR verification'))),
      );
      final service = OcrService();
      final temp = await getTemporaryDirectory();
      final fixtures = await temp.createTemp('usisa-ocr-test-');
      final documents = await (await getApplicationDocumentsDirectory())
          .createTemp('usisa-ocr-source-test-');
      try {
        final bytes = await imageBytes(1200, 400);
        final valid = await File('${fixtures.path}/valid.png')
            .writeAsBytes(bytes);
        final draft = await service.readImage(XFile(valid.path));
        expect(draft.text, contains('GCash'));
        expect(draft.text, contains('OTP'));
        expect(draft.text, contains('https://gcash.com.evil.test'));
        expect(await valid.exists(), isFalse);

        final source = await File('${documents.path}/source.png')
            .writeAsBytes(bytes);
        await service.readImage(XFile(source.path));
        expect(await source.exists(), isTrue);

        final blank = await File('${fixtures.path}/blank.png')
            .writeAsBytes(await imageBytes(400, 200, text: false));
        expect(
          (await service.readImage(XFile(blank.path))).text.trim(),
          isEmpty,
        );
        expect(await blank.exists(), isFalse);

        final oversized = File('${fixtures.path}/over-byte-limit.png');
        final output = await oversized.open(mode: FileMode.write);
        await output.truncate(20 * 1024 * 1024 + 1);
        await output.close();
        await expectLater(
          service.readImage(XFile(oversized.path)),
          throwsA(
            isA<ScanException>().having((e) => e.code, 'code', 'imageTooLarge'),
          ),
        );
        expect(await oversized.exists(), isFalse);

        final pixels = await File('${fixtures.path}/over-pixel-limit.png')
            .writeAsBytes(await imageBytes(5000, 4001, text: false));
        await expectLater(
          service.readImage(XFile(pixels.path)),
          throwsA(
            isA<ScanException>().having((e) => e.code, 'code', 'imageTooLarge'),
          ),
        );
        expect(await pixels.exists(), isFalse);

        final corrupt = await File('${fixtures.path}/corrupt.png')
            .writeAsBytes([0, 1, 2, 3]);
        await expectLater(
          service.readImage(XFile(corrupt.path)),
          throwsA(
            isA<ScanException>().having((e) => e.code, 'code', 'ocrFailed'),
          ),
        );
        expect(await corrupt.exists(), isFalse);
      } finally {
        await fixtures.delete(recursive: true);
        await documents.delete(recursive: true);
      }
    },
  );
}
