import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'features/history/history_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    UsisaApp(
      storage: kIsWeb ? MemoryStorage() : const SecureStorage(),
      isPreview: kIsWeb,
    ),
  );
}
