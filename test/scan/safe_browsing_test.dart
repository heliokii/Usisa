import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/scan/scan_models.dart';
import 'package:usisa/features/settings/settings_store.dart';

LinkResult advisory({
  bool expired = false,
  List<String> threats = const ['MALWARE'],
}) {
  final at = DateTime.now().subtract(Duration(minutes: expired ? 10 : 0));
  return LinkResult(
    original: 'https://submitted.example/private',
    uri: Uri.parse('https://submitted.example/private'),
    findings: [],
    provider: 'Google Safe Browsing',
    reputation: ReputationState.matched,
    checkedAt: at,
    expiresAt: at.add(const Duration(minutes: 1)),
    threatTypes: threats,
  );
}

ScanResult scan(LinkResult link, {List<Finding> findings = const []}) =>
    ScanResult(
      id: 'advisory-fixture',
      text: link.original,
      source: ScanSource.link,
      findings: findings,
      links: [link],
      createdAt: DateTime.now(),
    );

void main() {
  test(
    'expired Safe Browsing evidence cannot raise risk; local findings remain',
    () {
      final result = scan(advisory(expired: true));
      expect(result.risk, RiskLevel.low);
      expect(result.hasUncheckedLinks, isTrue);
      expect(scan(advisory()).risk, RiskLevel.high);
      expect(
        scan(
          advisory(expired: true),
          findings: [const Finding('codeRequest', severity: RiskLevel.high)],
        ).risk,
        RiskLevel.high,
      );
      final restored = LinkResult.fromJson(advisory().toJson());
      expect(restored.provider, 'Google Safe Browsing');
      final legacy = LinkResult.fromJson(
        advisory().toJson()..remove('provider'),
      );
      expect(legacy.provider, 'Google Web Risk');
    },
  );

  test('old Web Risk consent cannot authorize Safe Browsing', () async {
    final storage = MemoryStorage();
    await storage.write(
      'settings',
      jsonEncode({'onlineLinkChecks': true, 'onlineDisclosure': 1}),
    );
    final settings = SettingsStore(storage);
    await settings.load();
    expect(settings.onlineLinkChecks, isFalse);
    await settings.update(onlineLinkChecks: true);
    expect(jsonDecode(storage.values['settings']!)['onlineDisclosure'], 2);
    final restored = SettingsStore(storage);
    await restored.load();
    expect(restored.onlineLinkChecks, isTrue);
  });
}
