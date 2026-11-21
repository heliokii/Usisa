import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/check/home_screen.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/sms/sms_background.dart';
import 'package:usisa/features/sms/sms_service.dart';

const _channel = MethodChannel('usisa/sms');
final _messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

/// Fake Android side of the SMS bridge: permissions, the saved on/off wish, the phone maker and warned texts.
class FakeBridge {
  FakeBridge({this.manufacturer = 'Google'});
  String manufacturer;
  bool smsPermission = false;
  bool notifications = false;
  bool wanted = false;

  /// What the permission dialog answers.
  bool grant = true;
  final calls = <String>[];
  final reviews = <String, Map<String, dynamic>>{};

  Map<String, dynamic> status() => {
    'supported': true,
    'enabled': wanted && smsPermission,
    'wanted': wanted,
    'smsPermission': smsPermission,
    'notifications': notifications,
    'manufacturer': manufacturer,
    'generation': 1,
    'checkedToday': 0,
  };

  void install() => _messenger.setMockMethodCallHandler(_channel, (call) async {
    calls.add(call.method);
    switch (call.method) {
      case 'requestPermissions':
        if (grant) smsPermission = notifications = true;
        return null;
      case 'setEnabled':
        wanted = (call.arguments as Map)['enabled'] == true && smsPermission;
      case 'reviews':
        return reviews.keys.toList();
      case 'review':
        return reviews[call.arguments];
      case 'dismiss':
        reviews.remove(call.arguments);
        return null;
      case 'takeNotification':
      case 'openBackgroundSettings':
      case 'openAppSettings':
        return null;
    }
    return status();
  });

  /// Android reports a change, as it does when the app comes back to the front.
  Future<void> changed() => _messenger.handlePlatformMessage(
    _channel.name,
    const StandardMethodCodec().encodeMethodCall(const MethodCall('statusChanged')),
    (_) {},
  );
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
}

Future<void> startApp(WidgetTester tester, FakeBridge bridge, {MemoryStorage? storage}) async {
  bridge.install();
  final sms = SmsService(nativePlatform: true);
  addTearDown(sms.dispose);
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UsisaApp(storage: storage ?? MemoryStorage(), sms: sms));
  await settle(tester);
}

MemoryStorage onboarded() => MemoryStorage()..values['settings'] = jsonEncode({'onboarded': true});

Finder settingsSwitch() =>
    find.descendant(of: find.widgetWithText(SwitchListTile, 'Auto SMS protection'), matching: find.byType(Switch));
Finder homeSwitch() => find.descendant(of: find.byType(HomeScreen), matching: find.byType(Switch));

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await settle(tester);
}

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await settle(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => _messenger.setMockMethodCallHandler(_channel, null));

  testWidgets('one setup step asks for SMS and notifications together and turns protection on', (tester) async {
    final bridge = FakeBridge();
    final storage = MemoryStorage();
    await startApp(tester, bridge, storage: storage);

    expect(find.text('Protect me from scam texts'), findsOneWidget);
    await tapVisible(tester, find.text('Turn on protection'));

    expect(bridge.calls.where((c) => c == 'requestPermissions'), hasLength(1));
    expect(bridge.calls, containsAllInOrder(['requestPermissions', 'setEnabled']));
    // Not a Xiaomi, Oppo, Vivo or Samsung: straight to home, protected.
    expect(find.text('Protect me from scam texts'), findsNothing);
    expect(find.text('Let Usisa keep running'), findsNothing);
    expect(tester.widget<Switch>(homeSwitch()).value, isTrue);
    expect(jsonDecode(storage.values['settings']!)['onboarded'], isTrue);
  });

  testWidgets('Not now skips setup and leaves protection off', (tester) async {
    final bridge = FakeBridge();
    await startApp(tester, bridge);
    await tapVisible(tester, find.text('Not now'));

    expect(bridge.calls, isNot(contains('requestPermissions')));
    expect(find.text('Texts are not being checked'), findsOneWidget);
    expect(find.text('Scam text protection is off'), findsNothing);
  });

  for (final maker in ['Xiaomi', 'OPPO', 'vivo', 'samsung']) {
    testWidgets('on $maker a follow-up step opens the background-running settings', (tester) async {
      final bridge = FakeBridge(manufacturer: maker);
      await startApp(tester, bridge);
      await tapVisible(tester, find.text('Turn on protection'));

      expect(find.text('Let Usisa keep running'), findsOneWidget);
      await tapVisible(tester, find.text('Open settings'));
      expect(bridge.calls, contains('openBackgroundSettings'));
      await tapVisible(tester, find.text('Done'));
      expect(find.text('Let Usisa keep running'), findsNothing);
      expect(tester.widget<Switch>(homeSwitch()).value, isTrue);
    });
  }

  for (final maker in ['Google', 'motorola', 'realme']) {
    testWidgets('on $maker there is no background-running step', (tester) async {
      await startApp(tester, FakeBridge(manufacturer: maker));
      await tapVisible(tester, find.text('Turn on protection'));
      expect(find.text('Let Usisa keep running'), findsNothing);
    });
  }

  testWidgets('the home card and Settings show one switch over the bridge', (tester) async {
    final bridge = FakeBridge();
    await startApp(tester, bridge, storage: onboarded());

    await openTab(tester, 'Settings');
    await tapVisible(tester, settingsSwitch());
    expect(bridge.wanted, isTrue);
    expect(tester.widget<Switch>(settingsSwitch()).value, isTrue);
    await openTab(tester, 'Check');
    expect(tester.widget<Switch>(homeSwitch()).value, isTrue);

    await tapVisible(tester, homeSwitch());
    expect(bridge.wanted, isFalse);
    await openTab(tester, 'Settings');
    expect(tester.widget<Switch>(settingsSwitch()).value, isFalse);
  });

  testWidgets('a revoked permission shows the protection-off banner and Fix asks again', (tester) async {
    final bridge = FakeBridge()
      ..wanted = true
      ..smsPermission = true
      ..notifications = true;
    await startApp(tester, bridge, storage: onboarded());
    expect(find.text('Scam text protection is off'), findsNothing);

    // The person revokes the notification permission in Android settings and comes back.
    bridge.notifications = false;
    await bridge.changed();
    await settle(tester);
    expect(find.text('Scam text protection is off'), findsOneWidget);
    expect(tester.widget<Switch>(homeSwitch()).value, isFalse);

    await tapVisible(tester, find.text('Fix'));
    expect(bridge.calls, contains('requestPermissions'));
    expect(find.text('Scam text protection is off'), findsNothing);
    expect(tester.widget<Switch>(homeSwitch()).value, isTrue);
  });

  testWidgets('Fix opens the app settings when Android no longer shows the permission dialog', (tester) async {
    final bridge = FakeBridge()
      ..wanted = true
      ..grant = false;
    await startApp(tester, bridge, storage: onboarded());

    await tapVisible(tester, find.text('Fix'));
    expect(bridge.calls, containsAllInOrder(['requestPermissions', 'openAppSettings']));
    expect(find.text('Scam text protection is off'), findsOneWidget);
  });

  testWidgets('a warning deleted from History does not come back on the next open', (tester) async {
    const id = '0b6d6e7c-1f0a-4c1e-9d8e-2a3b4c5d6e7f';
    const scam = 'Your GCash account is locked. Verify at http://gcash-verify.example now';
    const worker = MethodChannel('usisa/sms_worker');
    Map<String, dynamic>? done;
    _messenger.setMockMethodCallHandler(worker, (call) async {
      if (call.method == 'takeEvent') return {'id': id, 'body': scam, 'sender': '09171234567'};
      done = Map<String, dynamic>.from(call.arguments as Map);
      return null;
    });
    await runSmsBackground(channel: worker);
    _messenger.setMockMethodCallHandler(worker, null);

    final bridge = FakeBridge()
      ..wanted = true
      ..smsPermission = true
      ..notifications = true;
    bridge.reviews[id] = {'body': scam, 'generation': 1, 'result': done!['result']};
    final storage = onboarded();
    await startApp(tester, bridge, storage: storage);
    await openTab(tester, 'History');
    expect(find.text(scam), findsOneWidget);

    await tapVisible(tester, find.text('Delete'));
    expect(find.text(scam), findsNothing);
    expect(bridge.calls, contains('dismiss'));

    // Next open, same phone.
    await tester.pumpWidget(const SizedBox());
    await startApp(tester, bridge, storage: storage);
    await openTab(tester, 'History');
    expect(find.text(scam), findsNothing);
  });
}
