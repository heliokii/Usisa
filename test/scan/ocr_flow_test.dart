import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/scan/screenshot_review_screen.dart';
import 'package:usisa/features/scan/ocr_models.dart';
import 'package:usisa/l10n/app_localizations.dart';
import 'package:usisa/theme/usisa_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:usisa/features/scan/ocr_service.dart';
import 'package:usisa/features/scan/scan_screen.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/settings/settings_store.dart';

void main() {
  testWidgets('a failed image preview keeps the extracted text editable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: UsisaTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ScreenshotReviewScreen(
          draft: OcrDraft(
            text: 'Readable OCR text',
            bytes: Uint8List.fromList([0, 1, 2, 3]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Image preview is unavailable. You can still review and edit the extracted text.',
      ),
      findsOneWidget,
    );
    expect(find.text('Readable OCR text'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'a picker result delivered after startup is recovered on resume',
    (tester) async {
      final storage = MemoryStorage();
      final ocr = RecoveredOcr()..recovered = null;
      await tester.pumpWidget(
        MaterialApp(
          theme: UsisaTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ScanScreen(
              history: HistoryStore(storage),
              settings: SettingsStore(storage),
              ocr: ocr,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Review previous screenshot'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      ocr.recovered = OcrDraft(text: 'Recovered text', bytes: Uint8List(0));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Review previous screenshot'), findsOneWidget);
      expect(find.text('Scan result'), findsNothing);
      expect(ocr.pickerCalls, 0);
    },
  );
  testWidgets(
    'startup offers recovered screenshot without scanning or choosing another image',
    (tester) async {
      final storage = MemoryStorage();
      final ocr = RecoveredOcr();
      await tester.pumpWidget(
        MaterialApp(
          theme: UsisaTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ScanScreen(
              history: HistoryStore(storage),
              settings: SettingsStore(storage),
              ocr: ocr,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Review previous screenshot'), findsOneWidget);
      expect(ocr.pickerCalls, 0);
      await tester.ensureVisible(find.text('Review previous screenshot'));
      await tester.tap(find.text('Review previous screenshot'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered text'), findsOneWidget);
      expect(find.text('Scan result'), findsNothing);
      expect(ocr.pickerCalls, 0);
    },
  );
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

class RecoveredOcr implements OcrService {
  int pickerCalls = 0;
  OcrDraft? recovered = OcrDraft(text: 'Recovered text', bytes: Uint8List(0));
  @override
  bool get available => true;
  @override
  Future<OcrDraft?> recoverScreenshot() async {
    final value = recovered;
    recovered = null;
    return value;
  }

  @override
  Future<OcrDraft?> readScreenshot() async {
    pickerCalls++;
    return null;
  }

  @override
  Future<OcrDraft> readImage(XFile image) async =>
      OcrDraft(text: 'Recovered text', bytes: Uint8List(0));
}
