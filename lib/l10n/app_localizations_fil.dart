// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get navCheck => 'Suriin';

  @override
  String get navHistory => 'Kasaysayan';

  @override
  String get navLearn => 'Alamin';

  @override
  String get navSettings => 'Mga setting';

  @override
  String get greetingMorning => 'Magandang umaga!';

  @override
  String get greetingAfternoon => 'Magandang hapon!';

  @override
  String get greetingEvening => 'Magandang gabi!';

  @override
  String get homeHeadline => 'Scam ba ang\ntext na ito?';

  @override
  String get homePrompt => 'Ano ang gusto mong suriin?';

  @override
  String get tileMessageTitle => 'I-scan ang mensahe';

  @override
  String get tileMessageSubtitle => 'I-paste ang natanggap mong text';

  @override
  String get tileLinkTitle => 'Suriin ang link';

  @override
  String get tileLinkSubtitle => 'Alamin kung saan talaga ito papunta';

  @override
  String get tileScreenshotTitle => 'I-scan ang screenshot';

  @override
  String get tileScreenshotSubtitle => 'Pumili ng larawan ng text';

  @override
  String get tileAiTitle => 'AI scan';

  @override
  String get tileAiSubtitle => 'Ipasuri nang mabuti sa AI';

  @override
  String get smsCardTitle => 'Awtomatikong proteksyon sa SMS';

  @override
  String get smsCardOn => 'Susuriin ang mga bagong text';

  @override
  String get smsCardOff => 'Hindi sinusuri ang mga text';

  @override
  String get comingSoon => 'Malapit na';

  @override
  String aiFindingTitle(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'credential_request': 'Humihingi ng lihim na pangseguridad',
      'payment_request': 'Humihingi ng bayad',
      'urgency': 'Minamadali kang kumilos',
      'impersonation': 'Posibleng pagpapanggap',
      'prize': 'Nangangako ng premyo',
      'suspicious_link': 'Kaduda-dudang konteksto ng link',
      'gambling_ad': 'Patalastas ng sugal',
      'other': 'Babalang nakita ng AI',
    });
    return '$_temp0';
  }
}
