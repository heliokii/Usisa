import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/settings/settings_store.dart';

void main() {
  test(
    'language and appearance persist while privacy settings default off',
    () async {
      final storage = MemoryStorage();
      final settings = SettingsStore(storage);
      expect(settings.saveHistory, isFalse);
      expect(settings.restoreDraft, isFalse);
      expect(settings.onlineLinkChecks, isFalse);
      await settings.update(language: 'fil', theme: ThemeMode.dark);
      final loaded = SettingsStore(storage);
      await loaded.load();
      expect(loaded.language, 'fil');
      expect(loaded.theme, ThemeMode.dark);
    },
  );
  test('failed preference persistence keeps the previous setting', () async {
    final settings = SettingsStore(FailingStorage());
    await expectLater(settings.update(language: 'fil'), throwsStateError);
    expect(settings.language, 'en');
  });
  test(
    'appearance updates immediately and rolls back when persistence fails',
    () async {
      final storage = DelayedStorage();
      final settings = SettingsStore(storage);
      final update = settings.update(theme: ThemeMode.dark);
      final failure = expectLater(update, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      final duringSave = settings.theme;
      storage.writeDone.completeError(StateError('save failed'));
      await failure;
      expect(duringSave, ThemeMode.dark);
      expect(settings.theme, ThemeMode.system);
    },
  );
}

class DelayedStorage extends MemoryStorage {
  final writeDone = Completer<void>();
  @override
  Future<void> write(String key, String value) => writeDone.future;
}

class FailingStorage extends MemoryStorage {
  @override
  Future<void> write(String key, String value) async =>
      throw StateError('storage failed');
}
