import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/scan/scam_analyzer.dart';
import 'package:usisa/features/scan/scan_models.dart';

void main() {
  test(
    'private draft expires after 24 hours and clear rejects stale autosave',
    () async {
      var now = DateTime.utc(2026, 11, 9);
      final history = HistoryStore(MemoryStorage(), clock: () => now);
      final generation = history.generation;
      await history.saveDraft('private draft', expectedGeneration: generation);
      expect(await history.loadDraft(), 'private draft');
      now = now.add(const Duration(hours: 24));
      expect(await history.loadDraft(), isNull);
      await history.clear();
      await history.saveDraft('old text', expectedGeneration: generation);
      expect(await history.loadDraft(), isNull);
    },
  );
  test(
    'history is opt in, encrypted adapter receives no default message',
    () async {
      final storage = MemoryStorage();
      final history = HistoryStore(storage);
      final result = ScamAnalyzer().analyze(const ScanInput('private message'));
      await history.save(result, expectedGeneration: history.generation);
      expect(storage.values, isEmpty);
      await history.setEnabled(true);
      await history.save(result, expectedGeneration: history.generation);
      expect(history.entries.single.text, 'private message');
      await history.setEnabled(false);
      expect(history.entries, isEmpty);
      expect(storage.values.keys.where((k) => k.startsWith('scan.')), isEmpty);
    },
  );
  test('clear invalidates queued stale saves', () async {
    final history = HistoryStore(MemoryStorage());
    await history.setEnabled(true);
    final generation = history.generation;
    await history.clear();
    await history.save(
      ScamAnalyzer().analyze(const ScanInput('old result')),
      expectedGeneration: generation,
    );
    expect(history.entries, isEmpty);
  });
  test('retention removes expired entries and keeps latest 100', () async {
    final now = DateTime.utc(2026, 11, 9);
    final history = HistoryStore(MemoryStorage(), clock: () => now);
    await history.setEnabled(true);
    for (var i = 0; i < 101; i++) {
      await history.save(
        ScanResult(
          id: '$i',
          text: '$i',
          source: ScanSource.text,
          findings: [],
          links: [],
          createdAt: now.subtract(Duration(minutes: i)),
        ),
        expectedGeneration: history.generation,
      );
    }
    expect(history.entries, hasLength(100));
    expect(history.entries.any((e) => e.id == '100'), isFalse);
    await history.save(
      ScanResult(
        id: 'expired',
        text: 'expired',
        source: ScanSource.text,
        findings: [],
        links: [],
        createdAt: now.subtract(const Duration(days: 31)),
      ),
      expectedGeneration: history.generation,
    );
    expect(history.entries.any((e) => e.id == 'expired'), isFalse);
  });
  test('a failed write does not claim a saved scan', () async {
    final history = HistoryStore(FailingStorage());
    await history.setEnabled(true);
    await expectLater(
      history.save(
        ScamAnalyzer().analyze(const ScanInput('hello')),
        expectedGeneration: history.generation,
      ),
      throwsStateError,
    );
    expect(history.entries, isEmpty);
  });
}

class FailingStorage extends MemoryStorage {
  @override
  Future<void> write(String key, String value) async =>
      throw StateError('storage failed');
}
