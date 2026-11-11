import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:usisa/app.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/settings/settings_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'explicit native reviewed text produces an attributed live AI assessment',
    (tester) async {
      final gateway = Uri.parse(
        const String.fromEnvironment('USISA_GATEWAY_URL'),
      );
      final capabilities = await tester.runAsync(
        () => http
            .get(gateway.resolve('/v1/capabilities'))
            .timeout(const Duration(seconds: 5)),
      );
      expect(jsonDecode(capabilities!.body)['aiScanning'], true);
      final storage = MemoryStorage();
      await SettingsStore(storage).update(onboarded: true);
      await tester.pumpWidget(UsisaApp(storage: storage));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'Private original not submitted',
      );
      await tester.ensureVisible(find.text('AI assisted'));
      await tester.tap(find.text('AI assisted'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Review for AI check'));
      await tester.tap(find.text('Review for AI check'));
      await tester.pumpAndSettle();
      expect(find.text('Send this text for AI check'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField),
        'GCash support: Send your OTP immediately to prevent account suspension.',
      );
      await tester.ensureVisible(find.text('Send this text for AI check'));
      await tester.tap(find.text('Send this text for AI check'));
      for (
        var n = 0;
        n < 100 &&
            find
                .textContaining('Groq · openai/gpt-oss-120b')
                .evaluate()
                .isEmpty;
        n++
      ) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(
        find.textContaining('Groq · openai/gpt-oss-120b · ph-scam-v1'),
        findsOneWidget,
      );
      expect(find.text('High risk'), findsWidgets);
      expect(find.textContaining('AI assessment unavailable'), findsNothing);
      expect(
        find.text('This result uses the text reviewed for AI.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
