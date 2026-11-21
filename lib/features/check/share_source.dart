import 'dart:async';

import 'package:flutter/services.dart';

/// Something another app shared into Usisa (Android ACTION_SEND).
class SharedItem {
  const SharedItem.text(String this.text) : imagePath = null;

  /// [imagePath] is a copy in the app cache, never the sender's URI.
  const SharedItem.image(String this.imagePath) : text = null;

  final String? text;
  final String? imagePath;
}

/// Shares from `MainActivity`: the one waiting at cold start, then each one that arrives while open.
/// Native holds the share until Dart takes it, and pings `shared` when a new one is ready.
Stream<SharedItem> channelShares() {
  const channel = MethodChannel('usisa/share');
  late final StreamController<SharedItem> out;
  Future<void> take() async {
    try {
      final m = await channel.invokeMapMethod<String, String>('take');
      final image = m?['image'];
      final text = m?['text'];
      if (image != null) {
        out.add(SharedItem.image(image));
      } else if (text != null && text.trim().isNotEmpty) {
        out.add(SharedItem.text(text));
      }
    } catch (_) {} // No native side (tests, other platforms): nothing was shared.
  }

  out = StreamController<SharedItem>(
    onListen: () {
      channel.setMethodCallHandler((call) async {
        if (call.method == 'shared') await take();
      });
      take();
    },
    onCancel: () => channel.setMethodCallHandler(null),
  );
  return out.stream;
}
