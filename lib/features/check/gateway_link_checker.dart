import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'check.dart';

/// The gateway's address: the Render service unless the build passes `USISA_GATEWAY_URL`.
final gatewayBase = Uri.parse(
  const String.fromEnvironment('USISA_GATEWAY_URL', defaultValue: 'https://usisa-gateway.onrender.com'),
);

/// One fire-and-forget /healthz ping so a sleeping gateway starts waking before the first Check.
void warmUpGateway(http.Client client, Uri base) =>
    client.get(base.resolve('/healthz')).timeout(const Duration(seconds: 10)).ignore();

/// The online link check over the gateway's `POST /v1/link-check` (contract: server/link_check.mjs).
/// One POST per link, never retried; any timeout, non-200, HTML, oversized, stale or cancelled answer is unresolved.
LinkChecker gatewayLinkChecker(
  http.Client client,
  Uri base, {
  DateTime Function() now = DateTime.now,
  Duration timeout = const Duration(seconds: 10),
}) =>
    (links) => Future.wait([for (final link in links) _check(client, base, link, now, timeout)]);

Future<LinkCheck> _check(http.Client client, Uri base, String link, DateTime Function() now, Duration timeout) async {
  final unresolved = LinkCheck(link, LinkStatus.unresolved);
  try {
    final response = await client
        .post(
          base.resolve('/v1/link-check'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'url': link.contains('://') ? link : 'http://$link'}),
        )
        .timeout(timeout);
    if (response.statusCode != 200 ||
        !(response.headers['content-type'] ?? '').startsWith('application/json') ||
        response.bodyBytes.length > 65536) {
      return unresolved;
    }
    final value = jsonDecode(response.body);
    if (value is! Map<String, dynamic>) return unresolved;
    final at = DateTime.tryParse('${value['checkedAt']}');
    if (at == null || now().difference(at).abs() > const Duration(minutes: 5)) return unresolved;
    final destination = value['destination'] is String ? value['destination'] as String : null;
    final status = switch (value['status']) {
      'matched' => LinkStatus.flagged,
      'blockedByShortener' => LinkStatus.shortenerBlocked,
      // Clean only when every hop was followed.
      'noMatch' when value['expansion'] == 'expanded' && destination != null => LinkStatus.clean,
      'unavailable' when value['reason'] == 'non_web_destination' => LinkStatus.opensApp,
      _ => LinkStatus.unresolved,
    };
    return LinkCheck(link, status, destination: destination);
  } catch (_) {
    return unresolved;
  }
}
