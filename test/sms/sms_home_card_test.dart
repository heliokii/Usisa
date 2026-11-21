import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/sms/sms_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('usisa/sms');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  testWidgets('home card turns protection on through the SMS bridge and shows the daily count as texts arrive', (
    tester,
  ) async {
    // Fake native bridge: protection off until enabled, then texts get checked in the background.
    var enabled = false;
    var checked = 0;
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'setEnabled') enabled = (call.arguments as Map)['enabled'] as bool;
      return {
        'supported': true,
        'enabled': enabled,
        'wanted': enabled,
        'smsPermission': enabled,
        'notifications': enabled,
        'generation': 1,
        'checkedToday': checked,
      };
    });
    final sms = SmsService(nativePlatform: true);
    addTearDown(sms.dispose);

    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UsisaApp(storage: _onboarded(), sms: sms));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Texts are not being checked'), findsOneWidget);
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump();
    expect(calls, containsAllInOrder(['requestPermissions', 'setEnabled']));
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text('0 texts checked today'), findsOneWidget);

    // The background worker finished a check and Android tells the app its state changed.
    checked = 12;
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(const MethodCall('statusChanged')),
      (_) {},
    );
    await tester.pump();
    expect(find.text('12 texts checked today'), findsOneWidget);
  });

  testWidgets('a refused permission leaves the card off', (tester) async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => {'supported': true, 'enabled': false, 'smsPermission': false, 'generation': 1},
    );
    final sms = SmsService(nativePlatform: true);
    addTearDown(sms.dispose);
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UsisaApp(storage: _onboarded(), sms: sms));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('Texts are not being checked'), findsOneWidget);
  });
}

/// Past first-run setup, so home shows straight away.
MemoryStorage _onboarded() => MemoryStorage()..values['settings'] = jsonEncode({'onboarded': true});
