import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/history/history_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native encrypted storage and manual evidence flow', (
    tester,
  ) async {
    const storage = SecureStorage();
    const key = 'integration-fixture';
    try {
      await storage.write(key, 'synthetic private round-trip');
      expect((await storage.readAll())[key], 'synthetic private round-trip');
    } finally {
      await storage.delete(key);
    }
    expect((await storage.readAll()).containsKey(key), isFalse);
    await tester.pumpWidget(const UsisaApp(storage: storage));
    await tester.pumpAndSettle();
    if (find.text('Start checking').evaluate().isNotEmpty) {
      await tester.ensureVisible(find.text('Start checking'));
      await tester.tap(find.text('Start checking'));
      await tester.pumpAndSettle();
    }
    await tester.enterText(
      find.byType(TextField).first,
      'BPI: Provide your OTP immediately to restore account access. https://bpi.com.ph.evil.test',
    );
    await tester.ensureVisible(find.text('Check message'));
    await tester.tap(find.text('Check message'));
    await tester.pumpAndSettle();
    expect(find.text('High risk'), findsWidgets);
    expect(find.text('Asks for a security secret'), findsOneWidget);
    expect(find.text('Link safety is unknown.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('Provide your OTP immediately'), findsOneWidget);
  });
}
