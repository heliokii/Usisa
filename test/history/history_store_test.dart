import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/check/check.dart';
import 'package:usisa/features/history/history_store.dart';

HistoryEntry entry(String id, DateTime at, {String text = 'synthetic'}) => HistoryEntry(
  id: id,
  checkedAt: at,
  source: CheckSource.message,
  result: CheckResult(
    text: text,
    verdict: Verdict.beCareful,
    reasons: const ['urgency'],
    checkedOnPhone: true,
  ),
);

void main() {
  test('expired history disappears during an active session and startup purges old drafts', () async {
    var now = DateTime.utc(2026, 11, 10);
    final storage = MemoryStorage();
    final history = HistoryStore(storage, clock: () => now);
    await history.save(entry('retention', now), expectedGeneration: 0);
    await history.saveDraft('synthetic draft', expectedGeneration: 0);
    now = now.add(const Duration(hours: 24));
    await history.load();
    expect(storage.values.containsKey('draft'), isFalse);
    now = now.add(const Duration(days: 29));
    expect(history.entries, isEmpty);
    await history.load();
    expect(storage.values.keys.where((k) => k.startsWith('scan.')), isEmpty);
  });
  test('a saved entry keeps its verdict, reasons, source and link results after reload', () async {
    final now = DateTime.utc(2026, 11, 10, 9, 30);
    final storage = MemoryStorage();
    await HistoryStore(storage, clock: () => now).save(
      HistoryEntry(
        id: 'links',
        checkedAt: now,
        source: CheckSource.sms,
        aiScan: true,
        result: const CheckResult(
          text: 'Claim at bit.ly/x',
          verdict: Verdict.dangerous,
          reasons: ['flagged_link', 'urgency'],
          checkedOnPhone: false,
          destinations: ['https://bad.example/claim'],
          evidence: ['Claim at'],
          aiUnavailable: true,
        ),
      ),
      expectedGeneration: 0,
    );
    final reloaded = HistoryStore(storage, clock: () => now);
    await reloaded.load();
    final saved = reloaded.entries.single;
    expect(saved.checkedAt, now);
    expect(saved.source, CheckSource.sms);
    expect(saved.aiScan, isTrue);
    expect(saved.result.text, 'Claim at bit.ly/x');
    expect(saved.result.verdict, Verdict.dangerous);
    expect(saved.result.reasons, ['flagged_link', 'urgency']);
    expect(saved.result.checkedOnPhone, isFalse);
    expect(saved.result.destinations, ['https://bad.example/claim']);
    expect(saved.result.evidence, ['Claim at']);
    expect(saved.result.aiUnavailable, isTrue);
  });
  test('recording wraps a Check so each finished result is saved', () async {
    final now = DateTime.utc(2026, 11, 10);
    final history = HistoryStore(MemoryStorage(), clock: () => now);
    final run = history.recording(
      (input) async => CheckResult(text: input.text, verdict: Verdict.looksSafe, reasons: const ['no_signs'], checkedOnPhone: true),
    );
    final result = await run(const CheckInput('Hello po', source: CheckSource.screenshot));
    await pumpEventQueue();
    expect(history.entries.single.result, same(result));
    expect(history.entries.single.source, CheckSource.screenshot);
    expect(history.entries.single.checkedAt, now);
  });
  test('a clear while a Check runs discards its result', () async {
    final history = HistoryStore(MemoryStorage());
    final run = history.recording((input) async {
      await history.clear();
      return CheckResult(text: input.text, verdict: Verdict.looksSafe, reasons: const [], checkedOnPhone: true);
    });
    await run(const CheckInput('private', source: CheckSource.message));
    await pumpEventQueue();
    expect(history.entries, isEmpty);
  });
  test('disabling history keeps separately opted-in private draft', () async {
    final history = HistoryStore(MemoryStorage());
    await history.setEnabled(true);
    await history.saveDraft(
      'separate draft',
      expectedGeneration: history.generation,
    );
    await history.setEnabled(false);
    expect(await history.loadDraft(), 'separate draft');
  });
  test(
    'clear waits for native SMS invalidation as well as local erasure',
    () async {
      var invalidated = false;
      final history = HistoryStore(
        MemoryStorage(),
        clearSmsPrivacy: () async {
          invalidated = true;
        },
      );
      await history.saveDraft(
        'private',
        expectedGeneration: history.generation,
      );
      await history.clear();
      expect(invalidated, isTrue);
      expect(await history.loadDraft(), isNull);
    },
  );
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
  test('history is on by default and turning it off erases saved entries', () async {
    final storage = MemoryStorage();
    final history = HistoryStore(storage);
    await history.save(entry('a', DateTime.now(), text: 'private message'), expectedGeneration: history.generation);
    expect(history.entries.single.result.text, 'private message');
    await history.setEnabled(false);
    expect(history.entries, isEmpty);
    expect(storage.values.keys.where((k) => k.startsWith('scan.')), isEmpty);
    await history.save(entry('b', DateTime.now()), expectedGeneration: history.generation);
    expect(storage.values, isEmpty);
  });
  test('clear invalidates queued stale saves', () async {
    final history = HistoryStore(MemoryStorage());
    final generation = history.generation;
    await history.clear();
    await history.save(entry('old', DateTime.now()), expectedGeneration: generation);
    expect(history.entries, isEmpty);
  });
  test('retention removes expired entries and keeps latest 100', () async {
    final now = DateTime.utc(2026, 11, 9);
    final history = HistoryStore(MemoryStorage(), clock: () => now);
    for (var i = 0; i < 101; i++) {
      await history.save(entry('$i', now.subtract(Duration(minutes: i))), expectedGeneration: history.generation);
    }
    expect(history.entries, hasLength(100));
    expect(history.entries.first.id, '0');
    expect(history.entries.any((e) => e.id == '100'), isFalse);
    await history.save(entry('expired', now.subtract(const Duration(days: 31))), expectedGeneration: history.generation);
    expect(history.entries.any((e) => e.id == 'expired'), isFalse);
  });
  test('a failed write does not claim a saved check', () async {
    final history = HistoryStore(FailingStorage());
    await expectLater(
      history.save(entry('x', DateTime.now()), expectedGeneration: history.generation),
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
