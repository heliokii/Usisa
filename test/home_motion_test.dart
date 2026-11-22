import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/history/history_store.dart';

Future<void> openHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UsisaApp(storage: MemoryStorage()));
  await tester.pump();
}

Finder tile(String title) => find.ancestor(of: find.text(title), matching: find.byType(InkWell)).first;

void main() {
  testWidgets('with reduced motion home shows its final state at once and nothing repeats', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await openHome(tester);

    final firstFrame = tester.getRect(tile('Check a link'));
    // Settling would time out if the header drift or any entrance kept running.
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.getRect(tile('Check a link')), firstFrame);

    final press = await tester.startGesture(tester.getCenter(tile('Check a link')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getRect(tile('Check a link')), firstFrame);
    await press.up();
  });

  testWidgets('otherwise home enters staggered, tiles shrink when pressed and the header drifts', (tester) async {
    await openHome(tester);

    final entering = tester.getRect(tile('Check a link'));
    await tester.pump(const Duration(seconds: 1));
    final settled = tester.getRect(tile('Check a link'));
    expect(entering.top - settled.top, closeTo(16, 1));
    // The 6s header drift keeps going.
    expect(tester.hasRunningAnimations, isTrue);

    final press = await tester.startGesture(tester.getCenter(tile('Check a link')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getRect(tile('Check a link')).width, closeTo(settled.width * .96, .5));
    await press.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getRect(tile('Check a link')).width, closeTo(settled.width, .01));
  });
}
