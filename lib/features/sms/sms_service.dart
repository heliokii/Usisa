import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../scan/scan_models.dart';

class SmsReview {
  const SmsReview({
    required this.body,
    required this.generation,
    this.result,
    this.error,
  });
  final String body;
  final int generation;
  final ScanResult? result;
  final String? error;
}

class SmsService extends ChangeNotifier {
  SmsService({bool? nativePlatform, MethodChannel? channel})
    : nativePlatform =
          nativePlatform ??
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android),
      _channel = channel ?? const MethodChannel('usisa/sms') {
    if (this.nativePlatform) {
      _channel.setMethodCallHandler((call) async {
        if (!_disposed && call.method == 'statusChanged') {
          await refresh();
        }
        if (!_disposed &&
            call.method == 'notification' &&
            call.arguments is String) {
          _notifications.add(call.arguments as String);
        }
      });
    }
  }
  final bool nativePlatform;
  final MethodChannel _channel;
  final _notifications = StreamController<String>.broadcast();
  Stream<String> get notificationOpens => _notifications.stream;
  bool supported = false;
  bool bridgeAvailable = false;
  bool enabled = false;
  bool smsPermission = false;
  bool notifications = false;
  bool degraded = false;
  int generation = 0;
  int pendingCount = 0;
  bool _disposed = false;

  void _status(Map<dynamic, dynamic>? value) {
    if (value == null) {
      return;
    }
    bridgeAvailable = true;
    supported = value['supported'] == true;
    enabled = supported && value['enabled'] == true;
    smsPermission = value['smsPermission'] == true;
    notifications = value['notifications'] == true;
    degraded = value['degraded'] == true;
    pendingCount = value['pending'] is int ? value['pending'] as int : 0;
    if (value['generation'] is int) {
      generation = value['generation'] as int;
    }
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (!nativePlatform || _disposed) {
      return;
    }
    try {
      _status(await _channel.invokeMapMethod('status'));
    } on MissingPluginException {
      bridgeAvailable = false;
      supported = false;
      enabled = false;
    } on PlatformException {
      enabled = false;
      degraded = true;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> setEnabled(bool value, {String language = 'en'}) async {
    if (!nativePlatform) {
      return;
    }
    if (value) {
      await _channel.invokeMethod<void>('requestPermissions');
    }
    _status(
      await _channel.invokeMapMethod('setEnabled', {
        'enabled': value,
        'language': language,
      }),
    );
  }

  Future<void> setLanguage(String value) async {
    if (bridgeAvailable) {
      await _channel.invokeMethod<void>('language', value);
    }
  }

  Future<void> requestNotifications() async {
    await _channel.invokeMethod<void>('requestNotifications');
    await refresh();
  }

  Future<List<String>> reviewIds() async {
    if (!supported) return [];
    final ids = await _channel.invokeListMethod<String>('reviews') ?? [];
    return ids
        .where((id) => RegExp(r'^[0-9a-f-]{36}$').hasMatch(id))
        .take(20)
        .toList();
  }

  Future<int> invalidatePrivacy() async {
    final value = await _channel.invokeMethod<int>('invalidate');
    if (value == null) {
      throw StateError('Privacy generation unavailable');
    }
    generation = value;
    if (!_disposed) {
      notifyListeners();
    }
    return value;
  }

  Future<String?> takeNotification() async => !bridgeAvailable
      ? null
      : _channel.invokeMethod<String>('takeNotification');
  Future<SmsReview?> review(String id) async {
    if (!nativePlatform) {
      return null;
    }
    await refresh();
    final capturedGeneration = generation;
    final value = await _channel.invokeMapMethod<String, dynamic>('review', id);
    if (value == null ||
        generation != capturedGeneration ||
        value['body'] is! String ||
        value['generation'] != generation) {
      return null;
    }
    ScanResult? result;
    try {
      if (value['result'] is Map) {
        result = ScanResult.fromJson(
          Map<String, dynamic>.from(value['result'] as Map),
        );
        if (result.id != id ||
            result.source != ScanSource.sms ||
            result.text != value['body']) {
          return null;
        }
      }
    } catch (_) {
      return null;
    }
    return SmsReview(
      body: value['body'] as String,
      generation: generation,
      result: result,
      error: value['error'] as String?,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    if (nativePlatform) {
      _channel.setMethodCallHandler(null);
    }
    _notifications.close();
    super.dispose();
  }
}
