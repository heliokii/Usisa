// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get deletedScan => 'Nabura ang naka-save na pagsusuri';

  @override
  String get learnOtpTitle => 'Paghingi ng OTP at password';

  @override
  String get learnOtpBody =>
      'Mag-ingat sa paghingi ng code kahit magpakilalang support ang nagpadala. Maaaring sabihin ng lehitimong OTP reminder na huwag ibahagi ang code. Tiyakin sa opisyal na app na ikaw mismo ang nagbukas.';

  @override
  String get learnBankTitle => 'Pekeng babala ng bangko at e-wallet';

  @override
  String get learnBankBody =>
      'Maaaring gamitin ang banta sa account para madaliin kang pumindot ng link. Maaaring peke ang pangalan ng nagpadala. Buksan mismo ang app ng bangko o e-wallet upang tiyakin ang account.';

  @override
  String get learnGovernmentTitle => 'Pagpapanggap na ahensiya ng gobyerno';

  @override
  String get learnGovernmentBody =>
      'Maaaring magpakilalang SSS, PhilHealth, Pag-IBIG o ibang ahensiya ang mensahe. Tiyakin ang di-inaasahang ayuda, multa o pagpaparehistro sa opisyal na serbisyo. Hindi patunay ang logo o pangalan.';

  @override
  String get learnDeliveryTitle => 'Di-inaasahang bayad sa delivery';

  @override
  String get learnDeliveryBody =>
      'Maaaring humingi ng detalye ng card o account ang pekeng bayad sa muling delivery. Tingnan ang order sa shopping o courier app. Itinatago ng pinaikling link ang destinasyon; hindi ito pinalalawak ng Usisa.';

  @override
  String get learnSellerTitle => 'Pagbabayad sa online seller';

  @override
  String get learnSellerBody =>
      'Mag-ingat kung pinipilit kang lumipat sa labas ng karaniwang proseso ng marketplace. Tiyakin ang seller, produkto, tatanggap at dahilan ng bayad sa mapagkakatiwalaang rekord bago magpadala.';

  @override
  String get learnRecoveryTitle => 'Kung nakapagbahagi ka na ng detalye';

  @override
  String get learnRecoveryBody =>
      'Itigil muna ang pagbabayad at makipag-ugnayan sa bangko o e-wallet sa opisyal na app o pinagkakatiwalaang contact sa sariling rekord. Palitan ang apektadong password sa tunay na serbisyo. Itago nang pribado ang ebidensiya. Huwag magbigay ng panibagong OTP sa nangangakong tutulong.';

  @override
  String selectedCount(int count) {
    return '$count ang napili';
  }

  @override
  String resultCount(int count) {
    return '$count resulta';
  }

  @override
  String get scan => 'Suriin';

  @override
  String get history => 'Kasaysayan';

  @override
  String get learn => 'Alamin';

  @override
  String get settings => 'Mga setting';

  @override
  String get scanHeading => 'Suriin bago pindutin.';

  @override
  String get scanIntro =>
      'Sandaling pagsusuri bago magtiwala. Suriin ang mensahe o link bago kumilos.';

  @override
  String get localPrivate => 'Sa iyong device. Pribado bilang default.';

  @override
  String get message => 'Mensahe';

  @override
  String get link => 'Link';

  @override
  String get screenshot => 'Screenshot';

  @override
  String get inputHint => 'I-paste o i-type ang mensahe rito…';

  @override
  String get pasteText => 'I-paste ang teksto';

  @override
  String get pasteLink => 'I-paste ang link';

  @override
  String get clear => 'Burahin';

  @override
  String get checkMessage => 'Suriin ang mensahe';

  @override
  String get checkLink => 'Suriin ang link';

  @override
  String get checking => 'Sinusuri ang mga babala…';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get chooseScreenshot => 'Pumili ng screenshot';

  @override
  String get screenshotIntro =>
      'Pumili ng larawan ng mensahe. Suriin muna ang nakuhang teksto.';

  @override
  String get ocrNativeOnly =>
      'Ang OCR ay para sa Android at iOS app. Maaari kang mag-paste ng teksto rito.';

  @override
  String get readingImage => 'Binabasa ang screenshot…';

  @override
  String get reviewText => 'Suriin ang nakuhang teksto';

  @override
  String get ocrNotice =>
      'Maaaring magkamali ang pagbasa. Suriin ang mga pangalan, numero, at link.';

  @override
  String get checkThisText => 'Suriin ang tekstong ito';

  @override
  String get noOcrText =>
      'Walang nabasang teksto. Pumili ng ibang larawan o i-type ang mensahe.';

  @override
  String get smsOff => 'Hindi magagamit ang awtomatikong SMS sa bersyong ito';

  @override
  String get smsDetail =>
      'Hindi kailangan ng SMS access para sa manwal na pagsusuri. Kailangan ng angkop na Android build para sa awtomatikong pagsusuri.';

  @override
  String get reminderTitle => 'Huwag ibahagi ang iyong OTP.';

  @override
  String get reminderBody =>
      'Tiyakin ang kahilingan sa opisyal na app o sa contact na pinagkakatiwalaan mo.';

  @override
  String get result => 'Resulta ng pagsusuri';

  @override
  String get newScan => 'Suriin ang ibang mensahe';

  @override
  String get whyFlagged => 'Bakit ito na-flag';

  @override
  String get linksInMessage => 'Mga link sa mensahe';

  @override
  String get nextSteps => 'Ano ang maaari mong gawin';

  @override
  String get originalText => 'Orihinal na mensahe';

  @override
  String get localChecked => 'Nasuri ang mga babala sa device na ito';

  @override
  String get unknownLink => 'Hindi pa tiyak ang kaligtasan ng link.';

  @override
  String get lowCopy =>
      'Walang karaniwang babalang nakita. Hindi nito tinitiyak kung sino ang nagpadala.';

  @override
  String get cautionCopy =>
      'May mga detalyeng dapat siyasatin. Tiyakin ang kahilingan bago sumagot o magbayad.';

  @override
  String get highCopy =>
      'May matitinding babala sa mensaheng ito. Huminto muna bago magbigay ng impormasyon o pera.';

  @override
  String get noWarnings => 'Walang karaniwang babalang nakita';

  @override
  String get notChecked => 'Hindi pa nasuri online';

  @override
  String get notListed =>
      'Wala sa listahan ng banta; hindi ito patunay na ligtas';

  @override
  String get linkUnavailable =>
      'Hindi magagamit ang online na pagsusuri. Subukan muli mamaya.';

  @override
  String get knownThreat => 'Nakalista bilang posibleng banta';

  @override
  String get fullLink => 'Buong link';

  @override
  String get checkOnline => 'Suriin ang mga link online';

  @override
  String get checkingLinks => 'Sinusuri ang mga link…';

  @override
  String get retry => 'Subukan muli';

  @override
  String get verifyAdvice =>
      'Tiyakin sa opisyal na app o website na ikaw mismo ang nagbukas.';

  @override
  String get secretAdvice =>
      'Huwag magbahagi ng OTP, password, PIN, o recovery code.';

  @override
  String get paymentAdvice =>
      'Ipagpaliban ang pagbabayad. Tiyakin ang tatanggap sa mapagkakatiwalaang paraan.';

  @override
  String get clickedAdvice =>
      'Nakapagbahagi na? Makipag-ugnayan agad sa bangko o e-wallet sa opisyal nitong app.';

  @override
  String get historyHeading => 'Pribado ang iyong mga pagsusuri.';

  @override
  String get historyOff => 'Naka-off ang kasaysayan';

  @override
  String get historyOffBody =>
      'Mananatili lang ang mga mensahe sa session. I-enable ang encrypted na kasaysayan para sa pinakahuling 100 pagsusuri; nag-e-expire ang access matapos ang 30 araw.';

  @override
  String get enableHistory => 'I-enable ang pribadong kasaysayan';

  @override
  String get noHistory => 'Wala pang pagsusuri';

  @override
  String get noHistoryBody =>
      'Lalabas dito ang naka-save na pagsusuri. Magsimula sa mensaheng nais mong tiyakin.';

  @override
  String get noMatches => 'Walang katugmang pagsusuri';

  @override
  String get clearFilters => 'Alisin ang mga filter';

  @override
  String get searchHistory => 'Hanapin sa naka-save na mensahe';

  @override
  String get filters => 'Mga filter';

  @override
  String get allRisk => 'Lahat ng antas';

  @override
  String get allSources => 'Lahat ng pinagmulan';

  @override
  String get allDates => 'Lahat ng petsa';

  @override
  String get last7 => 'Nakaraang 7 araw';

  @override
  String get last30 => 'Nakaraang 30 araw';

  @override
  String get select => 'Pumili';

  @override
  String get selectAll => 'Piliin ang lahat ng tugma';

  @override
  String get deleteSelected => 'Burahin ang napili';

  @override
  String get delete => 'Burahin';

  @override
  String get undo => 'Ibalik';

  @override
  String get deleteTitle => 'Burahin ang mga naka-save na pagsusuri?';

  @override
  String get deleteBody =>
      'Buburahin lang nito ang pagsusuri sa Usisa. Hindi nito buburahin ang mensahe sa SMS app.';

  @override
  String get clearSavedData => 'Burahin ang naka-save na datos';

  @override
  String get notSaved =>
      'Hindi na-save. Makikita pa rin ang resulta sa session na ito.';

  @override
  String get saveFailed => 'Hindi ma-save ang pagbabago. Subukan muli.';

  @override
  String get learnHeading => 'Kilalanin ang babala. Mag-ingat.';

  @override
  String get learnIntro =>
      'Mga praktikal na paalala para sa araw-araw na mensahe sa Pilipinas.';

  @override
  String get privacy => 'Pagkapribado at imbakan';

  @override
  String get appearance => 'Hitsura';

  @override
  String get systemTheme => 'Sundin ang device';

  @override
  String get lightTheme => 'Maliwanag';

  @override
  String get darkTheme => 'Madilim';

  @override
  String get language => 'Wika';

  @override
  String get saveHistory => 'I-save ang pribadong kasaysayan';

  @override
  String get restoreDraft => 'Ibalik ang aking draft';

  @override
  String get draftDetail =>
      'Ibalik ang isang encrypted na draft sa loob ng 24 oras. Binubura ang nag-expire na file habang bukas ang Usisa o sa susunod na paggamit; hindi ito magagawa sa takdang oras kung sarado o naka-stop ang app. Hindi sine-save ang screenshot.';

  @override
  String get onlineChecks => 'Online na pagsusuri ng link';

  @override
  String get onlineDisclosure => 'I-enable ang online na pagsusuri ng link?';

  @override
  String get onlineBody =>
      'Ipapadala ang buong URL, kasama ang path at query, sa Usisa gateway at Google Web Risk para sa pagsusuring ito at susunod na manwal na pagsusuri hanggang i-off. Mananatili sa device ang teksto, nagpadala, at larawan. Walang URL na ia-upload sa awtomatikong SMS.';

  @override
  String get enableOnline => 'I-enable ang online na pagsusuri';

  @override
  String get localOnly => 'Sa device lamang';

  @override
  String get gatewayMissing =>
      'Hindi pa naka-configure ang online na pagsusuri sa build na ito. Gumagana pa rin ang lokal na pagsusuri.';

  @override
  String get about => 'Tungkol sa Usisa';

  @override
  String get aboutBody =>
      'Para sa mga mensahe sa Pilipinas. Tinutukoy ng Usisa ang posibleng babala ng scam; hindi nito magagarantiya ang pagtukoy o matitiyak ang bawat nagpadala.';

  @override
  String get sessionPreview =>
      'Browser preview: sa session lang ang imbakan. Kailangan ng Android para sa native OCR at papasok na SMS.';

  @override
  String get privateHistoryConsent =>
      'Mag-save ng encrypted na teksto, link, at resulta sa device (pinakahuling 100). Nag-e-expire ang access matapos ang 30 araw. Binubura ang nag-expire na file habang bukas ang Usisa o sa susunod na paggamit; hindi ito magagawa sa takdang oras kung sarado o naka-stop ang app. Binubura agad ng Burahin ang naka-save na datos kapag gumagana ang storage.';

  @override
  String get assumedHttps =>
      'Ipinagpalagay ang HTTPS dahil walang scheme ang link. Walang pahinang binuksan.';

  @override
  String get reputationExpired =>
      'Hindi na kasalukuyan ang dating online na resulta. Suriin muli.';

  @override
  String get previousThreat => 'Dating nakalista bilang banta.';

  @override
  String checkedAtLabel(String date) {
    return 'Huling sinuri: $date';
  }

  @override
  String get retentionCleanupFailed =>
      'May nag-expire na datos na hindi nabura. Subukan ang Burahin ang naka-save na datos sa Settings.';

  @override
  String get welcomeTitle => 'Suriin muna bago kumilos.';

  @override
  String get welcomeBody =>
      'Tingnan ang mga babala sa kahina-hinalang mensahe at link. Para sa mga mensaheng English, Filipino, at Taglish sa Pilipinas.';

  @override
  String get welcomePrivacy =>
      'Gumagana offline ang manwal na pagsuri. Naka-off muna at opsyonal ang history, online na pagsuri ng link, at papasok na SMS. Maaaring may scam na hindi matukoy; kumpirmahin ang mahahalagang hiling sa hiwalay na opisyal na paraan.';

  @override
  String get startChecking => 'Simulang magsuri';

  @override
  String get smsHeading => 'Pagsuri ng papasok na SMS';

  @override
  String get smsDisclosure => 'I-enable ang pagsuri ng SMS?';

  @override
  String get smsDisclosureBody =>
      'Binabasa lang ng Usisa ang bagong SMS habang naka-enable ito. Lokal ang pagsuri: walang pag-upload, pagbasa ng inbox, o pag-access sa ibang app. Hanggang 20 naka-encrypt na pagsusuri ang nag-e-expire matapos ang 15 minuto; maaaring maantala ng Android ang pagbura. Maaaring maantala o ihinto ng Android ang pagsuri; hindi gagana kapag naka-force stop ang Usisa. Maaaring may scam na hindi matukoy.';

  @override
  String get enableSmsChecks => 'I-enable ang pagsuri ng SMS';

  @override
  String get smsPermissionNeeded => 'Kailangan ng pahintulot sa SMS';

  @override
  String get smsEnabled => 'Naka-enable ang pagsuri ng SMS';

  @override
  String get smsDisabled => 'Naka-off ang pagsuri ng SMS';

  @override
  String get smsLimits =>
      'Lokal na pagsuri lang. Maaaring maantala ng Android; hindi garantisado ang saklaw. Walang alerto para sa mababang panganib.';

  @override
  String get smsAlertsOff =>
      'Naka-off ang mga notification. Buksan dito ang kamakailang SMS. Maaari ring i-enable sa Android app settings.';

  @override
  String get enableSmsAlerts => 'I-enable ang mga notification';

  @override
  String get smsDegraded =>
      'May mga mensaheng hindi nasuri. Hindi kumpleto ang saklaw. Subukang i-off at i-on muli ang pagsuri ng SMS.';

  @override
  String get manageSms => 'Pamahalaan ang pagsuri ng SMS';

  @override
  String get recentSms => 'Kamakailang SMS';

  @override
  String get smsTemporary =>
      'Naka-encrypt ang pansamantalang kopya at nawawala 15 minuto mula sa pagtanggap. Binubura ang mababang panganib pagkatapos suriin.';

  @override
  String get smsEmpty =>
      'Walang pansamantalang SMS. Maaaring nag-expire, mababa ang panganib, o hindi natanggap habang naka-enable ang pagsuri.';

  @override
  String get smsMissing =>
      'Hindi magagamit ang pagsusuring ito. Maaaring nag-expire, nabura, o naka-off ang pagsuri. Kopyahin ang mensahe sa Text para suriin muli.';

  @override
  String get smsPending =>
      'Wala pang natapos na pagsusuri. Subukan mamaya o kopyahin sa Text para sa manwal na pagsuri.';

  @override
  String get continueAction => 'Magpatuloy';

  @override
  String get back => 'Bumalik';

  @override
  String riskLabel(String risk) {
    String _temp0 = intl.Intl.selectLogic(risk, {
      'high': 'Mataas na panganib',
      'caution': 'Mag-ingat',
      'other': 'Mababang panganib',
    });
    return '$_temp0';
  }

  @override
  String sourceLabel(String source) {
    String _temp0 = intl.Intl.selectLogic(source, {
      'link': 'Link',
      'screenshot': 'Screenshot',
      'sms': 'SMS',
      'other': 'Teksto',
    });
    return '$_temp0';
  }

  @override
  String errorMessage(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'emptyInput': 'Maglagay muna ng mensahe o link.',
      'textTooLong': 'Hanggang 10,000 character. Walang pinutol.',
      'invalidUrl': 'Maglagay ng isang kumpletong HTTP o HTTPS link. Gamitin ang Teksto para sa maraming link.',
      'urlTooLong': 'Lampas 2,048 character ang link. I-edit muna.',
      'tooManyLinks': 'Hanggang 10 magkakaibang link bawat pagsusuri.',
      'imageTooLarge':
          'Pumili ng larawang mas maliit sa 20 MB at 20 megapixel.',
      'other': 'Hindi natapos. Nandito pa ang teksto. Subukan muli.',
    });
    return '$_temp0';
  }

  @override
  String findingTitle(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'codeRequest': 'Humihingi ng lihim na code',
      'paymentRequest': 'Humihingi ng bayad',
      'urgency': 'Minamadali ka',
      'prize': 'Nangangako ng premyo',
      'advanceFee': 'Humihingi ng paunang bayad',
      'deceptiveHost': 'Pangalan ng brand sa ibang domain',
      'userInfo': 'Mapanlinlang na format ng link',
      'httpLink': 'Hindi encrypted na link',
      'ipHost': 'Numero o IP address',
      'shortLink': 'Pinaikling destinasyon',
      'unusualHost': 'Hindi karaniwang character sa domain',
      'invalidLink': 'Hindi masuri ang link',
      'other': 'Babala',
    });
    return '$_temp0';
  }

  @override
  String findingBody(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'codeRequest':
          'Tiyakin sa ibang paraan bago magbahagi ng code o password.',
      'paymentRequest':
          'Tiyakin ang tatanggap at dahilan bago magpadala ng pera.',
      'urgency': 'Maaaring madaliin ka ng deadline o banta sa account.',
      'prize': 'Tiyakin sa opisyal na paraan na ikaw mismo ang nagbukas.',
      'advanceFee': 'Tiyakin ang dahilan at tatanggap ng paunang bayad.',
      'deceptiveHost':
          'May pangalan ng brand ngunit hindi tugma sa opisyal na domain.',
      'userInfo':
          'Hindi destinasyon ang bago ang @. Ipinapakita ang tunay na host.',
      'httpLink':
          'HTTP ang gamit. Hindi rin garantiya ng pagiging lehitimo ang HTTPS.',
      'ipHost': 'IP address ang gamit sa halip na karaniwang domain.',
      'shortLink':
          'Nakatago ang destinasyon. Hindi pinalawak ng Usisa ang link.',
      'unusualHost': 'Suriin ang encoded o halo-halong character; hindi ito patunay ng scam.',
      'invalidLink':
          'Mali o hindi suportado ang format. Walang pasya sa kaligtasan.',
      'other': 'Tiyakin ang kahilingan bago kumilos.',
    });
    return '$_temp0';
  }
}
