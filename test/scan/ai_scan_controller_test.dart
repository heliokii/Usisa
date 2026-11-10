import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/scan/ai_models.dart';
import 'package:usisa/features/scan/ai_scan_client.dart';
import 'package:usisa/features/scan/scan_controller.dart';
import 'package:usisa/features/scan/scan_models.dart';

import 'ai_models_test.dart' show assessment;

void main() {
  for (final action in ['complete', 'cancel', 'edit', 'clear', 'dispose']) {
    test(
      'AI $action keeps local snapshot and rejects stale results/history',
      () async {
        final storage = MemoryStorage();
        final history = HistoryStore(storage);
        await history.setEnabled(true);
        final wait = Completer<http.Response>();
        var calls = 0;
        final client = AiScanClient(
          baseUri: Uri.parse('https://gateway.test'),
          client: MockClient((request) {
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
        final work = controller.checkAi(
          input,
          client: client,
          history: history,
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.result?.text, input.text);
        expect(controller.result?.aiAssessment?.state, AiScanState.checking);
        expect(controller.result?.findings, isNotEmpty);
        final id = controller.result!.id;
        await controller.checkAi(input, client: client, history: history);
        expect(calls, 1);
        if (action == 'cancel') controller.cancel();
        if (action == 'edit') {
          controller.cancel();
          await controller.check(const ScanInput('A newer message'));
        }
        if (action == 'clear') await history.clear();
        if (action == 'dispose') controller.dispose();
        wait.complete(http.Response(jsonEncode(assessment()), 200));
        await work;
        if (action == 'complete') {
          expect(controller.result?.aiAssessment?.state, AiScanState.completed);
          expect(history.entries.single.id, id);
          expect(history.entries.single.source, ScanSource.screenshot);
          expect(history.entries.single.reviewedForAi, isTrue);
        } else {
          expect(history.entries, isEmpty);
          if (action == 'edit')
            expect(controller.result?.text, 'A newer message');
          else if (action != 'dispose')
            expect(
              controller.result?.aiAssessment?.state,
              AiScanState.cancelled,
            );
        }
        if (action != 'dispose') controller.dispose();
        history.dispose();
      },
    );
  }
  test(
    'history serializes completed AI but never resumes pending inference',
    () async {
      final storage = MemoryStorage();
      final history = HistoryStore(storage);
      await history.setEnabled(true);
      final controller = ScanController();
      await controller.check(const ScanInput('Send your OTP'));
      await history.save(
        controller.result!.withAi(const AiAssessment(AiScanState.checking)),
        expectedGeneration: 0,
      );
      await history.load();
      expect(history.entries.single.aiAssessment?.state, AiScanState.cancelled);
      controller.dispose();
      history.dispose();
    },
  );
}
