import 'package:flutter/foundation.dart';

import 'scan_models.dart';
import 'scam_analyzer.dart';
import '../history/history_store.dart';
import 'ai_models.dart';
import 'ai_scan_client.dart';

class ScanController extends ChangeNotifier {
  ScanController({
    ScamAnalyzer? analyzer,
    this.beforeAnalyze,
    ScanResult? initialResult,
  }) : _analyzer = analyzer ?? ScamAnalyzer(),
       result = initialResult;
  final ScamAnalyzer _analyzer;
  final Future<void> Function()? beforeAnalyze;
  ScanInput input = const ScanInput('');
  ScanResult? result;
  String? error;
  bool busy = false;
  int _revision = 0;
  bool _disposed = false;
  AiScanClient? _aiClient;

  Future<void> checkAi(
    ReviewedAiInput value, {
    required AiScanClient client,
    HistoryStore? history,
  }) async {
    if (busy ||
        _disposed ||
        history != null && history.generation != value.privacyGeneration)
      return;
    input = ScanInput(value.text, source: value.source);
    error = null;
    try {
      final local = result?.text == value.text && result?.source == value.source
          ? result!
          : _analyzer.analyze(input);
      result = local.withAi(
        const AiAssessment(AiScanState.checking),
        reviewed: true,
      );
    } on ScanException catch (e) {
      error = e.code;
      client.close();
      notifyListeners();
      return;
    }
    final revision = ++_revision;
    busy = true;
    _aiClient = client;
    notifyListeners();
    try {
      final assessment = await client.check(value);
      if (_disposed || revision != _revision) return;
      if (history != null && value.privacyGeneration != history.generation) {
        result = result!.withAi(const AiAssessment(AiScanState.cancelled));
        return;
      }
      result = result!.withAi(assessment);
      notifyListeners();
      if (history != null) {
        try {
          await history.save(
            result!,
            expectedGeneration: value.privacyGeneration,
          );
        } catch (_) {
          if (!_disposed && revision == _revision) error = 'saveFailed';
        }
      }
    } finally {
      client.close();
      if (!_disposed && revision == _revision) {
        busy = false;
        _aiClient = null;
        notifyListeners();
      }
    }
  }

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
    _aiClient?.close();
    _aiClient = null;
    if (result?.aiAssessment?.state == AiScanState.checking)
      result = result!.withAi(const AiAssessment(AiScanState.cancelled));
    busy = false;
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _aiClient?.close();
    super.dispose();
  }
}
