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
    'consented native lookup displays live threat and no-match coverage',
    (tester) async {
      final gateway = Uri.parse(
        const String.fromEnvironment('USISA_GATEWAY_URL'),
      );
      final capabilities = await http
          .get(gateway.resolve('/v1/capabilities'))
          .timeout(const Duration(seconds: 5));
      expect(
        capabilities.statusCode,
        200,
        reason: 'The emulator must reach the development gateway.',
      );
      final storage = MemoryStorage();
      await SettingsStore(storage).update(onboarded: true);
      await tester.pumpWidget(UsisaApp(storage: storage));
      await tester.pumpAndSettle();
      for (final threat in [true, false]) {
        await tester.enterText(
          find.byType(TextField).first,
          threat
              ? 'http://testsafebrowsing.appspot.com/s/malware.html'
              : 'https://www.google.com/',
        );
        await tester.ensureVisible(find.text('Check message'));
        await tester.tap(find.text('Check message'));
        await tester.pumpAndSettle();
        final online = find.text('Check links online');
        await tester.ensureVisible(online);
        await tester.tap(online);
        await tester.pumpAndSettle();
        if (threat) {
          expect(find.text('Enable online link checks?'), findsOneWidget);
          await tester.tap(find.text('Keep local only'));
          await tester.pumpAndSettle();
          expect(find.text('Advisory provided by Google'), findsNothing);
          await tester.tap(online);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Enable online checks'));
        } else {
          expect(find.text('Enable online link checks?'), findsNothing);
        }
        final completion = threat
            ? find.text('Advisory provided by Google')
            : find.textContaining(
                'Not on the provider threat list; this does not prove safety',
              );
        for (
          var attempt = 0;
          attempt < 80 && completion.evaluate().isEmpty;
          attempt++
        ) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(completion, findsOneWidget);
        expect(find.textContaining('Last checked:'), findsWidgets);
        if (threat) expect(find.text('High risk'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    },
  );
}
