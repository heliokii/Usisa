import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../scan/scam_analyzer.dart';
import '../scan/scan_models.dart';

Future<void> runSmsBackground({
  MethodChannel channel = const MethodChannel('usisa/sms_worker'),
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final value = await channel.invokeMapMethod<String, dynamic>('takeEvent');
  if (value == null || value['id'] is! String || value['body'] is! String) {
    return;
  }
  final id = value['id'] as String;
  try {
    final local = ScamAnalyzer().analyze(
      ScanInput(value['body'] as String, source: ScanSource.sms),
    );
    final result = ScanResult(
      id: id,
      text: local.text,
      source: ScanSource.sms,
      findings: local.findings,
      links: local.links,
      createdAt: local.createdAt,
      ruleVersion: local.ruleVersion,
    );
    await channel.invokeMethod<void>('complete', {
      'result': result.toJson(),
      'risk': result.risk.name,
    });
  } on ScanException catch (error) {
    await channel.invokeMethod<void>('complete', {'error': error.code});
  } catch (_) {
    await channel.invokeMethod<void>('complete', {'error': 'scanFailed'});
  }
}
