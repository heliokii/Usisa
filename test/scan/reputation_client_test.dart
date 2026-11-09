import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:usisa/features/scan/reputation_client.dart';
import 'package:usisa/features/scan/scan_models.dart';

void main() {
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
              'provider': 'Google Web Risk',
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
                'provider': 'Google Web Risk',
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
