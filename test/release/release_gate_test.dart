import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_gate.dart';

void main() {
  test('runs analyze, the tests and the phone-only evaluation, in that order', () async {
    final ran = <String>[];
    final failed = await runGate((command) async {
      ran.add(command.join(' '));
      return 0;
    });
    expect(failed, isEmpty);
    expect(ran, [
      'flutter analyze --no-pub',
      'flutter test --no-pub',
      'flutter test --no-pub tool/evaluate.dart',
    ]);
  });

  test('still runs every step after a miss and names each failed step', () async {
    final ran = <String>[];
    final failed = await runGate((command) async {
      ran.add(command.join(' '));
      return command.contains('tool/evaluate.dart') || command.contains('analyze') ? 1 : 0;
    });
    expect(ran, hasLength(3));
    expect(failed, ['flutter analyze --no-pub', 'flutter test --no-pub tool/evaluate.dart']);
  });
}
