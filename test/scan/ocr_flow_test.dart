import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/scan/screenshot_review_screen.dart';
import 'package:usisa/features/scan/ocr_models.dart';
import 'package:usisa/l10n/app_localizations.dart';
import 'package:usisa/theme/usisa_theme.dart';

void main() {
  testWidgets(
    'OCR text stays editable and is not submitted before confirmation',
    (tester) async {
      String? reviewed;
      await tester.pumpWidget(
        MaterialApp(
          theme: UsisaTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  reviewed = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => ScreenshotReviewScreen(
                        draft: OcrDraft(
                          text: 'Misread text',
                          bytes: Uint8List(0),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(reviewed, isNull);
      await tester.enterText(find.byType(TextField), 'Corrected message');
      await tester.ensureVisible(find.text('Check this text'));
      await tester.tap(find.text('Check this text'));
      await tester.pumpAndSettle();
      expect(reviewed, 'Corrected message');
    },
  );
}
