import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'features/history/history_store.dart';
import 'features/sms/sms_background.dart';

@pragma('vm:entry-point')
Future<void> usisaSmsBackground() => runSmsBackground();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    UsisaApp(
      storage: kIsWeb ? MemoryStorage() : const SecureStorage(),
      isPreview: kIsWeb,
    ),
  );
}
