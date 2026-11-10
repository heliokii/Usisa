import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:usisa/features/scan/reputation_client.dart';
import 'package:usisa/features/scan/scan_models.dart';
import 'package:usisa/features/scan/result_screen.dart';
import 'package:usisa/l10n/app_localizations.dart';

void main() {
  test('small gateway clock skew does not hide a fresh advisory or extend its lifetime', () async {
    final at = DateTime.now().toUtc().add(const Duration(seconds: 2));
    final client = ReputationClient(
      baseUri: Uri.parse('https://gateway.example'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 'matched',
            'threatTypes': ['MALWARE'],
            'checkedAt': at.toIso8601String(),
            'expiresAt': at.add(const Duration(seconds: 60)).toIso8601String(),
            'provider': 'Google Safe Browsing',
          }),
          200,
        ),
      ),
    );
    final check = await client.check(Uri.parse('https://example.test'));
    expect(check.state, ReputationState.matched);
    expect(check.checkedAt!.isAfter(DateTime.now()), isFalse);
    final link =
        LinkResult(
          original: 'https://example.test',
          uri: Uri.parse('https://example.test'),
          findings: [],
        ).withReputation(
          check.state,
          at: check.checkedAt,
          until: check.expiresAt,
          provider: check.provider,
        );
    expect(link.currentReputation, ReputationState.matched);
    expect(
      check.expiresAt!.difference(check.checkedAt!),
      lessThanOrEqualTo(const Duration(seconds: 60)),
    );
    client.close();
  });
  testWidgets(
    'expired saved matches show the historical warning, check time and unknown coverage',
    (tester) async {
      final at = DateTime.now().subtract(const Duration(days: 1));
      final link = LinkResult(
        original: 'https://example.test',
        uri: Uri.parse('https://example.test'),
        findings: [],
        reputation: ReputationState.matched,
        checkedAt: at,
        expiresAt: at.add(const Duration(minutes: 1)),
      );
      final result = ScanResult(
        id: 'expired',
        text: link.original,
        source: ScanSource.link,
        findings: [],
        links: [link],
        createdAt: at,
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ResultScreen(result: result),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Link safety is unknown.'), findsOneWidget);
      expect(
        find.textContaining('Previously listed as a threat.'),
        findsOneWidget,
      );
      expect(find.textContaining('Last checked:'), findsOneWidget);
      expect(
        find.textContaining('Previous online result is no longer current.'),
        findsOneWidget,
      );
      expect(result.risk, RiskLevel.high);
    },
  );
  test('persisted provider expiry survives serialization and old checks are unknown', () {
    final at = DateTime.now().toUtc().subtract(const Duration(days: 1));
    final expiry = at.add(const Duration(minutes: 10)).toIso8601String();
    final original = LinkResult(
      original: 'https://example.test',
      uri: Uri.parse('https://example.test'),
      findings: [],
      reputation: ReputationState.matched,
      checkedAt: at,
    );
    final restored = LinkResult.fromJson(
      original.toJson()..['expiresAt'] = expiry,
    );
    expect(restored.toJson()['expiresAt'], expiry);
    final old = ScanResult(
      id: 'old',
      text: original.original,
      source: ScanSource.link,
      findings: [],
      links: [original.withReputation(ReputationState.noMatch, at: at)],
      createdAt: at,
    );
    expect(old.hasUncheckedLinks, isTrue);
  });
  test(
    'only the URL reaches the gateway; provider no-match is typed',
    () async {
      final client = ReputationClient(
        baseUri: Uri.parse('https://gateway.example'),
        client: MockClient((request) async {
          expect(request.url.path, '/v1/link-check');
          expect(jsonDecode(request.body), {
            'url': 'https://example.test/private?q=1',
          });
          return http.Response(
            jsonEncode({
              'status': 'noMatch',
              'threatTypes': [],
              'checkedAt': DateTime.now().toUtc().toIso8601String(),
              'expiresAt': null,
              'provider': 'Google Safe Browsing',
            }),
            200,
          );
        }),
      );
      expect(
        (await client.check(
          Uri.parse('https://example.test/private?q=1#fragment'),
        )).state,
        ReputationState.noMatch,
      );
      client.close();
    },
  );
  test('missing configuration, HTTP failure and malformed provider state remain unavailable', () async {
    expect(
      (await ReputationClient().check(Uri.parse('https://example.test'))).state,
      ReputationState.unavailable,
    );
    for (final response in [
      http.Response('{}', 429),
      http.Response('{bad', 200),
      http.Response('{"status":"safe"}', 200),
      http.Response('{"status":"matched","threatTypes":[]}', 200),
      http.Response(
        jsonEncode({
          'status': 'noMatch',
          'threatTypes': [],
          'provider': 'Google Web Risk',
          'checkedAt': DateTime.now().toUtc().toIso8601String(),
        }),
        200,
      ),
    ]) {
      final client = ReputationClient(
        baseUri: Uri.parse('https://gateway.example'),
        client: MockClient((_) async => response),
      );
      expect(
        (await client.check(Uri.parse('https://example.test'))).state,
        ReputationState.unavailable,
      );
      client.close();
    }
  });
  test(
    'matched threat cannot be fabricated from an expired or invalid response',
    () async {
      for (final expired in [true, false]) {
        final client = ReputationClient(
          baseUri: Uri.parse('https://gateway.example'),
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'status': 'matched',
                'threatTypes': ['MALWARE'],
                'checkedAt': DateTime.now().toUtc().toIso8601String(),
                'expiresAt': DateTime.now()
                    .toUtc()
                    .add(Duration(hours: expired ? -1 : 1))
                    .toIso8601String(),
                'provider': 'Google Safe Browsing',
              }),
              200,
            ),
          ),
        );
        expect(
          (await client.check(Uri.parse('https://example.test'))).state,
          expired ? ReputationState.unavailable : ReputationState.matched,
        );
        client.close();
      }
    },
  );
}
