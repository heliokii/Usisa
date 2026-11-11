import 'dart:typed_data';

class OcrDraft {
  const OcrDraft({required this.text, required this.bytes});
  final String text;
  final Uint8List bytes;
}
