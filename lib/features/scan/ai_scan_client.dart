import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ai_models.dart';
import 'gateway_readiness.dart';

class AiScanClient {
  AiScanClient({
    Uri? baseUri,
    http.Client? client,
    this.timeout = const Duration(seconds: 18),
  }) : baseUri =
           baseUri ??
           Uri.tryParse(const String.fromEnvironment('USISA_GATEWAY_URL')),
       _client = client ?? http.Client();
  final Uri? baseUri;
  final http.Client _client;
  final Duration timeout;
  final _abort = Completer<void>();
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

  Future<AiAssessment> check(ReviewedAiInput input) async {
    const unavailable = AiAssessment(AiScanState.unavailable);
    if (_abort.isCompleted ||
        !configured ||
        input.text.trim().isEmpty ||
        input.text.runes.length > 10000 ||
        !['en', 'fil'].contains(input.responseLanguage)) {
      return unavailable;
    }
    if (!await waitForGateway(
      _client,
      baseUri!,
      cancelled: () => _abort.isCompleted,
    )) {
      return unavailable;
    }
    try {
      return await _request(input).timeout(timeout);
    } catch (_) {
      close();
      return unavailable;
    }
  }

  Future<AiAssessment> _request(ReviewedAiInput input) async {
    final random = Random.secure();
    final key = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final request =
        http.AbortableRequest(
            'POST',
            baseUri!.resolve('/v1/ai-scan'),
            abortTrigger: _abort.future,
          )
          ..headers.addAll({
            'Content-Type': 'application/json',
            'Idempotency-Key': key,
          })
          ..body = jsonEncode({
            'text': input.text,
            'responseLanguage': input.responseLanguage,
          });
    final response = await _client.send(request);
    if (response.statusCode != 200) {
      await response.stream.listen(null).cancel();
      return const AiAssessment(AiScanState.unavailable);
    }
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > 32768) {
        throw const FormatException('Oversized assessment');
      }
      bytes.addAll(chunk);
    }
    final value = AiAssessment.fromJson(
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
      text: input.text,
    );
    if (_abort.isCompleted ||
        ![
          AiScanState.completed,
          AiScanState.unableToAssess,
        ].contains(value.state) ||
        value.checkedAt == null ||
        DateTime.now().difference(value.checkedAt!).abs() >
            const Duration(minutes: 5)) {
      return const AiAssessment(AiScanState.unavailable);
    }
    return value;
  }

  void close() {
    if (_abort.isCompleted) return;
    _abort.complete();
    _client.close();
  }
}
