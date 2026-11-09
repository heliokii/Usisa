import 'package:flutter/foundation.dart';

import 'scan_models.dart';
import 'scam_analyzer.dart';

class ScanController extends ChangeNotifier {
  ScanController({ScamAnalyzer? analyzer, this.beforeAnalyze})
    : _analyzer = analyzer ?? ScamAnalyzer();
  final ScamAnalyzer _analyzer;
  final Future<void> Function()? beforeAnalyze;
  ScanInput input = const ScanInput('');
  ScanResult? result;
  String? error;
  bool busy = false;
  int _revision = 0;
  bool _disposed = false;

  Future<void> check(ScanInput value) async {
    if (busy || _disposed) {
      return;
    }
    input = value;
    result = null;
    error = null;
    busy = true;
    final revision = ++_revision;
    notifyListeners();
    try {
      if (beforeAnalyze != null) {
        await beforeAnalyze!();
      } else {
        await Future<void>.delayed(Duration.zero);
      }
      if (_disposed || revision != _revision) {
        return;
      }
      result = _analyzer.analyze(value);
    } on ScanException catch (e) {
      if (revision == _revision) {
        error = e.code;
      }
    } catch (_) {
      if (revision == _revision) {
        error = 'scanFailed';
      }
    } finally {
      if (!_disposed && revision == _revision) {
        busy = false;
        notifyListeners();
      }
    }
  }

  void cancel() {
    _revision++;
    busy = false;
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }
}
