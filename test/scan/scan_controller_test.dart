import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/scan/scan_controller.dart';
import 'package:usisa/features/scan/scan_models.dart';

void main() {
  test('cancellation discards delayed work and keeps the input', () async {
    final wait = Completer<void>();
    final controller = ScanController(beforeAnalyze: () => wait.future);
    final work = controller.check(const ScanInput('Send your OTP now. GCash'));
    expect(controller.busy, isTrue);
    controller.cancel();
    wait.complete();
    await work;
    expect(controller.result, isNull);
    expect(controller.input.text, 'Send your OTP now. GCash');
    expect(controller.busy, isFalse);
  });
  test(
    'double submission produces only one result and errors preserve text',
    () async {
      final wait = Completer<void>();
      final controller = ScanController(beforeAnalyze: () => wait.future);
      final first = controller.check(const ScanInput('hello'));
      final second = controller.check(const ScanInput('second'));
      wait.complete();
      await Future.wait([first, second]);
      expect(controller.result?.text, 'hello');
      await controller.check(const ScanInput(' '));
      expect(controller.error, 'emptyInput');
      expect(controller.result, isNull);
      expect(controller.input.text, ' ');
    },
  );
}
