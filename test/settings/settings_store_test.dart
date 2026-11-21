import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/settings/settings_store.dart';

void main() {
  test(
    'language and AI preference persist; History on by default, other privacy preferences off',
    () async {
      final storage = MemoryStorage();
      final settings = SettingsStore(storage);
      expect(settings.saveHistory, isTrue);
      expect(settings.restoreDraft, isFalse);
      expect(settings.onlineLinkChecks, isFalse);
      expect(settings.aiScanning, isTrue);
      await settings.update(language: 'fil', aiScanning: false);
      final loaded = SettingsStore(storage);
      await loaded.load();
      expect(loaded.language, 'fil');
      expect(loaded.aiScanning, isFalse);
    },
  );

  for (final corrupt in ['not json', '[1, 2]', '{"language": 3, "saveHistory": "yes"}']) {
    test('corrupt settings ($corrupt) fall back to defaults', () async {
      final storage = MemoryStorage();
      await storage.write('settings', corrupt);
      final settings = SettingsStore(storage);
      await settings.load();
      expect(settings.language, 'en');
      expect(settings.saveHistory, isTrue);
      expect(settings.onlineLinkChecks, isFalse);
      expect(settings.aiScanning, isTrue);
    });
  }

  test('History can be turned off and stays off', () async {
    final storage = MemoryStorage();
    await SettingsStore(storage).update(saveHistory: false);
    final loaded = SettingsStore(storage);
    await loaded.load();
    expect(loaded.saveHistory, isFalse);
  });

  test('failed preference persistence keeps the previous setting', () async {
    final settings = SettingsStore(FailingStorage());
    await expectLater(settings.update(language: 'fil'), throwsStateError);
    expect(settings.language, 'en');
  });

  test(
    'AI preference updates immediately and rolls back on storage failure',
    () async {
      final storage = DelayedStorage();
      final settings = SettingsStore(storage);
      final update = settings.update(aiScanning: false);
      final failure = expectLater(update, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      final duringSave = settings.aiScanning;
      storage.writeDone.completeError(StateError('save failed'));
      await failure;
      expect(duringSave, isFalse);
      expect(settings.aiScanning, isTrue);
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
