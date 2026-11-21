import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:usisa/features/check/check.dart';
import 'package:usisa/features/scan/scan_models.dart';

final screenshot = XFile('scam.png');

Future<CheckResult> checkScreenshot(TextReader reader) =>
    CheckPipeline(readText: reader).run(CheckInput.image(screenshot));

void main() {
  test('a screenshot is read, then its text is checked', () async {
    XFile? read;
    final r = await checkScreenshot((image) async {
      read = image;
      return 'Your account is on hold. Send your OTP at bit.ly/verify-now';
    });
    expect(read, same(screenshot));
    expect(r.verdict, Verdict.dangerous);
    expect(r.reasons.first, 'otp_with_link');
    expect(r.text, 'Your account is on hold. Send your OTP at bit.ly/verify-now');
  });

  test('a screenshot with no text gives no verdict', () async {
    await expectLater(checkScreenshot((_) async => '  \n '), throwsA(isA<ScanException>()));
  });

  test('a failed read gives no verdict', () async {
    await expectLater(
      checkScreenshot((_) async => throw const ScanException('ocrFailed')),
      throwsA(isA<ScanException>()),
    );
  });
}
