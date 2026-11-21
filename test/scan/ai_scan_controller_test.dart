import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:usisa/features/scan/ai_models.dart';
import 'package:usisa/features/scan/ai_scan_client.dart';
import 'package:usisa/features/scan/scan_controller.dart';
import 'package:usisa/features/scan/scan_models.dart';

import 'ai_models_test.dart' show assessment;
import 'gateway_test_helpers.dart';

void main() {
  for (final action in ['complete', 'cancel', 'edit', 'dispose']) {
    test(
      'AI $action keeps local snapshot and rejects stale results',
      () async {
        final wait = Completer<http.Response>();
        var calls = 0;
        final client = AiScanClient(
          baseUri: Uri.parse('https://gateway.test'),
          client: MockClient((request) {
            final health = gatewayHealthResponse(request);
            if (health != null) return Future.value(health);
            calls++;
            expect(jsonDecode(request.body)['text'], 'Send your OTP');
            return wait.future;
          }),
        );
        final controller = ScanController();
        const input = ReviewedAiInput(
          text: 'Send your OTP',
          source: ScanSource.screenshot,
          responseLanguage: 'en',
          inputRevision: 1,
          privacyGeneration: 0,
        );
        final work = controller.checkAi(input, client: client);
        await Future<void>.delayed(Duration.zero);
        expect(controller.result?.text, input.text);
        expect(controller.result?.aiAssessment?.state, AiScanState.checking);
        expect(controller.result?.findings, isNotEmpty);
        final id = controller.result!.id;
        await controller.checkAi(input, client: client);
        expect(calls, 1);
        if (action == 'cancel') controller.cancel();
        if (action == 'edit') {
          controller.cancel();
          await controller.check(const ScanInput('A newer message'));
        }
        if (action == 'dispose') controller.dispose();
        wait.complete(http.Response(jsonEncode(assessment()), 200));
        await work;
        if (action == 'complete') {
          expect(controller.result?.aiAssessment?.state, AiScanState.completed);
          expect(controller.result?.id, id);
          expect(controller.result?.reviewedForAi, isTrue);
        } else {
          if (action == 'edit') {
            expect(controller.result?.text, 'A newer message');
          } else if (action != 'dispose') {
            expect(
              controller.result?.aiAssessment?.state,
              AiScanState.cancelled,
            );
          }
        }
        if (action != 'dispose') controller.dispose();
      },
    );
  }
}
