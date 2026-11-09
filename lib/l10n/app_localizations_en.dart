// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get deletedScan => 'Saved scan deleted';

  @override
  String get learnOtpTitle => 'OTP and password requests';

  @override
  String get learnOtpBody =>
      'Treat requests to share a code with care, even when a sender claims to be support. An ordinary OTP reminder may tell you never to share the code. Verify requests through the official app you opened yourself.';

  @override
  String get learnBankTitle => 'Fake bank and e-wallet alerts';

  @override
  String get learnBankBody =>
      'An account suspension threat can pressure you to tap a link. Sender names can be spoofed. Open your bank or e-wallet app directly to check your account; do not use the message\'s link as proof.';

  @override
  String get learnGovernmentTitle => 'Government impersonation';

  @override
  String get learnGovernmentBody =>
      'Messages may claim to come from SSS, PhilHealth, Pag-IBIG, or another agency. Verify unexpected aid, penalty, or registration requests using an independently opened official service. A logo or government name does not prove authenticity.';

  @override
  String get learnDeliveryTitle => 'Unexpected delivery fees';

  @override
  String get learnDeliveryBody =>
      'A small redelivery fee may lead to a page asking for card or account details. Check the order inside the shopping or courier app. A shortened link hides its destination; Usisa does not expand it.';

  @override
  String get learnSellerTitle => 'Online seller payments';

  @override
  String get learnSellerBody =>
      'Be cautious about pressure to move a conversation or payment outside a marketplace\'s normal process. Confirm the seller, item, recipient and payment purpose through trusted records before sending money.';

  @override
  String get learnRecoveryTitle => 'If you already shared details';

  @override
  String get learnRecoveryBody =>
      'Pause further payments and contact your bank or e-wallet through its official app or a trusted contact from your own records. Change affected passwords through the real service. Keep relevant evidence privately. Never share another OTP with someone promising recovery.';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String resultCount(int count) {
    return '$count results';
  }

  @override
  String get scan => 'Scan';

  @override
  String get history => 'History';

  @override
  String get learn => 'Learn';

  @override
  String get settings => 'Settings';

  @override
  String get scanHeading => 'Check before you tap.';

  @override
  String get scanIntro =>
      'A little pause can protect a lot. Check a message or link before you act.';

  @override
  String get localPrivate => 'On your device. Private by default.';

  @override
  String get message => 'Message';

  @override
  String get link => 'Link';

  @override
  String get screenshot => 'Screenshot';

  @override
  String get inputHint => 'Paste or type the message here…';

  @override
  String get pasteText => 'Paste text';

  @override
  String get pasteLink => 'Paste link';

  @override
  String get clear => 'Clear';

  @override
  String get checkMessage => 'Check message';

  @override
  String get checkLink => 'Check link';

  @override
  String get checking => 'Checking warning signs…';

  @override
  String get cancel => 'Cancel';

  @override
  String get chooseScreenshot => 'Choose screenshot';

  @override
  String get screenshotIntro =>
      'Choose an image of a message. Review the extracted text before checking it.';

  @override
  String get ocrNativeOnly =>
      'Screenshot OCR is available in the Android and iOS app. You can paste text here.';

  @override
  String get readingImage => 'Reading screenshot…';

  @override
  String get reviewText => 'Review extracted text';

  @override
  String get ocrNotice =>
      'Images can be misread. Check names, numbers, and links before continuing.';

  @override
  String get checkThisText => 'Check this text';

  @override
  String get noOcrText =>
      'No readable text found. Choose another image or type the message.';

  @override
  String get smsOff => 'Incoming SMS checks unavailable in this build';

  @override
  String get smsDetail =>
      'Manual checks work without SMS access. Automatic checks need an eligible Android build.';

  @override
  String get reminderTitle => 'Never share your OTP.';

  @override
  String get reminderBody =>
      'Verify requests through the official app or a contact you already trust.';

  @override
  String get result => 'Scan result';

  @override
  String get newScan => 'Check another message';

  @override
  String get whyFlagged => 'Why this was flagged';

  @override
  String get linksInMessage => 'Links in this message';

  @override
  String get nextSteps => 'What you can do';

  @override
  String get originalText => 'Original message';

  @override
  String get localChecked => 'Message warning signs checked on this device';

  @override
  String get unknownLink => 'Link safety is unknown.';

  @override
  String get lowCopy =>
      'No common warning signs found. This does not verify who sent the message.';

  @override
  String get cautionCopy =>
      'Some details deserve a closer look. Verify the request before replying or paying.';

  @override
  String get highCopy =>
      'This message has strong warning signs. Pause before sharing information or money.';

  @override
  String get noWarnings => 'No common warning signs detected';

  @override
  String get notChecked => 'Not checked online';

  @override
  String get notListed =>
      'Not on the provider threat list; this does not prove safety';

  @override
  String get linkUnavailable => 'Online check unavailable. Try again later.';

  @override
  String get knownThreat => 'Listed as a potential threat';

  @override
  String get fullLink => 'Full link';

  @override
  String get checkOnline => 'Check links online';

  @override
  String get checkingLinks => 'Checking links…';

  @override
  String get retry => 'Try again';

  @override
  String get verifyAdvice =>
      'Verify through the official app or website you opened yourself.';

  @override
  String get secretAdvice =>
      'Do not share an OTP, password, PIN, or recovery code.';

  @override
  String get paymentAdvice =>
      'Pause the payment. Confirm the recipient through a trusted channel.';

  @override
  String get clickedAdvice =>
      'Already shared details? Contact your bank or e-wallet through its official app immediately.';

  @override
  String get historyHeading => 'Your checks, kept private.';

  @override
  String get historyOff => 'History is off';

  @override
  String get historyOffBody =>
      'Messages stay in this session. Enable encrypted history to keep up to 100 checks for 30 days on this device.';

  @override
  String get enableHistory => 'Enable private history';

  @override
  String get noHistory => 'No scans yet';

  @override
  String get noHistoryBody =>
      'Your saved checks will appear here. Start with a message you want to verify.';

  @override
  String get noMatches => 'No matching scans';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get searchHistory => 'Search saved messages';

  @override
  String get filters => 'Filters';

  @override
  String get allRisk => 'All risks';

  @override
  String get allSources => 'All sources';

  @override
  String get allDates => 'All dates';

  @override
  String get last7 => 'Last 7 days';

  @override
  String get last30 => 'Last 30 days';

  @override
  String get select => 'Select';

  @override
  String get selectAll => 'Select all matching';

  @override
  String get deleteSelected => 'Delete selected';

  @override
  String get delete => 'Delete';

  @override
  String get undo => 'Undo';

  @override
  String get deleteTitle => 'Delete saved scans?';

  @override
  String get deleteBody =>
      'This removes saved checks from Usisa only. It does not delete messages from your SMS app.';

  @override
  String get clearSavedData => 'Clear saved data';

  @override
  String get notSaved =>
      'Not saved. Your result is still available in this session.';

  @override
  String get saveFailed => 'Could not save the change. Try again.';

  @override
  String get learnHeading => 'Spot the signs. Stay a step ahead.';

  @override
  String get learnIntro =>
      'Practical reminders for everyday messages in the Philippines.';

  @override
  String get privacy => 'Privacy and storage';

  @override
  String get appearance => 'Appearance';

  @override
  String get systemTheme => 'Use device setting';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get saveHistory => 'Save private history';

  @override
  String get restoreDraft => 'Restore my draft';

  @override
  String get draftDetail =>
      'Keep one encrypted text draft for up to 24 hours. Screenshots are never saved.';

  @override
  String get onlineChecks => 'Online link checks';

  @override
  String get onlineDisclosure => 'Enable online link checks?';

  @override
  String get onlineBody =>
      'Full URLs, including path and query, will be sent to the Usisa gateway and Google Web Risk for this and future manual scans until disabled. Message text, sender, and images stay on your device. Background SMS checks never upload URLs.';

  @override
  String get enableOnline => 'Enable online checks';

  @override
  String get localOnly => 'Keep local only';

  @override
  String get gatewayMissing =>
      'Online reputation is not configured in this build. Local warning checks still work.';

  @override
  String get about => 'About Usisa';

  @override
  String get aboutBody =>
      'Built for messages in the Philippines. Usisa points out potential scam indicators; it cannot guarantee detection or verify every sender.';

  @override
  String get sessionPreview =>
      'Browser preview: session-only storage. Native OCR and incoming SMS need Android.';

  @override
  String get privateHistoryConsent =>
      'Save encrypted copies of message text, links, and findings on this device for up to 30 days (latest 100 scans). You can erase them at any time.';

  @override
  String get continueAction => 'Continue';

  @override
  String get back => 'Back';

  @override
  String riskLabel(String risk) {
    String _temp0 = intl.Intl.selectLogic(risk, {
      'high': 'High risk',
      'caution': 'Caution',
      'other': 'Low risk',
    });
    return '$_temp0';
  }

  @override
  String sourceLabel(String source) {
    String _temp0 = intl.Intl.selectLogic(source, {
      'link': 'Link',
      'screenshot': 'Screenshot',
      'sms': 'SMS',
      'other': 'Text',
    });
    return '$_temp0';
  }

  @override
  String errorMessage(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'emptyInput': 'Enter a message or link first.',
      'textTooLong': 'Keep within 10,000 characters. Nothing was cut.',
      'invalidUrl':
          'Enter one complete HTTP or HTTPS link. Use Text for multiple links.',
      'urlTooLong': 'A link exceeds 2,048 characters. Edit it first.',
      'tooManyLinks': 'Check up to 10 distinct links at a time.',
      'imageTooLarge': 'Choose an image under 20 MB and 20 megapixels.',
      'other':
          'The check could not finish. Your input is still here. Try again.',
    });
    return '$_temp0';
  }

  @override
  String findingTitle(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'codeRequest': 'Asks for a security secret',
      'paymentRequest': 'Requests a payment',
      'urgency': 'Pressures you to act',
      'prize': 'Promises a prize',
      'advanceFee': 'Asks for an upfront fee',
      'deceptiveHost': 'Brand name on a different domain',
      'userInfo': 'Misleading link format',
      'httpLink': 'Unencrypted link',
      'ipHost': 'Numeric or IP address',
      'shortLink': 'Shortened destination',
      'unusualHost': 'Unusual domain characters',
      'invalidLink': 'Link could not be assessed',
      'other': 'Warning sign',
    });
    return '$_temp0';
  }

  @override
  String findingBody(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'codeRequest': 'Verify independently before sharing a code or password.',
      'paymentRequest':
          'Confirm the recipient and reason before sending money.',
      'urgency':
          'Deadlines and account threats can discourage careful checking.',
      'prize': 'Verify through an official channel you opened independently.',
      'advanceFee': 'Verify the purpose and recipient of any upfront fee.',
      'deceptiveHost': 'This host contains a brand but does not match its reviewed official domain.',
      'userInfo':
          'Text before the @ is not the destination. The real host is shown.',
      'httpLink': 'This uses HTTP. HTTPS also does not guarantee legitimacy.',
      'ipHost': 'The link uses an IP address rather than an ordinary domain.',
      'shortLink':
          'The final destination is hidden. Usisa has not expanded this link.',
      'unusualHost': 'Encoded or mixed-script characters need review; they do not prove fraud.',
      'invalidLink': 'The format is malformed or unsupported. No safety verdict is available.',
      'other': 'Verify the request before acting.',
    });
    return '$_temp0';
  }
}
