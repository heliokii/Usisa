import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/history/history_store.dart';

const tiles = ['Scan a message', 'Check a link', 'Scan a screenshot', 'AI scan'];

Future<void> startApp(WidgetTester tester, {MemoryStorage? storage}) async {
  // A typical phone screen.
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UsisaApp(storage: storage ?? MemoryStorage()));
  // The header drift repeats forever, so pump past the entrance instead of settling.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('app starts with in-memory storage and shows the four tiles and the SMS card', (tester) async {
    await startApp(tester);

    for (final title in tiles) {
      expect(find.text(title), findsOneWidget);
      final tile = find.ancestor(of: find.text(title), matching: find.byType(InkWell)).first;
      expect(find.descendant(of: tile, matching: find.byType(Icon)), findsNothing);
    }
    expect(find.text('Auto SMS protection'), findsOneWidget);
    expect(find.text('Texts are not being checked'), findsOneWidget);

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('bottom nav has Check, History, Learn and Settings and switches tabs', (tester) async {
    await startApp(tester);

    final nav = find.byType(NavigationBar);
    for (final label in ['Check', 'History', 'Learn', 'Settings']) {
      expect(find.descendant(of: nav, matching: find.text(label)), findsOneWidget);
    }
    expect(tester.widget<NavigationBar>(nav).backgroundColor, Colors.white);

    await tester.tap(find.descendant(of: nav, matching: find.text('Learn')));
    await tester.pump();
    expect(find.text('Scan a message'), findsNothing);

    await tester.tap(find.descendant(of: nav, matching: find.text('Check')));
    await tester.pump();
    expect(find.text('Scan a message'), findsOneWidget);
  });

  testWidgets('home follows the saved Filipino language', (tester) async {
    final storage = MemoryStorage();
    await storage.write('settings', jsonEncode({'language': 'fil'}));
    await startApp(tester, storage: storage);

    expect(find.text('I-scan ang mensahe'), findsOneWidget);
    expect(find.text('Suriin'), findsOneWidget);
  });

  testWidgets('home lays out on a small phone with Filipino and 200% text', (tester) async {
    final storage = MemoryStorage();
    await storage.write('settings', jsonEncode({'language': 'fil'}));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await startApp(tester, storage: storage);
    tester.view.physicalSize = const Size(320, 640);
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.dragUntilVisible(find.byType(Switch), find.byType(CustomScrollView), const Offset(0, -200));
    expect(tester.takeException(), isNull);
    expect(find.text('Awtomatikong proteksyon sa SMS'), findsOneWidget);
  });
}
