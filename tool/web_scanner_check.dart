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
  final bare = analyzer.analyze(
    const ScanInput('bit.ly/example', source: ScanSource.sms),
  );
  if (result.risk != RiskLevel.high ||
      benign.risk != RiskLevel.low ||
      result.id == benign.id ||
      bare.risk != RiskLevel.caution ||
      bare.links.single.uri.toString() != 'https://bit.ly/example') {
    throw StateError(
      'JavaScript target must produce distinct IDs and correct scam/benign results.',
    );
  }
}
