import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/check/check.dart';
import 'package:usisa/features/check/paste_screen.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/sms/sms_background.dart';
import 'package:usisa/features/sms/sms_service.dart';

const _id = '0b6d6e7c-1f0a-4c1e-9d8e-2a3b4c5d6e7f';
const _scam = 'Your GCash account is locked. Verify at http://gcash-verify.example now';

/// What the background Incoming SMS check stored for [_scam], made by the real background entry point.
Future<Map<String, dynamic>> _backgroundResult() async {
  const worker = MethodChannel('usisa/sms_worker');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Map<String, dynamic>? completion;
  messenger.setMockMethodCallHandler(worker, (call) async {
    if (call.method == 'takeEvent') return {'id': _id, 'body': _scam, 'sender': '09171234567'};
    completion = Map<String, dynamic>.from(call.arguments as Map);
    return null;
  });
  await runSmsBackground(channel: worker);
  messenger.setMockMethodCallHandler(worker, null);
  return Map<String, dynamic>.from(completion!['result'] as Map);
}

/// The tap path hops through several platform calls before the verdict screen slides in.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('usisa/sms');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  /// Fake native bridge holding one warned text; [opened] is the notification the app was launched from.
  Future<void> startApp(WidgetTester tester, {String? opened, required List<CheckInput> checks}) async {
    final result = await _backgroundResult();
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'takeNotification':
          final id = opened;
          opened = null;
          return id;
        case 'reviews':
          return [_id];
        case 'review':
          return call.arguments == _id ? {'body': _scam, 'generation': 1, 'result': result} : null;
      }
      return {'supported': true, 'enabled': true, 'smsPermission': true, 'generation': 1};
    });
    final sms = SmsService(nativePlatform: true);
    addTearDown(sms.dispose);
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UsisaApp(
        storage: MemoryStorage(),
        sms: sms,
        runCheck: (input) async {
          checks.add(input);
          return CheckResult(
            text: input.text,
            verdict: Verdict.dangerous,
            reasons: const ['urgency'],
            checkedOnPhone: false,
            destinations: const [],
          );
        },
      ),
    );
    await settle(tester);
  }

  Future<void> openHistory(WidgetTester tester) async {
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('tapping a scam text notification opens Scan a message prefilled and runs the check', (tester) async {
    final checks = <CheckInput>[];
    await startApp(tester, opened: _id, checks: checks);

    expect(find.byType(PasteScreen, skipOffstage: false), findsOneWidget);
    expect(checks.single.text, _scam);
    expect(checks.single.source, CheckSource.sms);
    expect(find.text('Dangerous'), findsWidgets);
  });

  testWidgets('a notification tapped while the app is open opens the same check', (tester) async {
    final checks = <CheckInput>[];
    await startApp(tester, checks: checks);
    expect(checks, isEmpty);

    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(const MethodCall('notification', _id)),
      (_) {},
    );
    await settle(tester);
    expect(checks.single.text, _scam);
    expect(find.text('Dangerous'), findsWidgets);
  });

  testWidgets('a warned text is saved once in History, marked From your texts, even before it is tapped', (
    tester,
  ) async {
    final checks = <CheckInput>[];
    await startApp(tester, checks: checks);
    await openHistory(tester);

    expect(find.text(_scam), findsOneWidget);
    expect(find.text('From your texts'), findsOneWidget);
    expect(checks, isEmpty, reason: 'saving the warning must not run an online check');

    // Tapping the notification afterwards updates that same entry instead of adding another.
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(const MethodCall('notification', _id)),
      (_) {},
    );
    await settle(tester);
    expect(checks.single.text, _scam);
    tester.state<NavigatorState>(find.byType(Navigator).first).popUntil((route) => route.isFirst);
    await settle(tester);
    expect(find.text(_scam), findsOneWidget);
    expect(find.text('From your texts'), findsOneWidget);
  });
}
