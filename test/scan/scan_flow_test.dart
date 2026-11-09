import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app.dart';

void main() {
  testWidgets('manual check explains warnings and does not activate the URL', (
    tester,
  ) async {
    await tester.pumpWidget(const UsisaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start checking'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'GCash: Send your OTP now or your account will be suspended. https://gcash.com.evil.test',
    );
    await tester.ensureVisible(find.text('Check message'));
    await tester.tap(find.text('Check message'));
    await tester.pumpAndSettle();
    expect(find.text('High risk'), findsWidgets);
    expect(find.text('Why this was flagged'), findsOneWidget);
    expect(find.text('Asks for a security secret'), findsOneWidget);
    expect(find.text('Link safety is unknown.'), findsOneWidget);
    await tester.ensureVisible(find.text('Asks for a security secret'));
    await tester.tap(find.text('Asks for a security secret'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('Send your OTP now'), findsOneWidget);
  });
  testWidgets('invalid empty check remains in form with actionable error', (
    tester,
  ) async {
    await tester.pumpWidget(const UsisaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start checking'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Check message'));
    await tester.tap(find.text('Check message'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a message or link first.'), findsOneWidget);
    expect(find.text('Scan result'), findsNothing);
  });
}
