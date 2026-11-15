import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:usisa/app.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/settings/settings_store.dart';
import 'package:usisa/widgets/usisa_action_button.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'consented native lookup displays live threat and no-match coverage',
    (tester) async {
      final gateway = Uri.parse(
        const String.fromEnvironment('USISA_GATEWAY_URL'),
      );
      final capabilityResult = await tester.runAsync(() async {
        try {
          return await http
              .get(gateway.resolve('/v1/capabilities'))
              .timeout(const Duration(seconds: 30));
        } catch (error) {
          return error;
        }
      });
      if (capabilityResult is! http.Response) {
        fail('Gateway capability check failed: $capabilityResult');
      }
      expect(
        capabilityResult.statusCode,
        200,
        reason:
            'The phone must reach the public gateway over its own internet.',
      );
      final storage = MemoryStorage();
      await SettingsStore(storage).update(onboarded: true);
      await tester.pumpWidget(UsisaApp(storage: storage));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scan Message'));
      await tester.pumpAndSettle();
      Future<void> openLinkDetails(String host) async {
        await tester.tap(find.text('Links in this message'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(host));
        await tester.pumpAndSettle();
      }

      for (final threat in [true, false]) {
        final host = threat
            ? 'testsafebrowsing.appspot.com'
            : 'www.google.com';
        await tester.enterText(
          find.byType(TextField).first,
          threat
              ? 'http://testsafebrowsing.appspot.com/s/malware.html'
              : 'https://www.google.com/',
        );
        await tester.pump();
        final scanButton = find.widgetWithText(
          UsisaActionButton,
          'Scan Message',
        );
        await tester.ensureVisible(scanButton);
        await tester.tap(scanButton);
        await tester.pumpAndSettle();
        await openLinkDetails(host);
        final online = find.text('Check links online');
        expect(
          online,
          findsOneWidget,
          reason:
              'Link detail text: ${tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).whereType<String>().join(' | ')}',
        );
        await tester.ensureVisible(online);
        await tester.tap(online);
        await tester.pumpAndSettle();
        if (threat) {
          expect(find.text('Enable online link checks?'), findsOneWidget);
          await tester.tap(find.text('Keep local only'));
          await tester.pumpAndSettle();
          expect(find.text('Advisory provided by Google'), findsNothing);
          await openLinkDetails(host);
          await tester.tap(online);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Enable online checks'));
          await tester.pumpAndSettle();
        } else {
          expect(find.text('Enable online link checks?'), findsNothing);
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 5)),
        );
        await tester.pumpAndSettle();
        await openLinkDetails(host);
        final completion = threat
            ? find.text('Advisory provided by Google')
            : find.text('Not on the threat list. That does not prove it is safe.');
        for (
          var attempt = 0;
          attempt < 80 && completion.evaluate().isEmpty;
          attempt++
        ) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(completion, findsOneWidget);
        expect(find.textContaining('Last checked:'), findsWidgets);
        if (threat) expect(find.text('High Risk'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        if (threat) {
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
        }
      }
    },
  );
}
