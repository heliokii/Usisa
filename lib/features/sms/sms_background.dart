import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../check/check.dart';
import '../scan/scan_models.dart';

const _risk = {
  Verdict.looksSafe: RiskLevel.low,
  Verdict.beCareful: RiskLevel.caution,
  Verdict.dangerous: RiskLevel.high,
};

Future<void> runSmsBackground({MethodChannel channel = const MethodChannel('usisa/sms_worker')}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final value = await channel.invokeMapMethod<String, dynamic>('takeEvent');
  if (value == null || value['id'] is! String || value['body'] is! String) {
    return;
  }
  final id = value['id'] as String;
  final body = value['body'] as String;
  try {
    if (body.trim().isEmpty) throw const ScanException('emptyInput');
    if (body.runes.length > 10000) throw const ScanException('textTooLong');
    // The same phone check the app runs; nothing leaves the phone here.
    final phone = phoneCheck(body);
    final risk = _risk[phone.verdict]!;
    final result = ScanResult(
      id: id,
      text: body,
      source: ScanSource.sms,
      findings: [
        for (final s in phone.signs)
          // Weak signs are reasons only, so they carry no risk of their own.
          Finding(
            s.code,
            severity: s.strength == SignStrength.strong || s.code == 'gambling_ad' ? risk : RiskLevel.low,
          ),
      ],
      links: [for (final l in phone.links) LinkResult(original: l, uri: Uri.tryParse(l), findings: const [])],
      createdAt: DateTime.now(),
      ruleVersion: 'phone-v2',
    );
    // Notification strings come from the .arb files; they name the verdict and sender, never the body.
    final l = lookupAppLocalizations(Locale(value['language'] == 'fil' ? 'fil' : 'en'));
    final sender = value['sender'] is String && (value['sender'] as String).trim().isNotEmpty
        ? (value['sender'] as String).trim()
        : l.smsAlertUnknownSender;
    await channel.invokeMethod<void>('complete', {
      'result': result.toJson(),
      'risk': risk.name,
      if (risk != RiskLevel.low) ...{'title': l.smsAlertTitle(phone.verdict.name), 'from': l.smsAlertFrom(sender)},
    });
  } on ScanException catch (error) {
    await channel.invokeMethod<void>('complete', {'error': error.code});
  } catch (_) {
    await channel.invokeMethod<void>('complete', {'error': 'scanFailed'});
  }
}
