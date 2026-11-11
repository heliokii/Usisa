import 'package:http/http.dart' as http;

http.Response? gatewayHealthResponse(http.Request request) =>
    request.url.path == '/healthz'
    ? http.Response(
        '{"status":"ok"}',
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      )
    : null;
