import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:usisa/features/check/check.dart';
import 'package:usisa/features/check/gateway_ai_checker.dart';

import '../scan/ai_models_test.dart' show assessment;
import '../scan/gateway_test_helpers.dart';

const text = 'Send your OTP at bit.ly/x';
final base = Uri.parse('https://gateway.test');

void main() {
  test('sends the text, language and link results; maps the answer to an AI level with quoted signs', () async {
    Object? sent;
    final checker = gatewayAiChecker(
      MockClient((request) async {
        final health = gatewayHealthResponse(request);
        if (health != null) return health;
        sent = jsonDecode(request.body);
        return http.Response(jsonEncode(assessment()), 200);
      }),
      base,
      language: () => 'fil',
    );
    final answer = await checker(text, const [
      LinkCheck('bit.ly/x', LinkStatus.clean, destination: 'https://gcash-verify.xyz/', hops: ['https://gcash-verify.xyz/']),
      LinkCheck('intent://x', LinkStatus.opensApp),
    ]);
    expect(sent, {
      'text': text,
      'responseLanguage': 'fil',
      'links': [
        {'url': 'bit.ly/x', 'destination': 'https://gcash-verify.xyz/', 'hops': ['https://gcash-verify.xyz/']},
        {'url': 'intent://x', 'destination': null, 'hops': <String>[]},
      ],
    });
    expect(answer!.level, AiLevel.high);
    expect(answer.signs.single.code, 'credential_request');
    expect(answer.signs.single.quote, 'Send your OTP');
  });

  test('no links means no links field', () async {
    Object? sent;
    await gatewayAiChecker(
      MockClient((request) async {
        final health = gatewayHealthResponse(request);
        if (health != null) return health;
        sent = jsonDecode(request.body);
        return http.Response(jsonEncode(assessment()), 200);
      }),
      base,
      language: () => 'en',
    )(text, const []);
    expect(sent, {'text': text, 'responseLanguage': 'en'});
  });

  test('a busy gateway or an AI that could not assess gives no answer', () async {
    for (final response in [
      http.Response('{"error":"unavailable"}', 503),
      http.Response(jsonEncode(assessment(risk: 'unknown')), 200),
    ]) {
      final checker = gatewayAiChecker(
        MockClient((request) async => gatewayHealthResponse(request) ?? response),
        base,
        language: () => 'en',
      );
      expect(await checker(text, const []), isNull);
    }
  });
}
