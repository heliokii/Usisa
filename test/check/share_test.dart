import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/check/check.dart';
import 'package:usisa/features/check/share_source.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/scan/scan_models.dart';

/// Opens the app with a fake share intent source and delivers [item] as if shared from another app.
Future<StreamController<SharedItem>> share(
  WidgetTester tester,
  SharedItem item, {
  required List<CheckInput> checks,
  Future<String> Function(String path)? readImage,
}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final shares = StreamController<SharedItem>();
  addTearDown(shares.close);
  await tester.pumpWidget(
    UsisaApp(
      storage: MemoryStorage(),
      shares: shares.stream,
      readSharedImage: readImage ?? (_) async => throw StateError('no image expected'),
      readScreenshot: () async => throw StateError('the picker should not open'),
      runCheck: (input) async {
        checks.add(input);
        return CheckResult(
          text: input.text,
          verdict: Verdict.looksSafe,
          reasons: const ['no_signs'],
          checkedOnPhone: true,
        );
      },
    ),
  );
  await tester.pump();
  shares.add(item);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1)); // A shared image is read, then replaced by the review.
  return shares;
}

void main() {
  testWidgets('shared text opens Scan a message filled in, unchecked', (tester) async {
    final checks = <CheckInput>[];
    await share(tester, const SharedItem.text('Hi Ma, pa-send ng pera sa GCash ngayon na'), checks: checks);

    expect(find.text('Scan a message'), findsOneWidget);
    expect(find.text('Hi Ma, pa-send ng pera sa GCash ngayon na'), findsOneWidget);
    expect(checks, isEmpty);

    await tester.tap(find.textContaining(RegExp(r'^Check (message|link|screenshot)$')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(checks.single.text, 'Hi Ma, pa-send ng pera sa GCash ngayon na');
    expect(checks.single.source, CheckSource.share);
  });

  testWidgets('a shared bare link opens Check a link filled in, unchecked', (tester) async {
    final checks = <CheckInput>[];
    await share(tester, const SharedItem.text('  https://bit.ly/verify-now \n'), checks: checks);

    expect(find.text('Check a link'), findsWidgets);
    expect(find.text('https://bit.ly/verify-now'), findsOneWidget);
    expect(checks, isEmpty);
  });

  testWidgets('text with a link inside is a message, not a link', (tester) async {
    final checks = <CheckInput>[];
    await share(tester, const SharedItem.text('Claim your prize at bit.ly/x'), checks: checks);
    expect(find.text('Scan a message'), findsOneWidget);
  });

  testWidgets('a shared image opens Scan a screenshot with the read text, unchecked', (tester) async {
    final checks = <CheckInput>[];
    String? readPath;
    await share(
      tester,
      const SharedItem.image('/cache/shared/abc.png'),
      checks: checks,
      readImage: (path) async {
        readPath = path;
        return 'Your account is on hold. Send your OTP';
      },
    );

    expect(readPath, '/cache/shared/abc.png');
    expect(find.text('Scan a screenshot'), findsWidgets);
    expect(find.text('Check the text we read and fix any mistakes.'), findsOneWidget);
    expect(find.text('Your account is on hold. Send your OTP'), findsOneWidget);
    expect(checks, isEmpty);
  });

  testWidgets('a shared image with no readable text stays on Scan a screenshot', (tester) async {
    final checks = <CheckInput>[];
    await share(
      tester,
      const SharedItem.image('/cache/shared/abc.png'),
      checks: checks,
      readImage: (_) async => throw const ScanException('ocrFailed'),
    );
    expect(find.text("We couldn't read any text in this picture. Try a clearer screenshot."), findsOneWidget);
    expect(checks, isEmpty);
  });
}
