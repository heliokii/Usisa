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

  @override
  String get sendToFamily => 'Ipadala sa pamilya';

  @override
  String get readAloud => 'Basahin nang malakas';

  @override
  String get readAloudNoFilipino =>
      'Walang Filipino na boses sa phone na ito, kaya binabasa sa English.';

  @override
  String get readAloudUnavailable =>
      'Hindi magagamit ang Basahin nang malakas sa phone na ito.';

  @override
  String shareIntro(String verdict) {
    return 'Sinuri ko ang isang mensahe gamit ang Usisa. Ang sabi: $verdict';
  }

  @override
  String get settingsDisplay => 'Itsura';

  @override
  String get settingsTextSize => 'Laki ng text';

  @override
  String get textSizeNormal => 'Karaniwan';

  @override
  String get textSizeLarge => 'Malaki';

  @override
  String get textSizeExtraLarge => 'Napakalaki';

  @override
  String get settingsTextSizeNote =>
      'Dagdag ito sa sariling laki ng text ng phone mo.';

  @override
  String get settingsLanguage => 'Wika';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFilipino => 'Filipino';

  @override
  String get settingsProtection => 'Proteksyon';

  @override
  String get settingsOnline => 'Pagsuri online';

  @override
  String get settingsOnlineSwitch =>
      'Suriin online ang mga link at gamitin ang AI';

  @override
  String get settingsOnlineOn =>
      'Ipinapadala ang mga link sa serbisyong pansuri ng Usisa. Ipinapadala ng AI scan ang text ng mensahe sa isang AI service.';

  @override
  String get settingsOnlineOff =>
      'Sa phone mo lang sinusuri ang lahat, kaya baka may scam na hindi mahuli ng Usisa.';

  @override
  String get settingsAbout => 'Tungkol sa Usisa';

  @override
  String get aboutGuide =>
      'Gabay ang Usisa, hindi garantiya. Naghahanap ito ng mga karaniwang senyales ng scam, pero puwede itong magkamali. Kung may kakaiba, huwag mag-click, huwag magbayad at huwag ibigay ang mga code. Magtanong sa taong pinagkakatiwalaan mo.';

  @override
  String get aboutData =>
      'Sa phone na ito lang naka-save ang mga sinuri mo at ang History. Walang ipinapadala kahit saan maliban kung naka-on ang pagsuri online.';

  @override
  String get learnIntro => 'Kilalanin ang mga daya ng scammer sa Pilipinas.';

  @override
  String get learnSourcesNote =>
      'Batay sa pampublikong payo ng BSP, NTC, PNP-ACG, CICC at DICT.';

  @override
  String get learnGoldenTitle => 'Mga gintong tuntunin';

  @override
  String get learnGoldenRules =>
      'Huwag ibigay kaninuman ang OTP, PIN o password mo, kahit sa nagsasabing taga-bangko o taga-gobyerno sila.\nHuwag pindutin ang link sa text na hindi mo inaasahan. Ikaw mismo ang magbukas ng opisyal na app o website.\nTumigil at suriin muna bago magpadala ng pera. Tawagan ang tao o kompanya sa numerong alam mo na.';

  @override
  String get learnSampleLabel => 'Halimbawang pekeng text';

  @override
  String get learnRedFlags => 'Mga babala';

  @override
  String learnMore(String topic) {
    return 'Alamin pa: $topic';
  }

  @override
  String get learnReportTitle => 'Mag-report ng scam';

  @override
  String get learnReportIntro =>
      'Kung tinarget ka o nawalan ka ng pera, i-report ito. I-save ang screenshot ng mga mensahe at ang numero ng nagpadala.';

  @override
  String get learnReportChannels =>
      'CICC hotline 1326|Libre, 24 oras araw-araw. Ang anti-scam hotline ng gobyerno (CICC at DICT).\neGov PH app|Report > Scam > Text Scam, saka i-upload ang mga screenshot.\nAng bangko o e-wallet mo|Tawagan agad ang opisyal na hotline nito kung may pera o account na nadamay. Kung hindi sila kumilos, magreklamo sa BSP Online Buddy (BOB) sa bsp.gov.ph.\nPNP Anti-Cybercrime Group|I-report ang online fraud sa kahit anong police station o sa acg.pnp.gov.ph.\nNTC|Para sa scam text at problema sa SIM, magreklamo sa NTC sa ntc.gov.ph.';

  @override
  String learnTopicTitle(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'phishing': 'Pekeng text mula sa bangko at e-wallet',
      'prize': 'Pekeng premyo at raffle',
      'family': 'Pekeng emergency ng pamilya',
      'aid': 'Pekeng ayuda ng gobyerno',
      'parcel': 'Pekeng bayad sa delivery at parcel',
      'job': 'Pekeng trabaho at online task',
      'investment': 'Scam sa investment at crypto',
      'other': 'Patalastas ng online na sugal',
    });
    return '$_temp0';
  }

  @override
  String learnTopicAbout(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'phishing': 'Mukhang galing sa bangko mo, GCash o Maya ang text: naka-lock daw ang account mo o kailangang i-verify, at may link. Mukhang totoo ang site pero ninanakaw nito ang password at OTP mo. Hindi kailanman humihingi ang bangko o e-wallet ng OTP, PIN o password sa text, tawag o link. Ikaw mismo ang magbukas ng opisyal na app.',
      'prize': '\"Nanalo\" ka raw sa raffle na hindi mo sinalihan, kadalasan may pangalan ng mall, TV show o ahensya ng gobyerno. Para makuha ito, kailangan mo munang magbayad ng \"processing fee\" o ibigay ang detalye mo. Hindi pinagbabayad ng totoong promo ang nanalo, at may permit number mula sa DTI ang totoong raffle na puwede mong suriin.',
      'family': 'May nagpapanggap na anak, apo o kamag-anak mo gamit ang bagong numero, o nagsasabing nurse o pulis sila na tumatawag tungkol sa kanila. May emergency daw, kailangan mong magpadala agad ng pera, at huwag sabihin sa iba. Tawagan muna ang kamag-anak mo sa numerong alam mo na bago magpadala.',
      'aid': 'Sinasabi ng text na kwalipikado ka sa cash aid mula sa DSWD, SSS o PhilHealth, o sa refund, at kailangan mong mag-register sa link o magbayad. Inaanunsyo ang ayuda sa opisyal na website at page, at hindi nagpapadala ang ahensya ng payout link sa text. Magtanong sa opisyal na page o opisina ng ahensya.',
      'parcel': 'Sinasabi ng text o tawag na naka-hold ang parcel mo at kailangan mong magbayad ng maliit na fee o i-update ang address mo sa link. May iba na nagsasabing na-hold sa customs ang package na may pangalan mo. Tingnan ang order sa app mismo ng shop, at huwag magbayad sa link na galing sa text.',
      'job': 'Alok na madaling kita sa bahay sa pag-like ng video, pag-rate ng produkto o paggawa ng \"task\". Maliit at totoo ang unang bayad. Pagkatapos, pinapa-\"deposit\" ka para sa mas malalaking task, at hindi mo na ito mawi-withdraw. Hindi ka pinagbabayad ng totoong employer para magtrabaho.',
      'investment': 'Pangako ng mabilis at siguradong kita, gaya ng pagdoble ng pera mo sa ilang araw, kadalasan sa crypto, forex o \"paluwagan\". Binabayaran ang mga naunang miyembro gamit ang pera ng mga bago hanggang bumagsak ito. Suriin sa SEC kung puwedeng tumanggap ng investment ang kompanya. Babala ang siguradong malaking kita.',
      'other': 'Hindi hinihinging text na nag-aalok ng libreng credit o bonus sa online casino, slots o e-sabong. Marami sa mga site na ito ay ilegal at walang lisensya, at kinukuha ang deposito at personal mong impormasyon. Huwag pindutin ang link o mag-register.',
    });
    return '$_temp0';
  }

  @override
  String learnTopicSample(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'phishing': 'GCash ALERT: Masususpinde ang account mo ngayong araw. Mag-verify sa gcash-verify-ph.xyz at ilagay ang MPIN at OTP mo para hindi mawala ang balance mo.',
      'prize': 'CONGRATULATIONS! Nanalo ka ng P50,000 sa Anniversary Raffle! Para makuha ang premyo, magbayad ng P1,500 processing fee sa numerong ito sa loob ng 24 oras.',
      'family': 'Ma, bagong number ko ito, nawala phone ko. Nasa ospital ako, pa-send ng 5,000 sa GCash na ito ngayon na. Huwag mo munang sabihin kay Papa.',
      'aid': 'DSWD: Kwalipikado ka sa P8,000 ayuda. Mag-register sa dswd-ayuda-claim.online at magbayad ng P200 para ma-release ang payout mo.',
      'parcel': 'Naka-hold ang parcel mo dahil kulang ang address. Magbayad ng P35 re-delivery fee sa ph-parcel-track.top o ibabalik ito ngayong araw.',
      'job': 'Hi! Naghahanap kami ng part-time. Kumita ng P500-P3,000 araw-araw sa pag-like lang ng video. Walang experience na kailangan. Mag-message sa Telegram para magsimula.',
      'investment': 'Siguradong 30% na kita kada linggo! Mag-invest ng P5,000 ngayon at makakuha ng P20,000 sa isang buwan. Limitado ang slot, mag-imbita ng kaibigan para sa bonus.',
      'other': 'LIBRENG P888 bonus para sa bagong player! Maglaro ng slots at e-sabong, withdraw kahit kailan. Mag-register na sa lucky888bet.vip',
    });
    return '$_temp0';
  }

  @override
  String learnTopicFlags(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'phishing': 'Masususpinde ang account mo ngayong araw|Tinatakot ka para hindi ka makapag-isip\ngcash-verify-ph.xyz|Hindi ito ang totoong website ng GCash (gcash.com)\nilagay ang MPIN at OTP mo|Walang totoong bangko o e-wallet na humihingi nito',
      'prize': 'Nanalo ka ng P50,000|Hindi ka mananalo sa raffle na hindi mo sinalihan\nmagbayad ng P1,500 processing fee|Hindi pinagbabayad muna ang totoong premyo\nsa loob ng 24 oras|Deadline para madaliin ka',
      'family': 'bagong number ko ito|Hindi kilalang numero na nagsasabing kapamilya\npa-send ng 5,000 sa GCash na ito ngayon na|Pinipilit kang magpadala agad\nHuwag mo munang sabihin kay Papa|Pinapalihim para hindi mo ito masuri',
      'aid': 'dswd-ayuda-claim.online|Nagtatapos sa .gov.ph ang website ng gobyerno\nmagbayad ng P200 para ma-release|Libre ang ayuda. Walang dapat maningil para matanggap mo ito',
      'parcel': 'Magbayad ng P35 re-delivery fee|Maliit na bayad para makuha ang detalye ng card mo\nph-parcel-track.top|Hindi ito totoong website ng courier o shop\nibabalik ito ngayong araw|Deadline para madaliin ka',
      'job': 'Kumita ng P500-P3,000 araw-araw sa pag-like lang ng video|Sobrang laking bayad sa halos walang trabaho\nMag-message sa Telegram|Inililipat ka sa pribadong chat na mahirap matunton',
      'investment': 'Siguradong 30% na kita kada linggo|Walang totoong investment na sigurado ang malaking kita\nLimitado ang slot|Minamadali kang sumali bago ka makapag-isip\nmag-imbita ng kaibigan para sa bonus|Senyales ng pyramid scheme ang pagbabayad sa pag-recruit',
      'other': 'LIBRENG P888 bonus|Libreng credit para akitin kang mag-deposit\nlucky888bet.vip|Hindi kilalang sugalan na maaaring walang lisensya',
    });
    return '$_temp0';
  }
}
