// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get analysisMode => 'Pagsusuri';

  @override
  String get onDevice => 'Sa device';

  @override
  String get aiAssisted => 'May tulong ng AI';

  @override
  String get aiManualOnly =>
      'Magpapadala lang ng teksto sa AI matapos mong suriin at kumpirmahin.';

  @override
  String get aiReviewTitle => 'Suriin bago ipadala sa AI';

  @override
  String get aiDisclosure =>
      'Ipapadala ang mismong tekstong ito sa server ng Usisa at sa Groq para sa pagsusuri ng AI. Alisin ang mga code o personal na detalyeng ayaw mong ibahagi. Kasama ang mga pangalan, numero at link sa tekstong ito. Mananatili sa device ang screenshot at hiwalay na detalye ng nagpadala. Maaaring magtago ang Groq ng mga request para sa pagiging maaasahan o pagsubaybay sa pang-aabuso, depende sa setting ng account. Maaaring magkamali ang AI; hindi nito pinapatunayan ang nagpadala o binibisita ang mga link.';

  @override
  String get aiTextLabel => 'Tekstong ipapadala';

  @override
  String get sendAi => 'Ipadala ang tekstong ito para sa AI';

  @override
  String get keepOnDevice => 'Panatilihin sa device';

  @override
  String get aiAssessment => 'Pagsusuri ng AI';

  @override
  String get onDeviceFindings => 'Mga nakita sa device';

  @override
  String get aiChecking =>
      'Tapos na ang pagsusuri sa device. Nagsusuri ang AI…';

  @override
  String get aiUnknown =>
      'Hindi masuri ng AI ang mensaheng ito. Gamitin ang lokal na resulta at tiyakin sa ibang paraan.';

  @override
  String get aiUnavailable =>
      'Tapos na ang lokal na check, pero hindi available ang AI. Nandito pa ang teksto. Suriin at subukan muli.';

  @override
  String get aiCancelled =>
      'Kinansela ang AI check. Nananatili ang lokal na resulta. Maaaring maproseso pa rin ang naipadalang request.';

  @override
  String get aiNotRequested =>
      'Wala pang AI check. Suriin ang teksto bago idagdag ito.';

  @override
  String get aiDisagreement =>
      'Magkaiba ang resulta. Panatilihin ang mas mataas na babala; walang resulta ang nagpapatunay na ligtas ang mensahe.';

  @override
  String get aiReviewed => 'Ginamit ng AI ang sinuri mong teksto.';

  @override
  String get aiRetry => 'Suriin at subukang muli ang AI';

  @override
  String get aiLimitations =>
      'Maaaring makaligtaan ng AI ang scam o magbigay ng maling babala. Ipinapakita ng sipi ang ginamit na teksto, hindi patunay.';

  @override
  String get aiSettingsBody =>
      'Tumutulong ang AI sa teksto, link, at tekstong inaprubahan mo mula sa screenshot. Kumpirmahin ang bawat upload sa Usisa at Groq. Sa device lang ang auto SMS. Hindi kasama ang AI sa pahintulot sa link check.';

  @override
  String aiFindingTitle(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'credential_request': 'Humihingi ng lihim na pangseguridad',
      'payment_request': 'Humihingi ng bayad',
      'urgency': 'Minamadali kang kumilos',
      'impersonation': 'Posibleng pagpapanggap',
      'prize': 'Nangangako ng premyo',
      'suspicious_link': 'Kaduda-dudang konteksto ng link',
      'other': 'Babalang nakita ng AI',
    });
    return '$_temp0';
  }

  @override
  String aiAdvice(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'dont_share_secrets':
          'Huwag ibahagi ang OTP, password o PIN sa sinumang humihingi nito.',
      'pause_payment': 'Ipagpaliban ang pagbabayad. Hiwalay na kumpirmahin ang tatanggap at dahilan.',
      'contact_provider_if_shared': 'Kung nagbahagi ka na ng detalye, kontakin ang provider sa opisyal na app o sarili mong pinagkakatiwalaang tala.',
      'other': 'Magberipika sa opisyal na app o pinagkakatiwalaang paraang ikaw mismo ang nagbukas.',
    });
    return '$_temp0';
  }

  @override
  String get deletedScan => 'Nabura ang naka-save na pagsusuri';

  @override
  String get learnOtpTitle => 'Paghingi ng OTP at password';

  @override
  String get learnOtpBody =>
      'Mag-ingat sa paghingi ng code, kahit magpakilalang support. Maaaring paalalahanan ka ng lehitimong OTP na huwag itong ibahagi. Tiyakin sa opisyal na app.';

  @override
  String get learnBankTitle => 'Scam sa Bank at E-Wallet';

  @override
  String get learnBankBody =>
      'Maaaring madaliin ka ng banta sa account. Puwedeng peke ang pangalan ng sender. Buksan mismo ang app ng bangko o e-wallet; huwag magtiwala sa link.';

  @override
  String get learnBankSummary =>
      'Pekeng text mula sa BPI,\nGCash, Maya, at iba pa.';

  @override
  String get learnGovernmentTitle => 'Pagpapanggap sa Gobyerno';

  @override
  String get learnGovernmentBody =>
      'Maaaring magpanggap na SSS, PhilHealth, Pag-IBIG, o ibang ahensiya ang scammer. Tiyakin ang di-inaasahang ayuda, multa, o registration sa opisyal na serbisyong ikaw mismo ang nagbukas. Hindi patunay ang logo.';

  @override
  String get learnGovernmentSummary =>
      'Pekeng mensahe kuno mula sa\nSSS, PAG-IBIG, PhilPost, at iba pa.';

  @override
  String get learnDeliveryTitle => 'Di-inaasahang bayad sa delivery';

  @override
  String get learnDeliveryBody =>
      'Maaaring nakawin ng pekeng redelivery fee ang detalye ng card o account. Tingnan ang order sa courier app. Itinatago ng short link ang destinasyon; hindi ito pinalalawak ng Usisa.';

  @override
  String get learnSellerTitle => 'Scam sa Online Selling';

  @override
  String get learnSellerBody =>
      'Mag-ingat kung inililipat ng seller ang bayad sa labas ng marketplace. Tiyakin ang seller, produkto, tatanggap, at dahilan bago magbayad.';

  @override
  String get learnSellerSummary =>
      'Pekeng seller at patunay ng bayad,\nat delivery.';

  @override
  String get learnRecoveryTitle => 'Kung nakapagbahagi ka na ng detalye';

  @override
  String get learnRecoveryBody =>
      'Itigil muna ang bayad. Kontakin ang bangko o e-wallet sa opisyal na app o pinagkakatiwalaang contact. Palitan ang password na posibleng nalantad; itago ang ebidensiya. Huwag magbigay ng panibagong OTP sa nangangakong magre-recover.';

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
  String get messageScanPrompt => 'I-paste o i-type ang mensahe para masuri';

  @override
  String get messageScanSupport =>
      'Hahanapin namin ang scam link at mapaminsalang content.';

  @override
  String get scanHeading => 'Suriin bago pindutin.';

  @override
  String get scanIntro => 'Suriin ang mensahe o link bago kumilos.';

  @override
  String get localPrivate => 'Sa device mo nananatili ang mga check.';

  @override
  String get message => 'Mensahe';

  @override
  String get link => 'Link';

  @override
  String get screenshot => 'Screenshot';

  @override
  String get screenshotHeading => 'Suriin ang screenshot';

  @override
  String get screenshotSelected => 'Napili ang screenshot';

  @override
  String get changeImage => 'Palitan ang larawan';

  @override
  String get screenshotSupported => 'PNG, JPG, JPEG, o WEBP · Hanggang 10 MB';

  @override
  String get linkCheckPrompt => 'Suriin kung ligtas ang link';

  @override
  String get linkCheckSupport => 'Tingnan ang mga babala bago buksan ang URL.';

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
  String get loading => 'Naglo-load';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get chooseScreenshot => 'Pumili ng screenshot';

  @override
  String get photos => 'Mga larawan';

  @override
  String get browseFiles => 'Mag-browse ng mga file';

  @override
  String get screenshotIntro =>
      'Pumili ng screenshot ng mensahe. Suriin ang teksto bago mag-scan.';

  @override
  String get ocrNativeOnly =>
      'Gumagana ang OCR sa Android at iOS. Maaari ka ring mag-paste ng teksto.';

  @override
  String get readingImage => 'Binabasa ang screenshot…';

  @override
  String get reviewText => 'Suriin ang nakuhang teksto';

  @override
  String get ocrNotice =>
      'Suriin ang mga pangalan, numero, at link. Maaaring magkamali ang OCR.';

  @override
  String get previewUnavailable =>
      'Hindi maipakita ang larawan. Suriin at i-edit pa rin ang nakuha nitong teksto.';

  @override
  String get checkThisText => 'Suriin ang tekstong ito';

  @override
  String get noOcrText =>
      'Walang nabasang teksto. Pumili ng ibang larawan o i-type ang mensahe.';

  @override
  String get smsOff => 'Hindi available ang auto SMS.';

  @override
  String get smsDetail =>
      'Maaari kang mag-scan nang walang SMS access. Kailangan ng suportadong Android phone para sa auto check.';

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
  String get checkAnotherLink => 'Suriin ang ibang link';

  @override
  String get checkAnotherScreenshot => 'Suriin ang ibang screenshot';

  @override
  String get viewFullImage => 'Tingnan ang buong larawan';

  @override
  String get checkAiShort => 'Suriin';

  @override
  String get linkDomainLabel => 'Domain';

  @override
  String get linkSimilarityLabel => 'Pagkakatulad';

  @override
  String get linkStatusLabel => 'Status';

  @override
  String resultLinkCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count na link ang nakita',
      one: '1 link ang nakita',
    );
    return '$_temp0';
  }

  @override
  String resultMoreFindings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tingnan ang $count pang senyales',
      one: 'Tingnan ang 1 pang senyales',
    );
    return '$_temp0';
  }

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
      'Walang karaniwang babala. Hindi nito pinatutunayan ang nagpadala.';

  @override
  String get cautionCopy =>
      'Suriing mabuti ang ilang detalye bago sumagot o magbayad.';

  @override
  String get highCopy =>
      'Maraming babala. Huminto muna bago magpadala ng pera o detalye.';

  @override
  String resultRiskLabel(String risk) {
    String _temp0 = intl.Intl.selectLogic(risk, {
      'low': 'Ligtas',
      'caution': 'Kailangang Suriin',
      'other': 'Mataas na Panganib',
    });
    return '$_temp0';
  }

  @override
  String get unknownStatus => 'Hindi tiyak';

  @override
  String get analysisSummary => 'Buod ng Pagsusuri';

  @override
  String get detectedSigns => 'Mga Natukoy na Senyales';

  @override
  String get noWarnings => 'Walang karaniwang babalang nakita';

  @override
  String get notChecked => 'Hindi pa nasuri online';

  @override
  String get notListed =>
      'Wala sa listahan ng banta. Hindi ibig sabihin nito ay ligtas.';

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
      'Nakapagbahagi na? Kontakin agad ang bangko o e-wallet sa opisyal na app nito.';

  @override
  String get historyHeading => 'Pribado ang iyong mga pagsusuri.';

  @override
  String get historyAll => 'Lahat';

  @override
  String get today => 'Ngayon';

  @override
  String get yesterday => 'Kahapon';

  @override
  String get historyOff => 'Naka-off ang kasaysayan';

  @override
  String get historyOffBody =>
      'Mag-save ng hanggang 100 encrypted na scan sa loob ng 30 araw.';

  @override
  String get enableHistory => 'I-enable ang pribadong kasaysayan';

  @override
  String get noHistory => 'Wala pang pagsusuri';

  @override
  String get noHistoryBody =>
      'Dito lalabas ang mga naka-save na check. Magsimula sa mensaheng gusto mong tiyakin.';

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
      'Aalisin nito ang naka-save na check sa Usisa, hindi ang SMS sa messaging app.';

  @override
  String get clearSavedData => 'Burahin ang naka-save na datos';

  @override
  String get notSaved =>
      'Hindi na-save. Nandito pa ang resulta sa session na ito.';

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
  String get language => 'Wika';

  @override
  String get saveHistory => 'I-save ang pribadong kasaysayan';

  @override
  String get restoreDraft => 'Ibalik ang aking draft';

  @override
  String get draftDetail =>
      'Encrypted na text draft sa loob ng 24 oras. Hindi sine-save ang screenshot.';

  @override
  String get onlineChecks => 'Online na pagsusuri ng link';

  @override
  String get onlineDisclosure => 'I-enable ang online na pagsusuri ng link?';

  @override
  String get onlineSettingsDescription =>
      'Suriin online ang buong URL gamit ang Google Safe Browsing.';

  @override
  String get onlineBody =>
      'Habang naka-on, ipinapadala ng manwal na link check ang buong URL, kasama ang path at query, sa gateway ng Usisa at Google Safe Browsing. Sa device mananatili ang mensahe, nagpadala, at larawan. Hindi nag-a-upload ng URL ang SMS check. Maaaring makaligtaan ng Google ang banta o mag-flag ng ligtas na site. Nag-e-expire ang online na babala. Lokal na resulta at huling check lang ang sine-save sa history, hindi ang online na hatol.';

  @override
  String get googleAdvisory => 'Paalala mula sa Google';

  @override
  String get advisoryUnavailable =>
      'Hindi mabuksan ang pahina ng tulong. Nandito pa rin ang iyong pagsusuri.';

  @override
  String get phishingHelp => 'Alamin ang phishing';

  @override
  String get malwareHelp => 'Alamin ang malware';

  @override
  String get unwantedHelp => 'Alamin ang di-kanais-nais na software';

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
      'Para sa mga mensahe sa Pilipinas. Ipinapakita ng Usisa ang posibleng babala, pero maaaring may scam na hindi makita at hindi nito pinatutunayan ang nagpadala.';

  @override
  String get sessionPreview =>
      'Sa browser preview, session lang ang storage. Kailangan ng Android para sa OCR at papasok na SMS.';

  @override
  String get privateHistoryConsent =>
      'Mag-save ng encrypted na teksto, link, at resulta sa device (pinakahuling 100 scan). Nag-e-expire ang review pagkalipas ng 30 araw. Binubura ng Usisa ang expired file habang bukas o sa susunod na paggamit. Hindi ito magagawa sa takdang oras kapag naka-stop ang app. Burahin ang naka-save na datos para mabura agad kung available ang storage.';

  @override
  String get reviewRecoveredScreenshot => 'Suriin ang nakaraang screenshot';

  @override
  String get discardRecoveredScreenshot => 'Alisin ang nakaraang screenshot';

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
      'Suriin ang kahina-hinalang mensahe at link para sa babala. Para sa English, Filipino, at Taglish sa Pilipinas.';

  @override
  String get welcomePrivacy =>
      'Gumagana offline ang manwal na check. Opsyonal at naka-off muna ang history, online link check, at SMS. Maaaring may scam na hindi makita. Tiyakin nang hiwalay ang mahahalagang hiling.';

  @override
  String get startChecking => 'Simulang magsuri';

  @override
  String get smsHeading => 'Pagsuri ng papasok na SMS';

  @override
  String get smsDisclosure => 'I-enable ang pagsuri ng SMS?';

  @override
  String get smsDisclosureBody =>
      'Sa device lang sinusuri ang bagong SMS. Hindi ina-upload ang mensahe o binabasa ang inbox at ibang app. Nag-e-expire sa 15 minuto ang hanggang 20 encrypted na review. Maaaring maantala ang check ng Android; hihinto ito kapag force-stop. May scam na maaaring hindi makita.';

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
      'Sa device lang sinusuri. Maaaring maantala ng Android. Hindi garantisado ang lahat; walang alerto sa mababang panganib.';

  @override
  String get smsAlertsOff =>
      'Naka-off ang notification. Nandito pa rin ang kamakailang review. I-on ang alert sa Android settings.';

  @override
  String get enableSmsAlerts => 'I-enable ang mga notification';

  @override
  String get smsDegraded =>
      'May mensaheng hindi nasuri. I-off at i-on muli ang SMS check.';

  @override
  String get manageSms => 'Pamahalaan ang pagsuri ng SMS';

  @override
  String get recentSms => 'Kamakailang SMS';

  @override
  String get smsTemporary =>
      'Naka-encrypt ang pansamantalang review at nag-e-expire pagkalipas ng 15 minuto. Binubura ang mababang panganib matapos suriin.';

  @override
  String get smsEmpty =>
      'Walang pansamantalang review. Maaaring nag-expire, mababa ang panganib, o dumating habang naka-off ang check.';

  @override
  String get smsMissing =>
      'Hindi available ang review. Maaaring nag-expire, nabura, o naka-off ang SMS check. Kopyahin ang mensahe para sa manwal na scan.';

  @override
  String get smsPending =>
      'Wala pang natapos na check. Subukan muli o kopyahin ang mensahe para sa manwal na scan.';

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

  @override
  String get homeHeading => 'Isang hakbang sa unahan ng mga scam.';

  @override
  String get homeBrand => 'Usisa';

  @override
  String get homeBody =>
      'Suriin ang mensahe, link, at screenshot para sa babala ng scam.';

  @override
  String get scanMessageCard => 'Suriin ang mensahe';

  @override
  String get scanMessageDescription => 'I-paste o i-type ang mensahe';

  @override
  String get checkLinkCard => 'Suriin ang link';

  @override
  String get checkLinkDescription => 'Suriin ang URL bago buksan.';

  @override
  String get scanScreenshotCard => 'Suriin ang screenshot';

  @override
  String get scanScreenshotDescription =>
      'Basahin ang mensahe mula sa screenshot.';

  @override
  String get aiScan => 'AI Scan';

  @override
  String get aiBeta => 'Beta';

  @override
  String get aiHomeDescription => 'Magpatulong sa AI sa pagsusuri ng scam.';

  @override
  String get homeAiBadge => 'Bago';

  @override
  String get autoSmsCard => 'Awtomatikong SMS';

  @override
  String get autoSmsDescription => 'Suriin ang SMS para sa scam.';

  @override
  String get aiIntroTitle => 'Pagsusuri ng scam gamit ang AI';

  @override
  String get aiIntroBody =>
      'Suriin ang mensahe, link, o screenshot. Ipapaliwanag ng AI ang panganib at susunod na hakbang.';

  @override
  String get aiMultiInput => 'Iba’t ibang input';

  @override
  String get aiMultiInputBody => 'Teksto, link, o screenshot na may OCR';

  @override
  String get aiContextAware => 'May konteksto';

  @override
  String get aiContextAwareBody =>
      'Naghahanap ng karaniwang pattern ng scam sa PH';

  @override
  String get aiActionable => 'May susunod na hakbang';

  @override
  String get aiActionableBody =>
      'Antas ng panganib, paliwanag, at susunod na hakbang';

  @override
  String get startAiScan => 'Simulan ang AI Scan';

  @override
  String get aiInputQuestion => 'Ano ang gusto mong suriin?';

  @override
  String get aiTextOption => 'Teksto / Mensahe';

  @override
  String get aiTextOptionBody => 'I-paste o i-type ang kahina-hinalang mensahe';

  @override
  String get aiLinkOption => 'URL / Link';

  @override
  String get aiLinkOptionBody => 'Suriin ang link para sa babala ng scam.';

  @override
  String get aiScreenshotOption => 'Screenshot / Larawan';

  @override
  String get aiScreenshotOptionBody =>
      'Basahin at suriin ang teksto gamit ang OCR.';

  @override
  String get aiProgressTitle => 'Sinusuri ng AI…';

  @override
  String get aiStageReviewed => 'Nakumpirma ang sinuring teksto';

  @override
  String get aiStageLocal => 'Tapos na ang pagsusuri sa device';

  @override
  String get aiStageRequest => 'Ipinapadala ang teksto para sa AI check…';

  @override
  String get aiStageResult => 'Inihahanda ang resulta';

  @override
  String get smsDetectionTitle => 'Pagsuri ng SMS';

  @override
  String get smsDetectionBody =>
      'Sinusuri ang bagong SMS para sa scam at nag-aalerto sa kahina-hinalang mensahe.';

  @override
  String get smsRecentDetections => 'Mga kamakailang SMS check';

  @override
  String get warningSigns => 'Mga natukoy na babala';

  @override
  String get safetyRecommendations => 'Mga rekomendasyong pangkaligtasan';

  @override
  String get linkWhyRisky => 'Bakit ito kahina-hinala?';

  @override
  String get learnScamTips => 'Mga paalala laban sa scam';

  @override
  String get learnScamTipsBody =>
      'Mga simpleng paraan para umiwas\nsa karaniwang scam sa Pilipinas.';

  @override
  String get learnCommonScams => 'Karaniwang scam sa PH';

  @override
  String get getStarted => 'Magsimula';

  @override
  String get onboardingSecondTitle => 'Alamin kung bakit na-flag ang mensahe.';

  @override
  String get onboardingSecondBody =>
      'Tingnan ang mga salita, link, at hiling na dapat siyasatin.';

  @override
  String get onboardingThirdTitle => 'Ikaw ang pipili ng mananatili sa device.';

  @override
  String get onboardingThirdBody =>
      'Sa device lang ang manwal na check. Kailangan ng pagsuri at pahintulot mo bago mag-AI o online link check.';

  @override
  String get linkCheckerTitle => 'Taga-suri ng link';

  @override
  String get aiScanResult => 'Resulta ng AI Scan';

  @override
  String get learnStaySafeTitle => 'Matuto at Manatiling Ligtas';

  @override
  String get detection => 'Pagsusuri';

  @override
  String get general => 'Pangkalahatan';

  @override
  String get notifications => 'Mga notification';

  @override
  String get aiScanToggleBody => 'Suriin muna bago ipadala sa AI.';

  @override
  String get smsNotificationsEnabled => 'Naka-on ang SMS notifications.';

  @override
  String smsRecentTab(int count) {
    return 'Kamakailan ($count)';
  }

  @override
  String smsFlaggedTab(int count) {
    return 'Na-flag ($count)';
  }

  @override
  String get smsFlaggedEmpty => 'Walang na-flag sa kamakailang SMS check.';

  @override
  String get home => 'Home';
}
