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
/// One POST per link, never retried; any timeout, non-200, HTML, oversized or cancelled answer is unresolved.
/// No `checkedAt` freshness check: the request timeout already bounds the answer's age, and the phone clock may be off.
LinkChecker gatewayLinkChecker(
  http.Client client,
  Uri base, {
  Duration timeout = const Duration(seconds: 10),
}) =>
    (links) => Future.wait([for (final link in links) _check(client, base, link, timeout)]);

Future<LinkCheck> _check(http.Client client, Uri base, String link, Duration timeout) async {
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
    final destination = value['destination'] is String ? value['destination'] as String : null;
    final status = switch (value['status']) {
      'matched' => LinkStatus.flagged,
      'blockedByShortener' => LinkStatus.shortenerBlocked,
      // Clean only when every hop was followed.
      'noMatch' when value['expansion'] == 'expanded' && destination != null => LinkStatus.clean,
      'unavailable' when value['reason'] == 'non_web_destination' => LinkStatus.opensApp,
      _ => LinkStatus.unresolved,
    };
    final hops = value['hops'] is List ? [for (final h in value['hops'] as List) if (h is String) h] : const <String>[];
    return LinkCheck(link, status, destination: destination, hops: hops);
  } catch (_) {
    return unresolved;
  }
}
