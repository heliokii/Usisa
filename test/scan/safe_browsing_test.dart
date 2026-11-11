import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/scan/result_screen.dart';
import 'package:usisa/features/scan/scan_models.dart';
import 'package:usisa/features/settings/settings_store.dart';
import 'package:usisa/l10n/app_localizations.dart';
import 'package:usisa/theme/usisa_theme.dart';

LinkResult advisory({
  bool expired = false,
  List<String> threats = const ['MALWARE'],
}) {
  final at = DateTime.now().subtract(Duration(minutes: expired ? 10 : 0));
  return LinkResult(
    original: 'https://submitted.example/private',
    uri: Uri.parse('https://submitted.example/private'),
    findings: [],
    provider: 'Google Safe Browsing',
    reputation: ReputationState.matched,
    checkedAt: at,
    expiresAt: at.add(const Duration(minutes: 1)),
    threatTypes: threats,
  );
}

ScanResult scan(LinkResult link, {List<Finding> findings = const []}) =>
    ScanResult(
      id: 'advisory-fixture',
      text: link.original,
      source: ScanSource.link,
      findings: findings,
      links: [link],
      createdAt: DateTime.now(),
    );

void main() {
  test(
    'expired Safe Browsing evidence cannot raise risk; local findings remain',
    () {
      final result = scan(advisory(expired: true));
      expect(result.risk, RiskLevel.low);
      expect(result.hasUncheckedLinks, isTrue);
      expect(scan(advisory()).risk, RiskLevel.high);
      expect(
        scan(
          advisory(expired: true),
          findings: [const Finding('codeRequest', severity: RiskLevel.high)],
        ).risk,
        RiskLevel.high,
      );
      final restored = LinkResult.fromJson(advisory().toJson());
      expect(restored.provider, 'Google Safe Browsing');
      final legacy = LinkResult.fromJson(
        advisory().toJson()..remove('provider'),
      );
      expect(legacy.provider, 'Google Web Risk');
    },
  );

  test('permanent history retains local evidence and check metadata without caching Google verdicts', () async {
    final storage = MemoryStorage();
    final history = HistoryStore(storage)..enabled = true;
    await history.save(
      scan(advisory()),
      expectedGeneration: history.generation,
    );
    final stored = jsonDecode(storage.values['scan.advisory-fixture']!) as Map;
    final link = (stored['links'] as List).single as Map;
    expect(link['provider'], 'Google Safe Browsing');
    expect(link['reputation'], 'unavailable');
    expect(link['threatTypes'], isEmpty);
    expect(link['checkedAt'], isNotNull);
    final reloaded = HistoryStore(storage)..enabled = true;
    await reloaded.load();
    expect(reloaded.entries.single.risk, RiskLevel.low);
    expect(reloaded.entries.single.hasUncheckedLinks, isTrue);
    history.dispose();
    reloaded.dispose();
  });

  test('old Web Risk consent cannot authorize Safe Browsing', () async {
    final storage = MemoryStorage();
    await storage.write(
      'settings',
      jsonEncode({'onlineLinkChecks': true, 'onlineDisclosure': 1}),
    );
    final settings = SettingsStore(storage);
    await settings.load();
    expect(settings.onlineLinkChecks, isFalse);
    await settings.update(onlineLinkChecks: true);
    expect(jsonDecode(storage.values['settings']!)['onlineDisclosure'], 2);
    final restored = SettingsStore(storage);
    await restored.load();
    expect(restored.onlineLinkChecks, isTrue);
  });

  for (final expired in [false, true]) {
    testWidgets(
      'Google attribution is linked only for current advisories: expired=$expired',
      (tester) async {
        Uri? opened;
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ResultScreen(
              result: scan(advisory(expired: expired)),
              advisoryLauncher: (uri) async {
                opened = uri;
                return true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final attribution = find.text('Advisory provided by Google');
        if (expired) {
          expect(attribution, findsNothing);
          expect(
            find.textContaining('Previously listed as a threat.'),
            findsNothing,
          );
          expect(find.text('Link safety is unknown.'), findsOneWidget);
        } else {
          await tester.ensureVisible(attribution);
          await tester.tap(attribution);
          await tester.pumpAndSettle();
          expect(
            opened.toString(),
            'https://developers.google.com/safe-browsing/v4/advisory',
          );
        }
      },
    );
  }

  testWidgets('threat help opens only fixed trusted help pages', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ResultScreen(
          result: scan(
            advisory(
              threats: ['MALWARE', 'SOCIAL_ENGINEERING', 'UNWANTED_SOFTWARE'],
            ),
          ),
          advisoryLauncher: (uri) async {
            opened.add(uri.toString());
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('submitted.example'));
    await tester.tap(find.text('submitted.example'));
    await tester.pumpAndSettle();
    for (final label in [
      'Learn about phishing',
      'Learn about malware',
      'Learn about unwanted software',
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(opened, [
      'https://www.antiphishing.org/',
      'https://developers.google.com/search/',
      'https://www.google.com/about/unwanted-software-policy.html',
    ]);
  });

  for (final throws in [false, true]) {
    testWidgets(
      'unavailable browser keeps the scan recoverable: throws=$throws',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ResultScreen(
              result: scan(advisory()),
              advisoryLauncher: (_) async {
                if (throws) throw StateError('No browser');
                return false;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Advisory provided by Google'));
        await tester.tap(find.text('Advisory provided by Google'));
        await tester.pump();
        expect(
          find.text(
            'Could not open the help page. Your scan is still available.',
          ),
          findsOneWidget,
        );
        expect(find.text('Link Checker'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [320.0, 840.0]) {
    testWidgets(
      'current advisory is usable at ${width}px with Filipino and 200% text',
      (tester) async {
        tester.view.physicalSize = Size(width, 740);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        var opened = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: UsisaTheme.light,
            locale: const Locale('fil'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ResultScreen(
              result: scan(advisory()),
              advisoryLauncher: (_) async {
                opened = true;
                return true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Advisory provided by Google'));
        await tester.tap(find.text('Advisory provided by Google'));
        await tester.pumpAndSettle();
        expect(opened, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
