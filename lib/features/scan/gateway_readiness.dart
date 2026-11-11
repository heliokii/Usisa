import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<bool> waitForGateway(
  http.Client client,
  Uri baseUri, {
  bool Function()? cancelled,
}) async {
  const budget = Duration(seconds: 80);
  const interval = Duration(seconds: 4);
  const probeTimeout = Duration(seconds: 5);
  final elapsed = Stopwatch()..start();

  while (elapsed.elapsed < budget) {
    if (cancelled?.call() == true) return false;
    final abort = Completer<void>();
    var retry = false;
    try {
      final request = http.AbortableRequest(
        'GET',
        baseUri.resolve('/healthz'),
        abortTrigger: abort.future,
      )..headers['Accept'] = 'application/json';
      final response = await client.send(request).timeout(probeTimeout);
      final contentType = (response.headers['content-type'] ?? '')
          .toLowerCase();
      if (response.statusCode == 200 &&
          contentType.startsWith('application/json')) {
        final bytes = <int>[];
        await response.stream
            .forEach((chunk) {
              if (bytes.length + chunk.length > 128) {
                throw const FormatException(
                  'Oversized gateway health response',
                );
              }
              bytes.addAll(chunk);
            })
            .timeout(probeTimeout);
        final value = jsonDecode(utf8.decode(bytes));
        return value is Map<String, dynamic> && value['status'] == 'ok';
      }
      retry =
          const {502, 503, 504}.contains(response.statusCode) ||
          (response.statusCode == 200 && contentType.startsWith('text/html'));
      await response.stream.listen(null).cancel();
      if (!retry) return false;
    } on TimeoutException {
      retry = true;
    } on SocketException {
      return false;
    } on http.ClientException {
      return false;
    } catch (_) {
      return false;
    } finally {
      if (!abort.isCompleted) abort.complete();
    }
    if (!retry || cancelled?.call() == true) return false;
    await Future<void>.delayed(interval);
  }
  return false;
}
