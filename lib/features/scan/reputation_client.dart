import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'scan_models.dart';

class ReputationCheck {
  const ReputationCheck(
    this.state, {
    this.checkedAt,
    this.threatTypes = const [],
  });
  final ReputationState state;
  final DateTime? checkedAt;
  final List<String> threatTypes;
}

class ReputationClient {
  ReputationClient({Uri? baseUri, http.Client? client})
    : baseUri =
          baseUri ??
          Uri.tryParse(const String.fromEnvironment('USISA_GATEWAY_URL')),
      _client = client ?? http.Client();
  final Uri? baseUri;
  final http.Client _client;
  bool get configured {
    final uri = baseUri;
    return uri != null &&
        uri.hasAuthority &&
        uri.userInfo.isEmpty &&
        (uri.scheme == 'https' ||
            (kDebugMode &&
                uri.scheme == 'http' &&
                ['localhost', '127.0.0.1', '10.0.2.2'].contains(uri.host)));
  }

  static const _threats = {
    'MALWARE',
    'SOCIAL_ENGINEERING',
    'UNWANTED_SOFTWARE',
  };
  Future<ReputationCheck> check(Uri uri) async {
    const unavailable = ReputationCheck(ReputationState.unavailable);
    if (!configured ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      return unavailable;
    }
    try {
      final response = await _client
          .post(
            baseUri!.resolve('/v1/link-check'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'url': uri.removeFragment().toString()}),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200 || response.bodyBytes.length > 8192) {
        return unavailable;
      }
      final value = jsonDecode(response.body);
      if (value is! Map<String, dynamic> ||
          value['provider'] != 'Google Web Risk' ||
          value['checkedAt'] is! String ||
          value['threatTypes'] is! List) {
        return unavailable;
      }
      final at = DateTime.tryParse(value['checkedAt'] as String);
      if (at == null ||
          at.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
        return unavailable;
      }
      final threats = List<String>.from(value['threatTypes'] as List);
      if (threats.any((t) => !_threats.contains(t))) {
        return unavailable;
      }
      if (value['status'] == 'noMatch' && threats.isEmpty) {
        return ReputationCheck(ReputationState.noMatch, checkedAt: at);
      }
      final expiry = value['expiresAt'] is String
          ? DateTime.tryParse(value['expiresAt'] as String)
          : null;
      if (value['status'] == 'matched' &&
          threats.isNotEmpty &&
          expiry != null &&
          expiry.isAfter(DateTime.now())) {
        return ReputationCheck(
          ReputationState.matched,
          checkedAt: at,
          threatTypes: threats,
        );
      }
      return unavailable;
    } catch (_) {
      return unavailable;
    }
  }

  void close() => _client.close();
}
