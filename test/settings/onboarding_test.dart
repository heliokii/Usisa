import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/history/history_store.dart';

void main() {
  testWidgets(
    'first run starts manual scanning with every optional permission off',
    (tester) async {
      final storage = MemoryStorage();
      await tester.pumpWidget(UsisaApp(storage: storage));
      await tester.pumpAndSettle();
      expect(find.text('Start checking'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('Start checking'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsWidgets);
      expect(storage.values['settings'], contains('"onboarded":true'));
      expect(storage.values['settings'], contains('"saveHistory":false'));
      expect(storage.values['settings'], contains('"onlineLinkChecks":false'));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(UsisaApp(storage: storage));
      await tester.pumpAndSettle();
      expect(find.text('Start checking'), findsNothing);
      expect(find.byType(TextField), findsWidgets);
    },
  );
}
