import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/settings/settings_screen.dart';
import 'package:usisa/features/settings/settings_store.dart';
import 'package:usisa/features/sms/sms_service.dart';
import 'package:usisa/l10n/app_localizations.dart';
import 'package:usisa/theme/usisa_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'SMS permission is requested only after the user confirms disclosure',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var permissionRequests = 0;
      const channel = MethodChannel('usisa/sms');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'requestPermissions') {
          permissionRequests++;
          return null;
        }
        return {
          'supported': true,
          'enabled': false,
          'smsPermission': false,
          'notifications': false,
          'generation': 0,
          'pending': 0,
          'degraded': false,
        };
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final storage = MemoryStorage();
      final service = SmsService(nativePlatform: true);
      addTearDown(service.dispose);
      await service.refresh();
      await tester.pumpWidget(
        MaterialApp(
          theme: UsisaTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            settings: SettingsStore(storage),
            history: HistoryStore(storage),
            sms: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(permissionRequests, 0);
      await tester.ensureVisible(find.text('Auto SMS Detection'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Auto SMS Detection'));
      await tester.pumpAndSettle();
      expect(find.text('Enable incoming SMS checks?'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(SingleChildScrollView),
        ),
        findsWidgets,
      );
      expect(permissionRequests, 0);
      await tester.tap(find.text('Enable SMS checks'));
      await tester.pumpAndSettle();
      expect(permissionRequests, 1);
      expect(find.text('SMS permission needed'), findsOneWidget);
    },
  );
}
