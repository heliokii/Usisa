import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../check/check.dart';

abstract interface class PrivateStorage {
  Future<Map<String, String>> readAll();
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureStorage implements PrivateStorage {
  const SecureStorage();
  static const _storage = FlutterSecureStorage();
  @override
  Future<Map<String, String>> readAll() => _storage.readAll();
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class MemoryStorage implements PrivateStorage {
  final values = <String, String>{};
  @override
  Future<Map<String, String>> readAll() async => Map.of(values);
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

/// One saved Check. Screenshots are kept as their extracted text only; no image is stored.
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.checkedAt,
    required this.source,
    required this.result,
    this.aiScan = false,
  });
  final String id;
  final DateTime checkedAt;
  final CheckSource source;
  final bool aiScan;
  final CheckResult result;

  Map<String, dynamic> toJson() => {
    'id': id,
    'checkedAt': checkedAt.toIso8601String(),
    'source': source.name,
    'aiScan': aiScan,
    'text': result.text,
    'verdict': result.verdict.name,
    'reasons': result.reasons,
    'checkedOnPhone': result.checkedOnPhone,
    'destinations': result.destinations,
    'evidence': result.evidence,
    'aiUnavailable': result.aiUnavailable,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    id: json['id'] as String,
    checkedAt: DateTime.parse(json['checkedAt'] as String),
    source: CheckSource.values.byName(json['source'] as String),
    aiScan: json['aiScan'] == true,
    result: CheckResult(
      text: json['text'] as String,
      verdict: Verdict.values.byName(json['verdict'] as String),
      reasons: List<String>.from(json['reasons'] as List),
      checkedOnPhone: json['checkedOnPhone'] == true,
      destinations: List<String>.from(json['destinations'] as List),
      // Entries saved before AI scan shipped have no evidence.
      evidence: List<String>.from(json['evidence'] as List? ?? const []),
      aiUnavailable: json['aiUnavailable'] == true,
    ),
  );
}

class HistoryStore extends ChangeNotifier {
  HistoryStore(this.storage, {DateTime Function()? clock, this.clearSmsPrivacy})
    : clock = clock ?? DateTime.now;
  final PrivateStorage storage;
  final DateTime Function() clock;
  final Future<void> Function()? clearSmsPrivacy;
  final _entries = <HistoryEntry>[];

  /// Newest first.
  List<HistoryEntry> get entries => List.unmodifiable(
    _entries.where((r) => _live(r.checkedAt, const Duration(days: 30))),
  );
  DateTime? _draftExpiresAt;
  DateTime? get nextExpiry {
    final dates = [
      for (final r in _entries) r.checkedAt.add(const Duration(days: 30)),
      ?_draftExpiresAt,
    ]..sort();
    return dates.firstOrNull;
  }

  bool _live(DateTime at, Duration ttl) {
    final age = clock().difference(at);
    return !age.isNegative && age < ttl;
  }

  /// History is on by default; the app syncs this from the saved setting.
  bool enabled = true;
  int generation = 0;
  int _historyRevision = 0;
  int _draftRevision = 0;
  Future<void> _tail = Future.value();
  bool _disposed = false;

  Future<void> _serial(Future<void> Function() work) {
    final result = _tail.then((_) => work());
    _tail = result.then((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  void _changed() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> load() => _serial(() async {
    final data = await storage.readAll();
    final loaded = <HistoryEntry>[];
    for (final entry in data.entries.where((e) => e.key.startsWith('scan.'))) {
      try {
        final value = HistoryEntry.fromJson(
          jsonDecode(entry.value) as Map<String, dynamic>,
        );
        if (enabled && _live(value.checkedAt, const Duration(days: 30))) {
          loaded.add(value);
        } else {
          await storage.delete(entry.key);
        }
      } catch (_) {
        await storage.delete(entry.key);
      }
    }
    _entries
      ..clear()
      ..addAll(loaded);
    await _prune();
    await _readDraft(data['draft']);
    _changed();
  });

  Future<void> setEnabled(bool value) async {
    enabled = value;
    _historyRevision++;
    if (!value) {
      await _serial(() async {
        final data = await storage.readAll();
        for (final key in data.keys.where((key) => key.startsWith('scan.'))) {
          await storage.delete(key);
        }
        _entries.clear();
      });
    }
    _changed();
  }

  Future<void> save(HistoryEntry entry, {required int expectedGeneration}) {
    final revision = _historyRevision;
    return _serial(() async {
      if (!enabled ||
          revision != _historyRevision ||
          expectedGeneration != generation ||
          !_live(entry.checkedAt, const Duration(days: 30))) {
        return;
      }
      await storage.write('scan.${entry.id}', jsonEncode(entry.toJson()));
      if (expectedGeneration != generation ||
          revision != _historyRevision ||
          !enabled) {
        await storage.delete('scan.${entry.id}');
        return;
      }
      _entries.removeWhere((r) => r.id == entry.id);
      _entries.add(entry);
      await _prune();
      _changed();
    });
  }

  int _seq = 0;

  /// Wraps [run] so every finished Check is saved. A clear while it runs discards the result,
  /// and a failed save never blocks the verdict.
  RunCheck recording(RunCheck run) => (input) async {
    final expectedGeneration = generation;
    final result = await run(input);
    final now = clock();
    save(
      HistoryEntry(
        id: input.historyId ?? '${now.microsecondsSinceEpoch}-${_seq++}',
        checkedAt: now,
        source: input.source,
        aiScan: input.aiScan,
        result: result,
      ),
      expectedGeneration: expectedGeneration,
    ).ignore();
    return result;
  };

  Future<void> _prune() async {
    _entries.sort((a, b) => b.checkedAt.compareTo(a.checkedAt));
    final remove = _entries
        .where((r) => !_live(r.checkedAt, const Duration(days: 30)))
        .toList();
    final current = _entries.where((r) => !remove.contains(r)).toList();
    remove.addAll(current.skip(100));
    for (final result in remove) {
      await storage.delete('scan.${result.id}');
      _entries.remove(result);
    }
  }

  Future<void> delete(Set<String> ids) => _serial(() async {
    for (final id in ids) {
      await storage.delete('scan.$id');
    }
    _entries.removeWhere((r) => ids.contains(r.id));
    _changed();
  });

  Future<void> clear() {
    generation++;
    _draftRevision++;
    _historyRevision++;
    return _serial(() async {
      await clearSmsPrivacy?.call();
      final all = await storage.readAll();
      for (final key in all.keys.where(
        (k) => k.startsWith('scan.') || k == 'draft',
      )) {
        await storage.delete(key);
      }
      _entries.clear();
      _draftExpiresAt = null;
      _changed();
    });
  }

  Future<void> saveDraft(String text, {required int expectedGeneration}) {
    final revision = _draftRevision;
    return _serial(() async {
      if (expectedGeneration != generation ||
          revision != _draftRevision ||
          text.runes.length > 10000) {
        return;
      }
      if (text.isEmpty) {
        await storage.delete('draft');
        _draftExpiresAt = null;
        _changed();
        return;
      }
      final createdAt = clock();
      await storage.write(
        'draft',
        jsonEncode({'text': text, 'createdAt': createdAt.toIso8601String()}),
      );
      if (expectedGeneration != generation || revision != _draftRevision) {
        await storage.delete('draft');
        _draftExpiresAt = null;
      } else {
        _draftExpiresAt = createdAt.add(const Duration(hours: 24));
      }
      _changed();
    });
  }

  Future<String?> loadDraft() async {
    String? result;
    await _serial(() async {
      result = await _readDraft((await storage.readAll())['draft']);
      _changed();
    });
    return result;
  }

  Future<String?> _readDraft(String? raw) async {
    if (raw == null) {
      _draftExpiresAt = null;
      return null;
    }
    try {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      final text = value['text'] as String;
      final createdAt = DateTime.parse(value['createdAt'] as String);
      if (_live(createdAt, const Duration(hours: 24)) &&
          text.runes.length <= 10000) {
        _draftExpiresAt = createdAt.add(const Duration(hours: 24));
        return text;
      }
    } catch (_) {
      /* A corrupt private draft must not become a scan result. */
    }
    await storage.delete('draft');
    _draftExpiresAt = null;
    return null;
  }

  Future<void> clearDraft() {
    _draftRevision++;
    return _serial(() async {
      await storage.delete('draft');
      _draftExpiresAt = null;
      _changed();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
