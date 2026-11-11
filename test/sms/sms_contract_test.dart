import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/scan/scan_models.dart';
import 'package:usisa/features/sms/sms_background.dart';
import 'package:usisa/features/sms/sms_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('usisa/sms');
  const worker = MethodChannel('usisa/sms_worker');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(worker, null);
  });
  test('refresh checks capabilities without requesting permissions', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return {
        'supported': false,
        'enabled': false,
        'smsPermission': false,
        'notifications': false,
        'generation': 3,
        'degraded': false,
      };
    });
    final service = SmsService(nativePlatform: true);
    await service.refresh();
    expect(service.supported, isFalse);
    expect(service.generation, 3);
    expect(calls, ['status']);
    service.dispose();
  });
  test(
    'explicit enable respects permission failure and disable invalidates state',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => {
          'supported': true,
          'enabled': false,
          'smsPermission': false,
          'notifications': false,
          'generation': 4,
          'degraded': false,
        },
      );
      final service = SmsService(nativePlatform: true);
      await service.setEnabled(true);
      expect(service.enabled, isFalse);
      expect(service.smsPermission, isFalse);
      service.dispose();
    },
  );
  test(
    'missing or expired notification never becomes a fabricated result',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async => null);
      final service = SmsService(nativePlatform: true);
      expect(await service.review('missing'), isNull);
      service.dispose();
    },
  );
  test(
    'background handler uses the same Dart rules and stable SMS event ID',
    () async {
      Map<String, dynamic>? completion;
      messenger.setMockMethodCallHandler(worker, (call) async {
        if (call.method == 'takeEvent') {
          return {
            'id': 'event-123',
            'body': 'GCash: Send your OTP now.',
            'generation': 7,
          };
        }
        if (call.method == 'complete') {
          completion = Map<String, dynamic>.from(call.arguments as Map);
          return true;
        }
        throw StateError('unexpected worker method');
      });
      var networkClients = 0;
      await HttpOverrides.runZoned(
        () async {
          await runSmsBackground(channel: worker);
          await runSmsBackground(channel: worker);
        },
        createHttpClient: (_) {
          networkClients++;
          throw StateError('Background SMS must not upload');
        },
      );
      expect(networkClients, 0);
      expect(completion?['risk'], 'high');
      final result = ScanResult.fromJson(
        Map<String, dynamic>.from(completion!['result'] as Map),
      );
      expect(result.source, ScanSource.sms);
      expect(result.id, 'event-123');
      expect(result.risk, RiskLevel.high);
      expect(result.aiAssessment, isNull);
      expect(
        result.links.every((l) => l.reputation == ReputationState.notRequested),
        isTrue,
      );
    },
  );
  test(
    'unsupported SMS content completes as an error, never low risk',
    () async {
      Map<String, dynamic>? completion;
      messenger.setMockMethodCallHandler(worker, (call) async {
        if (call.method == 'takeEvent') {
          return {'id': 'empty', 'body': '', 'generation': 1};
        }
        completion = Map<String, dynamic>.from(call.arguments as Map);
        return true;
      });
      await runSmsBackground(channel: worker);
      expect(completion?['error'], 'emptyInput');
      expect(completion?['result'], isNull);
    },
  );
}
