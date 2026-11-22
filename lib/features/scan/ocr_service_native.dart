import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'ocr_models.dart';
import 'scan_models.dart';

class OcrService {
  final _picker = ImagePicker();
  bool get available => Platform.isAndroid || Platform.isIOS;

  Future<OcrDraft?> readScreenshot({bool usePhotos = false}) async {
    if (!available) {
      throw const ScanException('ocrUnavailable');
    }
    final image = Platform.isAndroid && !usePhotos
        ? await openFile(
            acceptedTypeGroups: const [
              XTypeGroup(
                label: 'images',
                extensions: ['jpg', 'jpeg', 'png', 'webp'],
                mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
              ),
            ],
          )
        : await _picker.pickImage(
            source: ImageSource.gallery,
            requestFullMetadata: false,
          );
    return image == null ? null : readImage(image);
  }

  /// Takes a photo with the camera (for example of another phone's screen) and reads it.
  Future<OcrDraft?> readPhoto() async {
    if (!available) throw const ScanException('ocrUnavailable');
    final image = await _picker.pickImage(source: ImageSource.camera, requestFullMetadata: false);
    return image == null ? null : readImage(image);
  }

  Future<OcrDraft?> recoverScreenshot() async {
    if (!Platform.isAndroid) {
      return null;
    }
    final response = await _picker.retrieveLostData();
    if (response.exception != null) {
      throw const ScanException('ocrFailed');
    }
    final image = response.files?.firstOrNull;
    return image == null ? null : readImage(image);
  }

  Future<OcrDraft> readImage(XFile image) async {
    if (!available) throw const ScanException('ocrUnavailable');
    TextRecognizer? recognizer;
    try {
      if (await image.length() > 20 * 1024 * 1024) {
        throw const ScanException('imageTooLarge');
      }
      final bytes = await image.readAsBytes();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      try {
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        try {
          if (descriptor.width * descriptor.height > 20000000) {
            throw const ScanException('imageTooLarge');
          }
        } finally {
          descriptor.dispose();
        }
      } finally {
        buffer.dispose();
      }
      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(
        InputImage.fromFilePath(image.path),
      );
      return OcrDraft(text: result.text, bytes: bytes, fileName: image.name);
    } on ScanException {
      rethrow;
    } catch (_) {
      throw const ScanException('ocrFailed');
    } finally {
      await recognizer?.close();
      // Delete only picker copies verified inside this app's temporary directory.
      final temp = await getTemporaryDirectory();
      final file = File(image.path);
      if (await file.exists()) {
        final actual = await file.resolveSymbolicLinks();
        final root = await temp.resolveSymbolicLinks();
        if (actual.startsWith('$root${Platform.pathSeparator}')) {
          await file.delete();
        }
      }
    }
  }
}
