import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../scan/scan_models.dart';

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

class HistoryStore extends ChangeNotifier {
  HistoryStore(this.storage, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final PrivateStorage storage;
  final DateTime Function() clock;
  final _entries = <ScanResult>[];
  List<ScanResult> get entries => List.unmodifiable(_entries);
  bool enabled = false;
  int generation = 0;
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
    final loaded = <ScanResult>[];
    for (final entry in data.entries.where((e) => e.key.startsWith('scan.'))) {
      try {
        final value = ScanResult.fromJson(
          jsonDecode(entry.value) as Map<String, dynamic>,
        );
        if (enabled &&
            clock().difference(value.createdAt) < const Duration(days: 30)) {
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
    _changed();
  });

  Future<void> setEnabled(bool value) async {
    enabled = value;
    generation++;
    if (!value) {
      await clear();
    }
    _changed();
  }

  Future<void> save(ScanResult result, {required int expectedGeneration}) =>
      _serial(() async {
        if (!enabled ||
            expectedGeneration != generation ||
            clock().difference(result.createdAt) >= const Duration(days: 30)) {
          return;
        }
        await storage.write('scan.${result.id}', jsonEncode(result.toJson()));
        if (expectedGeneration != generation) {
          await storage.delete('scan.${result.id}');
          return;
        }
        _entries.removeWhere((r) => r.id == result.id);
        _entries.add(result);
        await _prune();
        _changed();
      });

  Future<void> _prune() async {
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final remove = _entries
        .where(
          (r) => clock().difference(r.createdAt) >= const Duration(days: 30),
        )
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
    return _serial(() async {
      final all = await storage.readAll();
      for (final key in all.keys.where(
        (k) => k.startsWith('scan.') || k == 'draft',
      )) {
        await storage.delete(key);
      }
      _entries.clear();
      _changed();
    });
  }

  Future<void> saveDraft(String text, {required int expectedGeneration}) =>
      _serial(() async {
        if (expectedGeneration != generation || text.runes.length > 10000) {
          return;
        }
        if (text.isEmpty) {
          await storage.delete('draft');
          return;
        }
        await storage.write(
          'draft',
          jsonEncode({'text': text, 'createdAt': clock().toIso8601String()}),
        );
        if (expectedGeneration != generation) {
          await storage.delete('draft');
        }
      });

  Future<String?> loadDraft() async {
    String? result;
    await _serial(() async {
      final raw = (await storage.readAll())['draft'];
      if (raw == null) {
        return;
      }
      try {
        final value = jsonDecode(raw) as Map<String, dynamic>;
        final text = value['text'] as String;
        final age = clock().difference(
          DateTime.parse(value['createdAt'] as String),
        );
        if (age < const Duration(hours: 24) && text.runes.length <= 10000) {
          result = text;
          return;
        }
      } catch (_) {
        /* A corrupt private draft must not become a scan result. */
      }
      await storage.delete('draft');
    });
    return result;
  }

  Future<void> clearDraft() {
    generation++;
    return _serial(() => storage.delete('draft'));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
