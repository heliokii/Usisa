import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:usisa/features/check/check.dart';
import 'package:usisa/features/check/gateway_link_checker.dart';

final base = Uri.parse('https://gateway.test');
final now = DateTime.utc(2026, 11, 21, 8);

/// A /v1/link-check answer shaped like server/link_check.mjs returns it.
Map<String, Object?> answer(String status, {String expansion = 'expanded', String? destination, String? reason, DateTime? at}) => {
  'status': status,
  'threatTypes': status == 'matched' ? ['SOCIAL_ENGINEERING'] : [],
  'flaggedUrls': [],
  'checkedAt': (at ?? now).toIso8601String(),
  'expiresAt': null,
  'provider': 'Google Safe Browsing',
  'expansion': expansion,
  'destination': destination,
  'hops': [?destination],
  'reason': ?reason,
};

http.Response json(Object body, {int status = 200}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

Future<LinkCheck> checkWith(http.Client client, [String link = 'bit.ly/abc']) async =>
    (await gatewayLinkChecker(client, base, now: () => now, timeout: const Duration(milliseconds: 50))([link])).single;

Future<LinkCheck> checkAnswer(Map<String, Object?> body) => checkWith(MockClient((_) async => json(body)));

void main() {
  test('sends the link as an http URL to /v1/link-check', () async {
    late http.Request sent;
    await checkWith(MockClient((r) async {
      sent = r;
      return json(answer('noMatch', destination: 'https://shopee.ph/sale'));
    }));
    expect(sent.method, 'POST');
    expect(sent.url, Uri.parse('https://gateway.test/v1/link-check'));
    expect(jsonDecode(sent.body), {'url': 'http://bit.ly/abc'});
  });

  test('a clean, fully followed link is clean with its real destination', () async {
    final r = await checkAnswer(answer('noMatch', destination: 'https://shopee.ph/sale'));
    expect(r.status, LinkStatus.clean);
    expect(r.destination, 'https://shopee.ph/sale');
    expect(r.hops, ['https://shopee.ph/sale']);
    expect(r.link, 'bit.ly/abc');
  });

  test('a flagged hop is flagged', () async {
    final r = await checkAnswer(answer('matched', destination: 'https://gcash-verify-ph.xyz/login'));
    expect(r.status, LinkStatus.flagged);
    expect(r.destination, 'https://gcash-verify-ph.xyz/login');
  });

  test('a link the shortener blocked is shortenerBlocked', () async {
    expect((await checkAnswer(answer('blockedByShortener', expansion: 'blocked'))).status, LinkStatus.shortenerBlocked);
  });

  test('a redirect into an app link opens an app', () async {
    final r = await checkAnswer(
      answer('unavailable', expansion: 'unresolved', reason: 'non_web_destination', destination: 'intent://pay#Intent;end'),
    );
    expect(r.status, LinkStatus.opensApp);
  });

  test('an unfollowed link is unresolved', () async {
    expect((await checkAnswer(answer('unavailable', expansion: 'unresolved', reason: 'timeout_total'))).status, LinkStatus.unresolved);
  });

  group('every failure is unresolved', () {
    final cases = <String, http.Client>{
      'timeout': MockClient((_) => Completer<http.Response>().future),
      'non-200': MockClient((_) async => json({'error': 'unavailable'}, status: 503)),
      'HTML page': MockClient((_) async => http.Response('<html>waking up</html>', 200, headers: {'content-type': 'text/html'})),
      'oversized': MockClient((_) async => json({...answer('noMatch', destination: 'https://a.ph'), 'pad': 'x' * 70000})),
      'stale': MockClient((_) async => json(answer('noMatch', destination: 'https://a.ph', at: now.subtract(const Duration(minutes: 6))))),
      'not JSON': MockClient((_) async => http.Response('nope', 200, headers: {'content-type': 'application/json'})),
      'cancelled': MockClient((_) async => throw http.ClientException('Connection closed')),
      'unknown status': MockClient((_) async => json(answer('maybe', destination: 'https://a.ph'))),
    };
    for (final MapEntry(key: name, value: client) in cases.entries) {
      test(name, () async {
        final r = await checkWith(client);
        expect(r.status, LinkStatus.unresolved);
      });
    }
  });

  test('a failed check is not retried', () async {
    var posts = 0;
    await checkWith(MockClient((_) async {
      posts++;
      return json({'error': 'unavailable'}, status: 503);
    }));
    expect(posts, 1);
  });

  test('warm-up pings /healthz once', () async {
    final hits = <Uri>[];
    warmUpGateway(MockClient((r) async {
      hits.add(r.url);
      return json({'status': 'ok'});
    }), base);
    await Future<void>.delayed(Duration.zero);
    expect(hits, [Uri.parse('https://gateway.test/healthz')]);
  });
}
