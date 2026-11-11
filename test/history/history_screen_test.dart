import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/history/history_screen.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/scan/scan_models.dart';
import 'package:usisa/features/settings/settings_store.dart';
import 'package:usisa/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'filters use the injected clock, bulk selection stays scoped, and single delete supports Undo',
    (tester) async {
      final now = DateTime.utc(2030);
      final storage = MemoryStorage();
      final history = HistoryStore(storage, clock: () => now)..enabled = true;
      for (final sample in [
        ('alpha', ScanSource.sms, 8),
        ('beta', ScanSource.text, 1),
      ]) {
        await history.save(
          ScanResult(
            id: sample.$1,
            text: '${sample.$1} synthetic message',
            source: sample.$2,
            findings: sample.$1 == 'alpha'
                ? [const Finding('codeRequest', severity: RiskLevel.high)]
                : [],
            links: [],
            createdAt: now.subtract(Duration(days: sample.$3)),
          ),
          expectedGeneration: 0,
        );
      }
      addTearDown(history.dispose);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HistoryScreen(
              history: history,
              settings: SettingsStore(storage),
              onEnable: () {},
              onScan: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(HistoryScreen)));
      await tester.tap(find.text(l.filters));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, l.riskLabel('high')));
      await tester.tap(find.widgetWithText(ChoiceChip, l.sourceLabel('text')));
      await tester.ensureVisible(find.text(l.continueAction));
      await tester.tap(find.text(l.continueAction));
      await tester.pumpAndSettle();
      expect(find.text(l.noMatches), findsOneWidget);
      await tester.tap(find.text(l.clearFilters));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.filters));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, l.last7));
      await tester.ensureVisible(find.text(l.continueAction));
      await tester.tap(find.text(l.continueAction));
      await tester.pumpAndSettle();
      expect(find.text(l.resultCount(1)), findsOneWidget);
      await tester.tap(find.text(l.clearFilters));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'alpha');
      await tester.pump(const Duration(milliseconds: 301));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.select));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.selectAll));
      await tester.pumpAndSettle();
      expect(find.text(l.selectedCount(1)), findsOneWidget);
      await tester.tap(find.text(l.deleteSelected));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, l.cancel),
        ),
      );
      await tester.pumpAndSettle();
      expect(history.entries, hasLength(2));
      await tester.tap(find.text(l.deleteSelected));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l.deleteSelected));
      await tester.pumpAndSettle();
      expect(history.entries.single.id, 'beta');
      await tester.tap(find.text(l.clearFilters));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.undo));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 6));
      expect(history.entries.single.id, 'beta');
      await tester.tap(find.byTooltip(l.delete));
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(history.entries, isEmpty);
      expect(storage.values.keys.where((k) => k.startsWith('scan.')), isEmpty);
    },
  );
}
