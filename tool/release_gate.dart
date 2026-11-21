// Release gate (#44): analyze, every test, and the phone-only Quality bar evaluation on the sealed split.
// Exits non-zero if any step fails. Every step runs even after a miss, so one run shows everything that blocks the release.
//
//   dart run tool/release_gate.dart
import 'dart:io';

const steps = [
  ['flutter', 'analyze', '--no-pub'],
  ['flutter', 'test', '--no-pub'],
  ['flutter', 'test', '--no-pub', 'tool/evaluate.dart'],
];

/// Runs every step and returns the ones that failed.
Future<List<String>> runGate(Future<int> Function(List<String> command) run) async {
  final failed = <String>[];
  for (final command in steps) {
    if (await run(command) != 0) failed.add(command.join(' '));
  }
  return failed;
}

Future<int> _run(List<String> command) async {
  stdout.writeln('\n==> ${command.join(' ')}');
  // runInShell: flutter is flutter.bat on Windows.
  final process = await Process.start(command.first, command.sublist(1), runInShell: true, mode: ProcessStartMode.inheritStdio);
  return process.exitCode;
}

Future<void> main() async {
  final failed = await runGate(_run);
  if (failed.isEmpty) {
    stdout.writeln('\nRelease gate passed.');
    return;
  }
  stderr.writeln('\nRelease gate FAILED. Blocking steps:\n${failed.map((s) => '  - $s').join('\n')}');
  exitCode = 1;
}
