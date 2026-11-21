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

  @override
  String get pasteHint => 'I-paste dito ang text message';

  @override
  String get checkButton => 'Suriin';

  @override
  String verdictWord(String verdict) {
    String _temp0 = intl.Intl.selectLogic(verdict, {
      'looksSafe': 'Mukhang ligtas',
      'beCareful': 'Mag-ingat',
      'dangerous': 'Delikado',
      'other': 'Hindi masuri',
    });
    return '$_temp0';
  }

  @override
  String verdictAction(String verdict) {
    String _temp0 = intl.Intl.selectLogic(verdict, {
      'looksSafe': 'Walang nakitang kahina-hinala. Pero huwag pa ring ibigay ang OTP o PIN mo kahit kanino.',
      'beCareful': 'Huwag pindutin ang link o magpadala ng pera hangga\'t hindi ka sigurado kung sino ang nagpadala nito.',
      'dangerous':
          'Huwag pindutin ang link, huwag sumagot, at huwag magpadala ng pera.',
      'other': 'Hindi namin ito lubos na masuri. Huwag magbukas ng link o maglagay ng anumang detalye hangga\'t hindi ka sigurado kung sino ang nagpadala.',
    });
    return '$_temp0';
  }

  @override
  String get verdictWhy => 'Bakit';

  @override
  String get checkedOnPhone => 'Sinuri sa iyong phone';

  @override
  String get youChecked => 'Ang sinuri mo';

  @override
  String reason(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'no_signs': 'Wala kaming nakitang babala',
      'otp_with_link':
          'Humihingi ito ng OTP o password mo at may kasamang link',
      'lookalike_domain': 'Nagpapanggap ang link na website ng kilalang brand',
      'prize_claim':
          'Sinasabi nitong nanalo ka ng premyong kailangan mong i-claim',
      'urgency': 'Minamadali ka nitong kumilos',
      'gambling_ad': 'Isa itong hindi hinihinging patalastas ng sugal',
      'flagged_link': 'Nakalista sa Google na hindi ligtas ang link na ito',
      'shortener_blocked': 'Hinarang na ng link shortener ang link na ito',
      'opens_app': 'Nagbubukas ng app ang link sa halip na website',
      'unresolved_link': 'Hindi namin makita kung saan papunta ang link',
      'harmless_promo': 'Mukhang karaniwang promo lang ito',
      'brand_mention':
          'Binabanggit nito ang isang bangko, e-wallet o ahensya ng gobyerno',
      'family_money': 'Humihingi ito ng pera o load, na karaniwan sa pamilya',
      'credential_request': 'Humihingi ito ng password, PIN o code',
      'payment_request': 'Pinapabayad o pinapapadala ka nito ng pera',
      'impersonation': 'Maaaring nagpapanggap ito bilang ibang tao',
      'prize': 'Nangangako ito ng premyo',
      'suspicious_link': 'Kahina-hinala ang link',
      'other': 'May iba pa kaming nakitang babala',
    });
    return '$_temp0';
  }
}
