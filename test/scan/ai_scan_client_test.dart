import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:usisa/features/scan/ai_models.dart';
import 'package:usisa/features/scan/ai_scan_client.dart';
import 'package:usisa/features/scan/scan_models.dart';

import 'ai_models_test.dart' show assessment;
import 'gateway_test_helpers.dart';

const reviewed = ReviewedAiInput(
  text: 'Send your OTP',
  source: ScanSource.screenshot,
  responseLanguage: 'fil',
  inputRevision: 3,
  privacyGeneration: 4,
);
void main() {
  test(
    'only confirmed text and locale leave the app, with opaque submission key',
    () async {
      var calls = 0;
      final client = AiScanClient(
        baseUri: Uri.parse('https://gateway.test'),
        client: MockClient((request) async {
          final health = gatewayHealthResponse(request);
          if (health != null) return health;
          calls++;
          expect(request.url.toString(), 'https://gateway.test/v1/ai-scan');
          expect(jsonDecode(request.body), {
            'text': 'Send your OTP',
            'responseLanguage': 'fil',
          });
          expect(
            request.headers['Idempotency-Key'],
            matches(RegExp(r'^[a-f0-9]{32}$')),
          );
          expect(request.headers.containsKey('Authorization'), isFalse);
          return http.Response(jsonEncode(assessment()), 200);
        }),
      );
      expect(calls, 0);
      expect((await client.check(reviewed)).state, AiScanState.completed);
      expect(calls, 1);
      client.close();
    },
  );
  test('malformed, invented, nonterminal, old, oversized and failed responses stay unavailable', () async {
    for (final response in [
      http.Response('private upstream details', 429),
      http.Response('{}', 200),
      http.Response(jsonEncode({...assessment(), 'summary': 'x' * 481}), 200),
      http.Response(
        jsonEncode({
          ...assessment(),
          'summary':
              'Call 09171234567 or visit https://invented.test for support.',
        }),
        200,
      ),
      http.Response(
        jsonEncode({
          ...assessment(),
          'warningSigns': [
            {'code': 'other', 'evidence': 'invented'},
          ],
        }),
        200,
      ),
      http.Response(
        jsonEncode(const AiAssessment(AiScanState.checking).toJson()),
        200,
      ),
      http.Response(
        jsonEncode({...assessment(), 'checkedAt': '2020-01-01T00:00:00Z'}),
        200,
      ),
      http.Response('x' * 32769, 200),
    ]) {
      final client = AiScanClient(
        baseUri: Uri.parse('https://gateway.test'),
        client: MockClient(
          (request) async => gatewayHealthResponse(request) ?? response,
        ),
      );
      expect((await client.check(reviewed)).state, AiScanState.unavailable);
      client.close();
    }
    final client = AiScanClient(
      baseUri: Uri.parse('http://untrusted.test'),
      client: MockClient((_) async => throw StateError('must not upload')),
    );
    expect((await client.check(reviewed)).state, AiScanState.unavailable);
    client.close();
  });
  test('timeout is a single unavailable attempt', () async {
    var calls = 0;
    final client = AiScanClient(
      baseUri: Uri.parse('https://gateway.test'),
      timeout: const Duration(milliseconds: 10),
      client: MockClient((request) async {
        final health = gatewayHealthResponse(request);
        if (health != null) return health;
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return http.Response(jsonEncode(assessment()), 200);
      }),
    );
    expect((await client.check(reviewed)).state, AiScanState.unavailable);
    expect(calls, 1);
    client.close();
  });
}
