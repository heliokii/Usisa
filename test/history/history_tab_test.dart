import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/check/check.dart';
import 'package:usisa/features/history/history_store.dart';

import '../check/scan_message_test.dart' show pasteAndCheck;

var checks = 0;

/// A fake Check: Be careful with a followed short link, numbered so a fresh result is visible.
Future<CheckResult> fakeCheck(CheckInput input) async {
  checks++;
  return CheckResult(
    text: input.text,
    verdict: checks == 1 ? Verdict.beCareful : Verdict.dangerous,
    reasons: const ['urgency', 'unresolved_link'],
    checkedOnPhone: false,
    destinations: const ['shop.example.ph/sale'],
  );
}

Future<MemoryStorage> startApp(WidgetTester tester, {MemoryStorage? storage}) async {
  checks = 0;
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  storage ??= MemoryStorage();
  await tester.pumpWidget(UsisaApp(storage: storage, runCheck: fakeCheck));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  return storage;
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> backToHome(WidgetTester tester) async {
  await tester.pageBack();
  await settle(tester);
  await tester.pageBack();
  await settle(tester);
}

Future<void> openHistory(WidgetTester tester) async {
  await tester.tap(find.byType(NavigationDestination).at(1));
  await settle(tester);
}

void main() {
  testWidgets('History is on by default, saved only on this phone, and a check appears in it', (tester) async {
    await startApp(tester);
    await openHistory(tester);
    expect(find.text('Saved only on this phone'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch).last).value, isTrue);
    expect(find.text('No saved checks yet.'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Check')));
    await settle(tester);
    await pasteAndCheck(tester, 'Sale today only! bit.ly/promo');
    await backToHome(tester);
    await openHistory(tester);

    expect(find.text('Sale today only! bit.ly/promo'), findsOneWidget);
    expect(find.text('Be careful'), findsOneWidget);
  });

  testWidgets('reopening an entry shows the saved verdict, reasons and destination, then Check again', (tester) async {
    await startApp(tester);
    await pasteAndCheck(tester, 'Sale today only! bit.ly/promo');
    await backToHome(tester);
    await openHistory(tester);

    await tester.tap(find.text('Sale today only! bit.ly/promo'));
    await settle(tester);
    expect(find.text('Be careful'), findsOneWidget);
    expect(find.text('It rushes you to act quickly'), findsOneWidget);
    expect(find.text("We couldn't see where the link goes"), findsOneWidget);
    expect(find.text('Really goes to shop.example.ph/sale'), findsOneWidget);
    expect(find.textContaining('Checked on '), findsOneWidget);

    await tester.ensureVisible(find.text('Check again'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check again'));
    await settle(tester);
    expect(checks, 2);
    expect(find.text('Dangerous'), findsOneWidget);
    expect(find.textContaining('Checked on '), findsNothing);

    await tester.pageBack();
    await settle(tester);
    expect(find.text('Dangerous'), findsOneWidget, reason: 'the fresh result is saved too');
    expect(find.text('Be careful'), findsOneWidget);
  });

  testWidgets('delete one entry', (tester) async {
    await startApp(tester);
    await pasteAndCheck(tester, 'First text');
    await backToHome(tester);
    await pasteAndCheck(tester, 'Second text');
    await backToHome(tester);
    await openHistory(tester);

    await tester.tap(find.descendant(
      of: find.ancestor(of: find.text('First text'), matching: find.byType(Card)),
      matching: find.text('Delete'),
    ));
    await settle(tester);
    expect(find.text('First text'), findsNothing);
    expect(find.text('Second text'), findsOneWidget);
  });

  testWidgets('clear all asks first', (tester) async {
    final storage = await startApp(tester);
    await pasteAndCheck(tester, 'First text');
    await backToHome(tester);
    await openHistory(tester);

    await tester.tap(find.text('Clear all'));
    await settle(tester);
    expect(find.text('Clear all History?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.text('First text'), findsOneWidget);

    await tester.tap(find.text('Clear all'));
    await settle(tester);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Clear all')));
    await settle(tester);
    expect(find.text('First text'), findsNothing);
    expect(storage.values.keys.where((k) => k.startsWith('scan.')), isEmpty);
  });

  testWidgets('turning saving off clears History and stops saving checks', (tester) async {
    final storage = await startApp(tester);
    await pasteAndCheck(tester, 'First text');
    await backToHome(tester);
    await openHistory(tester);

    await tester.tap(find.byType(Switch).last);
    await settle(tester);
    expect(find.text('First text'), findsNothing);
    expect(find.text('Saving is off.'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Check')));
    await settle(tester);
    await pasteAndCheck(tester, 'Second text');
    await backToHome(tester);
    await openHistory(tester);
    expect(find.text('Second text'), findsNothing);
    expect(storage.values.keys.where((k) => k.startsWith('scan.')), isEmpty);
    expect(jsonDecode(storage.values['settings']!)['saveHistory'], isFalse);
  });

  testWidgets('a saved SMS warning loads at start and is marked From your texts', (tester) async {
    final storage = MemoryStorage();
    final entry = HistoryEntry(
      id: 'sms-1',
      checkedAt: DateTime.now().subtract(const Duration(hours: 1)),
      source: CheckSource.sms,
      result: const CheckResult(text: 'Your parcel is held', verdict: Verdict.dangerous, reasons: [], checkedOnPhone: true),
    );
    await storage.write('scan.sms-1', jsonEncode(entry.toJson()));
    await startApp(tester, storage: storage);
    await openHistory(tester);

    expect(find.text('Your parcel is held'), findsOneWidget);
    expect(find.text('From your texts'), findsOneWidget);
  });

  testWidgets('History lays out on a small phone with Filipino and 200% text', (tester) async {
    final storage = MemoryStorage();
    await storage.write('settings', jsonEncode({'language': 'fil'}));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final entry = HistoryEntry(
      id: 'long',
      checkedAt: DateTime.now(),
      source: CheckSource.sms,
      result: CheckResult(text: 'Mahabang mensahe ' * 30, verdict: Verdict.couldntCheck, reasons: const [], checkedOnPhone: true),
    );
    await storage.write('scan.long', jsonEncode(entry.toJson()));
    await startApp(tester, storage: storage);
    tester.view.physicalSize = const Size(320, 640);
    await openHistory(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Sa phone na ito lang naka-save'), findsOneWidget);
    await tester.dragUntilVisible(find.text('Mula sa iyong mga text'), find.byType(ListView), const Offset(0, -200));
    expect(tester.takeException(), isNull);
  });
}
