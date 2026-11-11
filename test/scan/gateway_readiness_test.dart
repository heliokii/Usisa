import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:usisa/features/scan/gateway_readiness.dart';

void main() {
  test('retries the Render wake-up page before scanning', () async {
    var attempts = 0;
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/healthz');
      expect(request.body, isEmpty);
      attempts++;
      if (attempts == 1) return http.Response('<html>waking</html>', 503);
      return http.Response(
        '{"status":"ok"}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    expect(
      await waitForGateway(client, Uri.parse('https://gateway.test')),
      isTrue,
    );
    expect(attempts, 2);
    client.close();
  });
}
