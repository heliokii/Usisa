import 'package:image_picker/image_picker.dart';

import 'ocr_models.dart';
import 'scan_models.dart';

class OcrService {
  bool get available => false;
  Future<OcrDraft?> readScreenshot({bool usePhotos = false}) async =>
      throw const ScanException('ocrUnavailable');
  Future<OcrDraft?> readPhoto() async => throw const ScanException('ocrUnavailable');
  Future<OcrDraft?> recoverScreenshot() async => null;
  Future<OcrDraft> readImage(XFile image) async =>
      throw const ScanException('ocrUnavailable');
}
