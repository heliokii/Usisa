import 'scan_models.dart';

class UrlChecker {
  static const _bareSource =
      r'''(?<![a-z0-9_@.-])(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+(?:[a-z]{2,63}|xn--[a-z0-9-]{2,59})(?![a-z0-9_@-])(?::[0-9]{1,5})?(?:[/?#][^\s<>"']*)?''';
  static final _bare = RegExp(_bareSource, caseSensitive: false);
  static final _candidate = RegExp(
    r'''(?:[a-z][a-z0-9+.-]*://|javascript:|data:|file:)[^\s<>"']*|''' +
        _bareSource,
    caseSensitive: false,
  );
  // Exact host boundaries, never substrings. Review sources before extending this list.
  static const officialDomains = [
    'gcash.com',
    'maya.ph',
    'bdo.com.ph',
    'bpi.com.ph',
    'landbank.com',
    'sss.gov.ph',
    'philhealth.gov.ph',
    'pagibigfund.gov.ph',
  ];
  static const shorteners = [
    'bit.ly',
    'tinyurl.com',
    't.co',
    'shorturl.at',
    'rb.gy',
    'cutt.ly',
  ];

  Uri? parse(String value) {
    try {
      if (RegExp(r'\s').hasMatch(value)) {
        return null;
      }
      final bare = _bare.firstMatch(value);
      final uri = Uri.tryParse(
        bare?.start == 0 && bare?.end == value.length
            ? 'https://$value'
            : value,
      );
      if (uri == null ||
          !['http', 'https'].contains(uri.scheme) ||
          uri.host.isEmpty ||
          uri.host.startsWith('.') ||
          uri.host.endsWith('..') ||
          uri.port < 1 ||
          uri.port > 65535) {
        return null;
      }
      return uri;
    } on FormatException {
      return null;
    }
  }

  List<LinkResult> extract(String text) {
    final results = <LinkResult>[];
    for (final match in _candidate.allMatches(text)) {
      var original = match.group(0)!;
      while (original.isNotEmpty &&
          '.,;!?:)]}'.contains(original[original.length - 1])) {
        if (original.endsWith('://')) {
          break;
        }
        if (original.endsWith(')') &&
            '('.allMatches(original).length >=
                ')'.allMatches(original).length) {
          break;
        }
        original = original.substring(0, original.length - 1);
      }
      if (original.length > 2048) {
        throw const ScanException('urlTooLong');
      }
      final uri = parse(original);
      if (uri != null && uri.toString().length > 2048) {
        throw const ScanException('urlTooLong');
      }
      results.add(
        LinkResult(
          original: original,
          uri: uri,
          findings: uri == null
              ? [Finding('invalidLink', evidence: original)]
              : inspect(uri),
        ),
      );
    }
    if (results.map((l) => l.uri?.toString() ?? l.original).toSet().length >
        10) {
      throw const ScanException('tooManyLinks');
    }
    return results;
  }

  List<Finding> inspect(Uri uri) {
    final findings = <Finding>[];
    final host = uri.host.toLowerCase();
    if (uri.userInfo.isNotEmpty) {
      findings.add(Finding('userInfo', evidence: host));
    }
    if (uri.scheme == 'http') {
      findings.add(Finding('httpLink', evidence: uri.toString()));
    }
    if (RegExp(r'^(?:\d{1,3}\.){3}\d{1,3}$').hasMatch(host) ||
        host.contains(':')) {
      findings.add(Finding('ipHost', evidence: host));
    }
    if (shorteners.contains(host)) {
      findings.add(Finding('shortLink', evidence: host));
    }
    if (host.contains('xn--') || RegExp(r'[^\x00-\x7F]').hasMatch(host)) {
      findings.add(Finding('unusualHost', evidence: host));
    }
    for (final domain in officialDomains) {
      final brand = domain.split('.').first;
      if (host.contains(brand) &&
          host != domain &&
          !host.endsWith('.$domain')) {
        findings.add(Finding('deceptiveHost', evidence: host));
        break;
      }
    }
    return findings;
  }
}
