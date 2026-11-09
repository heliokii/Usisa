import 'dart:convert';

import 'package:flutter/material.dart';

import '../history/history_store.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore(this.storage);
  final PrivateStorage storage;
  String language = 'en';
  ThemeMode theme = ThemeMode.system;
  bool saveHistory = false;
  bool restoreDraft = false;
  bool onlineLinkChecks = false;
  Future<void> _tail = Future.value();

  Future<void> load() async {
    final json = (await storage.readAll())['settings'];
    if (json == null) {
      return;
    }
    final value = jsonDecode(json) as Map<String, dynamic>;
    language = value['language'] == 'fil' ? 'fil' : 'en';
    theme =
        ThemeMode.values.where((t) => t.name == value['theme']).firstOrNull ??
        ThemeMode.system;
    saveHistory = value['saveHistory'] == true;
    restoreDraft = value['restoreDraft'] == true;
    onlineLinkChecks =
        value['onlineLinkChecks'] == true && value['onlineDisclosure'] == 1;
  }

  Future<void> update({
    String? language,
    ThemeMode? theme,
    bool? saveHistory,
    bool? restoreDraft,
    bool? onlineLinkChecks,
  }) {
    final work = _tail.then((_) async {
      final value = {
        'language': language ?? this.language,
        'theme': (theme ?? this.theme).name,
        'saveHistory': saveHistory ?? this.saveHistory,
        'restoreDraft': restoreDraft ?? this.restoreDraft,
        'onlineLinkChecks': onlineLinkChecks ?? this.onlineLinkChecks,
        'onlineDisclosure': 1,
      };
      await storage.write('settings', jsonEncode(value));
      this.language = value['language'] as String;
      this.theme = ThemeMode.values.byName(value['theme'] as String);
      this.saveHistory = value['saveHistory'] as bool;
      this.restoreDraft = value['restoreDraft'] as bool;
      this.onlineLinkChecks = value['onlineLinkChecks'] as bool;
      notifyListeners();
    });
    _tail = work.then((_) {}, onError: (Object _, StackTrace _) {});
    return work;
  }
}
