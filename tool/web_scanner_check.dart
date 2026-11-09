import 'package:usisa/features/scan/scam_analyzer.dart';
import 'package:usisa/features/scan/scan_models.dart';

void main() {
  final analyzer = ScamAnalyzer();
  final result = analyzer.analyze(
    const ScanInput(
      'GCash: Send your OTP now or your account will be suspended. https://gcash.com.evil.test',
    ),
  );
  final benign = analyzer.analyze(
    const ScanInput('Your OTP is 123456. Never share your OTP.'),
  );
  if (result.risk != RiskLevel.high ||
      benign.risk != RiskLevel.low ||
      result.id == benign.id) {
    throw StateError(
      'JavaScript target must produce distinct IDs and correct scam/benign results.',
    );
  }
}
