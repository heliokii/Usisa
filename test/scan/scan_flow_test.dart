import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/settings/settings_store.dart';
import 'package:usisa/l10n/app_localizations.dart';
import 'package:usisa/widgets/usisa_action_button.dart';

void main() {
  testWidgets('manual check explains warnings and does not activate the URL', (
    tester,
  ) async {
    final storage = MemoryStorage();
    await SettingsStore(storage).update(onboarded: true);
    await tester.pumpWidget(UsisaApp(storage: storage));
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.text('Scan Message')));
    await tester.tap(find.text(l.scanMessageCard));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'GCash: Send your OTP now or your account will be suspended. https://gcash.com.evil.test',
    );
    await tester.pump();
    final scanButton = find.widgetWithText(
      UsisaActionButton,
      l.scanMessageCard,
    );
    await tester.ensureVisible(scanButton);
    expect(tester.widget<UsisaActionButton>(scanButton).onPressed, isNotNull);
    await tester.tapAt(tester.getCenter(scanButton));
    await tester.pumpAndSettle();
    expect(find.text(l.resultRiskLabel('high')), findsWidgets);
    expect(find.text(l.detectedSigns), findsOneWidget);
    expect(find.text(l.findingTitle('codeRequest')), findsOneWidget);
    expect(find.text(l.unknownLink), findsOneWidget);
    await tester.ensureVisible(find.text(l.findingTitle('codeRequest')));
    await tester.tap(find.text(l.findingTitle('codeRequest')));
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsWidgets);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.textContaining('Send your OTP now'), findsOneWidget);
  });
  testWidgets('empty message scan stays disabled', (tester) async {
    final storage = MemoryStorage();
    await SettingsStore(storage).update(onboarded: true);
    await tester.pumpWidget(UsisaApp(storage: storage));
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.text('Scan Message')));
    await tester.tap(find.text(l.scanMessageCard));
    await tester.pumpAndSettle();
    final scanButton = find.widgetWithText(
      UsisaActionButton,
      l.scanMessageCard,
    );
    await tester.ensureVisible(scanButton);
    expect(tester.widget<UsisaActionButton>(scanButton).onPressed, isNull);
    expect(find.text(l.errorMessage('emptyInput')), findsNothing);
    expect(find.text(l.result), findsNothing);
  });
}
