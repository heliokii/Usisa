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
  testWidgets(
    'landscape keyboard and reduced motion preserve the scan journey',
    (tester) async {
      tester.view.physicalSize = const Size(840, 390);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 160);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final storage = MemoryStorage();
      await SettingsStore(storage).update(onboarded: true);
      await tester.pumpWidget(UsisaApp(storage: storage));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Scan Message').last);
      await tester.tap(find.text('Scan Message').last);
      await tester.pumpAndSettle();
      const text = 'GCash: Send your OTP immediately.\nKeep this draft.';
      await tester.enterText(find.byType(TextField).first, text);
      await tester.ensureVisible(find.text('Check message'));
      await tester.tap(find.text('Check message'));
      await tester.pumpAndSettle();
      expect(find.text('High risk'), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.liveRegion == true,
        ),
        findsWidgets,
      );
      await tester.ensureVisible(find.text('Asks for a security secret'));
      await tester.tap(find.text('Asks for a security secret'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(text), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('scan controls have labels and Android sized tap targets', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      final storage = MemoryStorage();
      await SettingsStore(storage).update(onboarded: true);
      await tester.pumpWidget(UsisaApp(storage: storage));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    } finally {
      handle.dispose();
    }
  });

  testWidgets('brand palette keeps body and risk text above 4.5:1 contrast', (
    tester,
  ) async {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
    }

    for (final theme in [UsisaTheme.light]) {
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
    for (final filipino in [false, true]) {
      testWidgets(
        'core screens at ${width}px / ${filipino ? 'Filipino' : 'English'} / 200% text',
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
            language: filipino ? 'fil' : 'en',
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
          final l = AppLocalizations.of(tester.element(find.text('Usisa')));
          await tester.tap(find.text(l.history).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
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
          await tester.tap(find.text(l.home).last);
          await tester.pumpAndSettle();
          await tester.tap(find.text(l.learn).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text(l.home).last);
          await tester.pumpAndSettle();
          await tester.tap(find.text(l.settings).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text(l.home).last);
          await tester.pumpAndSettle();
          final scanCard = find.text(l.scanMessageCard).last;
          await tester.ensureVisible(scanCard);
          await tester.pumpAndSettle();
          await tester.tap(scanCard);
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField).first, sample.text);
          final checkButton = find.widgetWithText(FilledButton, l.checkMessage);
          await tester.ensureVisible(checkButton);
          await tester.tap(checkButton);
          await tester.pumpAndSettle();
          expect(find.text(l.riskLabel('high')), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
