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
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      expect(find.text('Stay one step ahead of scams.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(storage.values['settings'], contains('"onboarded":true'));
      expect(storage.values['settings'], contains('"saveHistory":false'));
      expect(storage.values['settings'], contains('"onlineLinkChecks":false'));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(UsisaApp(storage: storage));
      await tester.pumpAndSettle();
      expect(find.text('Get Started'), findsNothing);
      expect(find.text('Stay one step ahead of scams.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    },
  );
}
