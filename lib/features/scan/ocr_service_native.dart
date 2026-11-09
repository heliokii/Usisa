import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'ocr_models.dart';
import 'scan_models.dart';

class OcrService {
  final _picker = ImagePicker();
  bool get available =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<OcrDraft?> readScreenshot() async {
    if (!available) {
      throw const ScanException('ocrUnavailable');
    }
    final recovered = await recoverScreenshot();
    if (recovered != null) {
      return recovered;
    }
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    return image == null ? null : _read(image);
  }

  Future<OcrDraft?> recoverScreenshot() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    final response = await _picker.retrieveLostData();
    if (response.exception != null) {
      throw const ScanException('ocrFailed');
    }
    final image = response.files?.firstOrNull;
    return image == null ? null : _read(image);
  }

  Future<OcrDraft> _read(XFile image) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
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
      final result = await recognizer.processImage(
        InputImage.fromFilePath(image.path),
      );
      return OcrDraft(text: result.text, bytes: bytes);
    } finally {
      await recognizer.close();
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
