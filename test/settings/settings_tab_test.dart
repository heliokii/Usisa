import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/history/history_store.dart';

import '../check/check_link_test.dart' show FakeGateway, checkLink, consented, settle, startApp;

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await settle(tester);
}

Future<void> tapInSettings(WidgetTester tester, Finder target) async {
  await tester.dragUntilVisible(target, find.byType(ListView), const Offset(0, -200));
  await tester.pump();
  await tester.tap(target);
  await settle(tester);
}

Finder switchIn(String title) =>
    find.descendant(of: find.widgetWithText(SwitchListTile, title), matching: find.byType(Switch));

void main() {
  testWidgets('Settings is one page of Display, Protection, Online checks, History and About cards', (tester) async {
    await startApp(tester, FakeGateway());
    await openTab(tester, 'Settings');
    for (final title in ['Display', 'Protection', 'Online checks', 'History', 'About']) {
      await tester.dragUntilVisible(find.text(title), find.byType(ListView), const Offset(0, -200));
      expect(find.text(title), findsWidgets);
    }
  });

  testWidgets('text size applies app-wide on top of the phone setting and is remembered', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final storage = MemoryStorage();
    await startApp(tester, FakeGateway(), storage: storage);
    double scaleOn(String text) => MediaQuery.textScalerOf(tester.element(find.text(text).first)).scale(10) / 10;

    await openTab(tester, 'Settings');
    expect(scaleOn('Display'), closeTo(1.5, .001), reason: 'Normal keeps the phone setting');

    await tapInSettings(tester, find.text('Large'));
    expect(scaleOn('Display'), closeTo(1.5 * 1.2, .001));
    await openTab(tester, 'Check');
    expect(scaleOn('Scan a message'), closeTo(1.5 * 1.2, .001), reason: 'applies on every tab');
    expect(jsonDecode(storage.values['settings']!)['textSize'], 'large');

    await openTab(tester, 'Settings');
    await tapInSettings(tester, find.text('Extra large'));
    expect(scaleOn('Display'), closeTo(1.5 * 1.4, .001));
  });

  testWidgets('switching language to Filipino changes the strings', (tester) async {
    final storage = MemoryStorage();
    await startApp(tester, FakeGateway(), storage: storage);
    await openTab(tester, 'Settings');
    await tapInSettings(tester, find.text('Filipino'));

    expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Suriin')), findsOneWidget);
    expect(find.text('Itsura'), findsOneWidget);
    expect(jsonDecode(storage.values['settings']!)['language'], 'fil');
  });

  testWidgets('turning online checks off makes link checks phone-only', (tester) async {
    final gateway = FakeGateway();
    final storage = consented(true);
    await startApp(tester, gateway, storage: storage);
    await openTab(tester, 'Settings');
    final online = switchIn('Check links and use AI online');
    await tester.dragUntilVisible(online, find.byType(ListView), const Offset(0, -200));
    expect(tester.widget<Switch>(online).value, isTrue);

    await tapInSettings(tester, online);
    expect(tester.widget<Switch>(online).value, isFalse);
    expect(jsonDecode(storage.values['settings']!)['onlineLinkChecks'], isFalse);

    await openTab(tester, 'Check');
    await checkLink(tester, 'bit.ly/shopee-sale');
    expect(find.text('Check links online?'), findsNothing);
    expect(find.text('Checked on your phone'), findsOneWidget);
    expect(gateway.linkChecks, isEmpty);
  });

  testWidgets('turning online checks on counts as consent: no question, the link goes online', (tester) async {
    final gateway = FakeGateway();
    await startApp(tester, gateway);
    await openTab(tester, 'Settings');
    await tapInSettings(tester, switchIn('Check links and use AI online'));

    await openTab(tester, 'Check');
    await checkLink(tester, 'bit.ly/shopee-sale');
    expect(find.text('Check links online?'), findsNothing);
    expect(gateway.linkChecks, hasLength(1));
  });

  testWidgets('the Protection switch and the home SMS card are the same switch', (tester) async {
    await startApp(tester, FakeGateway());
    await openTab(tester, 'Settings');
    await tapInSettings(tester, switchIn('Auto SMS protection'));
    expect(tester.widget<Switch>(switchIn('Auto SMS protection')).value, isTrue);

    await openTab(tester, 'Check');
    expect(find.text('Texts are not being checked'), findsNothing);
  });

  testWidgets('the History card turns saving off like the History tab does', (tester) async {
    final storage = MemoryStorage();
    await startApp(tester, FakeGateway(), storage: storage);
    await openTab(tester, 'Settings');
    await tapInSettings(tester, switchIn('Save my checks'));
    expect(jsonDecode(storage.values['settings']!)['saveHistory'], isFalse);

    await openTab(tester, 'History');
    expect(find.text('Saving is off.'), findsOneWidget);
  });

  testWidgets('About says Usisa is a guide, never a guarantee', (tester) async {
    await startApp(tester, FakeGateway());
    await openTab(tester, 'Settings');
    final about = find.textContaining('a guide, not a guarantee');
    await tester.dragUntilVisible(about, find.byType(ListView), const Offset(0, -200));
    expect(about, findsOneWidget);
    for (final claim in ['100%', 'definitely', 'always safe', 'guaranteed']) {
      expect(find.textContaining(claim), findsNothing);
    }
  });

  testWidgets('Settings lays out on a small phone in Filipino with extra large and 200% text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final storage = MemoryStorage()..values['settings'] = jsonEncode({'language': 'fil', 'textSize': 'extraLarge'});
    await startApp(tester, FakeGateway(), storage: storage);
    tester.view.physicalSize = const Size(320, 640);
    await openTab(tester, 'Mga setting');
    expect(tester.takeException(), isNull);
    await tester.dragUntilVisible(find.text('Tungkol sa Usisa'), find.byType(ListView), const Offset(0, -200));
    expect(tester.takeException(), isNull);
  });
}
