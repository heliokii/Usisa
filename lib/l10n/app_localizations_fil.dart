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
  String get screenshotIntro =>
      'Pumili ng screenshot ng mensahe. Babasahin namin ang text para sa iyo.';

  @override
  String get screenshotChoose => 'Pumili ng screenshot';

  @override
  String get screenshotReview =>
      'Tingnan ang text na nabasa namin at ayusin ang anumang mali.';

  @override
  String get screenshotNoText =>
      'Wala kaming mabasang text sa larawang ito. Subukan ang mas malinaw na screenshot.';

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
      'credential_request': 'Humihingi ito ng password, PIN o code',
      'payment_request': 'Pinapabayad o pinapapadala ka nito ng pera',
      'impersonation': 'Maaaring nagpapanggap ito bilang ibang tao',
      'prize': 'Nangangako ito ng premyo',
      'suspicious_link': 'Kahina-hinala ang link',
      'other': 'May iba pa kaming nakitang babala',
    });
    return '$_temp0';
  }

  @override
  String get linkHint => 'I-paste dito ang link';

  @override
  String reallyGoesTo(String destination) {
    return 'Talagang pupunta sa $destination';
  }

  @override
  String get consentTitle => 'Suriin online ang mga link?';

  @override
  String get consentBody =>
      'Para makita kung saan talaga pupunta ang link at kung tinatawag itong delikado ng Google, ipapadala ng Usisa ang link sa serbisyo nitong pansuri. Kung gagamit ka ng AI scan, ipapadala rin ang text ng mensahe sa isang AI service.';

  @override
  String get consentDecline =>
      'Kung hindi, sa phone mo lang susuriin ng Usisa ang lahat. Hindi nito makikita kung saan talaga pupunta ang mga link, kaya baka may scam itong hindi mahuli.';

  @override
  String get consentLater => 'Puwede mo itong baguhin mamaya sa Settings.';

  @override
  String get consentAllow => 'Oo, suriin online';

  @override
  String get consentDeny => 'Hindi, sa phone lang';

  @override
  String get historySavedOnPhone => 'Sa phone na ito lang naka-save';

  @override
  String get historySaveSwitch => 'I-save ang mga check ko';

  @override
  String get historySaveNote =>
      'Kapag pinatay ito, mabubura rin ang History mo.';

  @override
  String get historyEmpty => 'Wala pang naka-save na check.';

  @override
  String get historyOff => 'Naka-off ang pag-save.';

  @override
  String get historyClearAll => 'Burahin lahat';

  @override
  String get historyClearTitle => 'Burahin ang buong History?';

  @override
  String get historyClearBody =>
      'Mabubura ang lahat ng naka-save na check sa phone na ito. Hindi na ito maibabalik.';

  @override
  String get historyDelete => 'Burahin';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get fromYourTexts => 'Mula sa iyong mga text';

  @override
  String checkedOnDate(String date) {
    return 'Sinuri noong $date';
  }

  @override
  String get checkAgain => 'Suriin muli';

  @override
  String get aiScanIntro => 'Ano ang gusto mong tingnan ng AI?';

  @override
  String get aiScanMessage => 'Isang mensahe';

  @override
  String get aiScanLink => 'Isang link';

  @override
  String get aiScanScreenshot => 'Isang screenshot';

  @override
  String get aiUnavailable => 'Hindi ito natingnan ng AI ngayon';
}
