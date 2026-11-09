import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/settings/settings_store.dart';

void main() {
  testWidgets('Filipino dark theme and tablet rail follow saved preferences', (
    tester,
  ) async {
    final storage = MemoryStorage();
    await SettingsStore(storage)
        .update(language: 'fil', theme: ThemeMode.dark, onboarded: true);
    await tester.pumpWidget(UsisaApp(storage: storage));
    await tester.pumpAndSettle();
    expect(find.text('Suriin bago pindutin.'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(TextField).first)).brightness,
      Brightness.dark,
    );
  });
  testWidgets('scan shell keeps draft across destinations', (tester) async {
    await tester.pumpWidget(const UsisaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start checking'));
    await tester.pumpAndSettle();
    expect(find.text('Check before you tap.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'My private draft');
    await tester.tap(find.text('History').last);
    await tester.pumpAndSettle();
    expect(find.text('Your checks, kept private.'), findsOneWidget);
    await tester.tap(find.text('Scan').last);
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
    await tester.ensureVisible(find.text('Start checking'));
    await tester.tap(find.text('Start checking'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
