import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/history/history_screen.dart';
import 'package:usisa/features/scan/scam_analyzer.dart';
import 'package:usisa/features/scan/scan_models.dart';
import 'package:usisa/features/settings/settings_store.dart';
import 'package:usisa/l10n/app_localizations.dart';
import 'package:usisa/theme/usisa_theme.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('both themes keep body and risk text above 4.5:1 contrast', (
    tester,
  ) async {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
    }

    for (final theme in [UsisaTheme.light, UsisaTheme.dark]) {
      final scheme = theme.colorScheme;
      for (final background in [
        theme.scaffoldBackgroundColor,
        scheme.surface,
      ]) {
        expect(
          contrast(scheme.onSurface, background),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(scheme.onSurfaceVariant, background),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(
        contrast(scheme.primary, scheme.onPrimary),
        greaterThanOrEqualTo(4.5),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              for (final risk in RiskLevel.values) {
                final (foreground, background, _) = UsisaTheme.risk(
                  context,
                  risk,
                );
                expect(
                  contrast(foreground, background),
                  greaterThanOrEqualTo(4.5),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      );
    }
  });
  for (final width in [320.0, 390.0, 600.0, 840.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'core screens at ${width}px / ${dark ? 'dark' : 'light'} / 200% text',
        (tester) async {
          tester.view.physicalSize = Size(width, 740);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final storage = MemoryStorage();
          await SettingsStore(storage).update(
            onboarded: true,
            saveHistory: true,
            theme: dark ? ThemeMode.dark : ThemeMode.light,
            language: dark ? 'fil' : 'en',
          );
          final sample = ScamAnalyzer().analyze(
            const ScanInput(
              'GCash: Give your PIN immediately. https://gcash.com.evil.test',
            ),
          );
          for (var i = 0; i < 100; i++) {
            await storage.write(
              'scan.layout-$i',
              jsonEncode(sample.toJson()..['id'] = 'layout-$i'),
            );
          }
          await tester.pumpWidget(UsisaApp(storage: storage));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.byIcon(Icons.history_rounded).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final l = AppLocalizations.of(
            tester.element(find.byType(HistoryScreen)),
          );
          await tester.scrollUntilVisible(
            find.byIcon(Icons.tune_rounded),
            150,
            scrollable: find
                .descendant(
                  of: find.byType(HistoryScreen),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.tap(find.byIcon(Icons.tune_rounded));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text(l.select));
          await tester.pumpAndSettle();
          await tester.tap(find.text(l.select));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.byIcon(Icons.menu_book_outlined).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.byIcon(Icons.settings_outlined));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.search_rounded).last);
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField).first, sample.text);
          await tester.ensureVisible(find.text(l.checkMessage));
          await tester.tap(find.text(l.checkMessage));
          await tester.pumpAndSettle();
          expect(find.text(l.riskLabel('high')), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
