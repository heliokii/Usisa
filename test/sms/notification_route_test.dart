import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/scan/scam_analyzer.dart';
import 'package:usisa/features/scan/scan_models.dart';
import 'package:usisa/features/settings/settings_store.dart';
import 'package:usisa/features/sms/sms_review_screen.dart';
import 'package:usisa/features/sms/sms_service.dart';
import 'package:usisa/l10n/app_localizations.dart';
import 'package:usisa/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('usisa/sms');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const id = 'a47ba739-041c-46b8-a349-f90abcfd8bf5';
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Future<void> show(
    WidgetTester tester,
    SmsService sms,
    HistoryStore history,
  ) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SmsReviewScreen(
        id: id,
        sms: sms,
        history: history,
        settings: SettingsStore(history.storage),
      ),
    ),
  );

  testWidgets(
    'expired notification opens a recoverable explanation without a risk verdict',
    (tester) async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'status'
            ? {'generation': 2, 'supported': true}
            : null,
      );
      final sms = SmsService(nativePlatform: true);
      addTearDown(sms.dispose);
      await show(tester, sms, HistoryStore(MemoryStorage()));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('This SMS review is unavailable.'),
        findsOneWidget,
      );
      expect(find.text('Low risk'), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
    },
  );

  testWidgets(
    'clear during notification load cannot resurrect private history',
    (tester) async {
      final pending = Completer<Map<String, dynamic>>();
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'status'
            ? {'generation': 2, 'supported': true}
            : pending.future,
      );
      final sms = SmsService(nativePlatform: true);
      addTearDown(sms.dispose);
      final history = HistoryStore(MemoryStorage())..enabled = true;
      await show(tester, sms, history);
      await tester.pump();
      await history.clear();
      final local = ScamAnalyzer().analyze(
        const ScanInput(
          'BDO: Submit your PIN immediately.',
          source: ScanSource.sms,
        ),
      );
      final json = local.toJson()..['id'] = id;
      pending.complete({'body': local.text, 'generation': 2, 'result': json});
      await tester.pumpAndSettle();
      expect(history.entries, isEmpty);
      expect(
        find.textContaining('This SMS review is unavailable.'),
        findsOneWidget,
      );
      expect(find.text('High risk'), findsNothing);
    },
  );
  testWidgets(
    'an explicitly retained SMS remains reviewable after its temporary copy expires',
    (tester) async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'status'
            ? {'generation': 2, 'supported': true}
            : null,
      );
      final sms = SmsService(nativePlatform: true);
      addTearDown(sms.dispose);
      final history = HistoryStore(MemoryStorage())..enabled = true;
      final local = ScamAnalyzer().analyze(
        const ScanInput(
          'BDO: Submit your PIN immediately.',
          source: ScanSource.sms,
        ),
      );
      await history.save(
        ScanResult.fromJson(local.toJson()..['id'] = id),
        expectedGeneration: 0,
      );
      await show(tester, sms, history);
      await tester.pumpAndSettle();
      expect(find.text('High risk'), findsWidgets);
      expect(
        find.textContaining('This SMS review is unavailable.'),
        findsNothing,
      );
    },
  );
  testWidgets('repeated warm notification tap does not reopen after Back', (
    tester,
  ) async {
    String? pending = id;
    final local = ScamAnalyzer().analyze(
      const ScanInput(
        'BDO: Submit your PIN immediately.',
        source: ScanSource.sms,
      ),
    );
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'status') return {'generation': 0, 'supported': true};
      if (call.method == 'takeNotification') {
        final value = pending;
        pending = null;
        return value;
      }
      if (call.method == 'review') {
        return {
          'body': local.text,
          'generation': 0,
          'result': local.toJson()..['id'] = id,
        };
      }
      return null;
    });
    final storage = MemoryStorage();
    await SettingsStore(storage).update(onboarded: true);
    await tester.pumpWidget(
      UsisaApp(storage: storage, sms: SmsService(nativePlatform: true)),
    );
    await tester.pumpAndSettle();
    expect(find.text('High risk'), findsWidgets);
    pending = id;
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('notification', id),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('High risk'), findsNothing);
    expect(find.text('Check before you tap.'), findsOneWidget);
  });
}
