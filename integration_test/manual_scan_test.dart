import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/settings/settings_store.dart';
import 'package:usisa/l10n/app_localizations.dart';
import 'package:usisa/widgets/usisa_action_button.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native encrypted storage and manual evidence flow', (
    tester,
  ) async {
    const storage = SecureStorage();
    const key = 'integration-fixture';
    try {
      await storage.write(key, 'synthetic private round-trip');
      expect((await storage.readAll())[key], 'synthetic private round-trip');
    } finally {
      await storage.delete(key);
    }
    expect((await storage.readAll()).containsKey(key), isFalse);
    await SettingsStore(storage).update(onboarded: true);
    await tester.pumpWidget(const UsisaApp(storage: storage));
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.text('Scan Message')));
    await tester.tap(find.text(l.scanMessageCard));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'BPI: Provide your OTP immediately to restore account access. https://bpi.com.ph.evil.test',
    );
    await tester.pump();
    final scanButton = find.widgetWithText(
      UsisaActionButton,
      l.scanMessageCard,
    );
    await tester.ensureVisible(scanButton);
    await tester.tap(scanButton);
    await tester.pumpAndSettle();
    expect(find.text(l.resultRiskLabel('high')), findsWidgets);
    expect(find.text(l.findingTitle('codeRequest')), findsOneWidget);
    expect(find.text(l.unknownLink), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.textContaining('Provide your OTP immediately'), findsOneWidget);
  });
}
