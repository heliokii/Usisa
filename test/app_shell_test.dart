import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/settings/settings_store.dart';
import 'package:usisa/features/scan/scan_models.dart';

void main() {
  testWidgets('foreground deadlines and resume erase expired private data', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 11, 10);
    final storage = MemoryStorage();
    await SettingsStore(storage).update(onboarded: true, saveHistory: true);
    for (final seconds in [10, 20]) {
      final result = ScanResult(
        id: 'expiry-$seconds',
        text: 'synthetic retention $seconds',
        source: ScanSource.text,
        findings: [],
        links: [],
        createdAt: now
            .subtract(const Duration(days: 30))
            .add(Duration(seconds: seconds)),
      );
      await storage.write('scan.${result.id}', jsonEncode(result.toJson()));
    }
    await storage.write(
      'draft',
      jsonEncode({
        'text': 'synthetic private draft',
        'createdAt': now
            .subtract(const Duration(hours: 24))
            .add(const Duration(seconds: 20))
            .toIso8601String(),
      }),
    );
    await tester.pumpWidget(UsisaApp(storage: storage, clock: () => now));
    await tester.pumpAndSettle();
    now = now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(storage.values.containsKey('scan.expiry-10'), isFalse);
    expect(storage.values.containsKey('scan.expiry-20'), isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 20));
    await tester.pump(const Duration(seconds: 20));
    expect(storage.values.containsKey('draft'), isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(storage.values.containsKey('draft'), isFalse);
    expect(storage.values.containsKey('scan.expiry-20'), isFalse);
  });
  testWidgets(
    'Filipino language uses the fixed brand palette and tablet rail',
    (tester) async {
      final storage = MemoryStorage();
      await SettingsStore(storage).update(language: 'fil', onboarded: true);
      await tester.pumpWidget(UsisaApp(storage: storage));
      await tester.pumpAndSettle();
      expect(find.text('Isang hakbang sa unahan ng mga scam.'), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(
        Theme.of(
          tester.element(find.text('Isang hakbang sa unahan ng mga scam.')),
        ).brightness,
        Brightness.light,
      );
    },
  );
  testWidgets('scan shell keeps draft across destinations', (tester) async {
    final storage = MemoryStorage();
    await SettingsStore(storage)
        .update(onboarded: true, restoreDraft: true, saveHistory: true);
    await tester.pumpWidget(UsisaApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan Message'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'My private draft');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('History').last);
    await tester.pumpAndSettle();
    expect(find.text('Your checks, kept private.'), findsOneWidget);
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan Message'));
    await tester.pumpAndSettle();
    expect(find.text('My private draft'), findsOneWidget);
  });

  testWidgets('compact shell supports large text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const UsisaApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Home'), findsOneWidget);
  });
}
