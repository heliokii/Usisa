import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../history/history_store.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore(this.storage);
  final PrivateStorage storage;
  String language = 'en';
  bool saveHistory = false;
  bool restoreDraft = false;
  bool onlineLinkChecks = false;
  bool aiScanning = true;
  bool onboarded = false;
  Future<void> _tail = Future.value();
  bool _disposed = false;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    final json = (await storage.readAll())['settings'];
    if (json == null) {
      return;
    }
    final value = jsonDecode(json) as Map<String, dynamic>;
    language = value['language'] == 'fil' ? 'fil' : 'en';
    saveHistory = value['saveHistory'] == true;
    restoreDraft = value['restoreDraft'] == true;
    aiScanning = value['aiScanning'] != false;
    onboarded = value['onboarded'] == true;
    onlineLinkChecks =
        value['onlineLinkChecks'] == true && value['onlineDisclosure'] == 2;
  }

  Future<void> update({
    String? language,
    bool? saveHistory,
    bool? restoreDraft,
    bool? onlineLinkChecks,
    bool? aiScanning,
    bool? onboarded,
  }) {
    final work = _tail.then((_) async {
      final value = {
        'language': language ?? this.language,
        'saveHistory': saveHistory ?? this.saveHistory,
        'restoreDraft': restoreDraft ?? this.restoreDraft,
        'onlineLinkChecks': onlineLinkChecks ?? this.onlineLinkChecks,
        'aiScanning': aiScanning ?? this.aiScanning,
        'onlineDisclosure': 2,
        'onboarded': onboarded ?? this.onboarded,
      };
      final oldLanguage = this.language;
      final oldAiScanning = this.aiScanning;
      this.language = value['language'] as String;
      this.aiScanning = value['aiScanning'] as bool;
      _changed();
      try {
        await storage.write('settings', jsonEncode(value));
      } catch (_) {
        this.language = oldLanguage;
        this.aiScanning = oldAiScanning;
        _changed();
        rethrow;
      }
      this.language = value['language'] as String;
      this.saveHistory = value['saveHistory'] as bool;
      this.restoreDraft = value['restoreDraft'] as bool;
      this.onlineLinkChecks = value['onlineLinkChecks'] as bool;
      this.aiScanning = value['aiScanning'] as bool;
      this.onboarded = value['onboarded'] as bool;
      _changed();
    });
    _tail = work.then((_) {}, onError: (Object _, StackTrace _) {});
    return work;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
