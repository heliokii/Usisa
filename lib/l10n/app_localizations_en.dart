// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navCheck => 'Check';

  @override
  String get navHistory => 'History';

  @override
  String get navLearn => 'Learn';

  @override
  String get navSettings => 'Settings';

  @override
  String get greetingMorning => 'Magandang umaga!';

  @override
  String get greetingAfternoon => 'Magandang hapon!';

  @override
  String get greetingEvening => 'Magandang gabi!';

  @override
  String get homeHeadline => 'Is this text\na scam?';

  @override
  String get homePrompt => 'What do you want to check?';

  @override
  String get tileMessageTitle => 'Scan a message';

  @override
  String get tileMessageSubtitle => 'Paste a text you got';

  @override
  String get tileLinkTitle => 'Check a link';

  @override
  String get tileLinkSubtitle => 'See where it really goes';

  @override
  String get tileScreenshotTitle => 'Scan a screenshot';

  @override
  String get tileScreenshotSubtitle => 'Pick a photo of the text';

  @override
  String get tileAiTitle => 'AI scan';

  @override
  String get tileAiSubtitle => 'Ask AI to look closely';

  @override
  String get smsCardTitle => 'Auto SMS protection';

  @override
  String get smsCardOn => 'New texts will be checked';

  @override
  String smsCardChecked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count texts checked today',
      one: '1 text checked today',
    );
    return '$_temp0';
  }

  @override
  String get smsCardOff => 'Texts are not being checked';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String aiFindingTitle(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'credential_request': 'Asks for a security secret',
      'payment_request': 'Requests a payment',
      'urgency': 'Pressures you to act',
      'impersonation': 'Possible impersonation',
      'prize': 'Promises a prize',
      'suspicious_link': 'Questionable link context',
      'gambling_ad': 'Gambling ad',
      'other': 'AI warning sign',
    });
    return '$_temp0';
  }

  @override
  String get pasteHint => 'Paste the text message here';

  @override
  String get checkButton => 'Check';

  @override
  String get screenshotIntro =>
      'Pick a screenshot of the message. We\'ll read the text for you.';

  @override
  String get screenshotChoose => 'Choose a screenshot';

  @override
  String get screenshotReview => 'Check the text we read and fix any mistakes.';

  @override
  String get screenshotNoText =>
      'We couldn\'t read any text in this picture. Try a clearer screenshot.';

  @override
  String verdictWord(String verdict) {
    String _temp0 = intl.Intl.selectLogic(verdict, {
      'looksSafe': 'Looks safe',
      'beCareful': 'Be careful',
      'dangerous': 'Dangerous',
      'other': 'Couldn\'t check',
    });
    return '$_temp0';
  }

  @override
  String verdictAction(String verdict) {
    String _temp0 = intl.Intl.selectLogic(verdict, {
      'looksSafe': 'Nothing suspicious found. Still, never share your OTP or PIN with anyone.',
      'beCareful':
          'Don\'t tap links or send money until you\'re sure who sent this.',
      'dangerous': 'Don\'t tap the link, don\'t reply, and don\'t send money.',
      'other': 'We couldn\'t check this fully. Don\'t open any link or enter any details until you\'re sure who sent it.',
    });
    return '$_temp0';
  }

  @override
  String get verdictWhy => 'Why';

  @override
  String get checkedOnPhone => 'Checked on your phone';

  @override
  String get youChecked => 'You checked';

  @override
  String reason(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'no_signs': 'We found no warning signs',
      'otp_with_link': 'It asks for your OTP or password and has a link',
      'lookalike_domain': 'The link pretends to be a known brand\'s website',
      'prize_claim': 'It says you won a prize you have to claim',
      'urgency': 'It rushes you to act quickly',
      'gambling_ad': 'This is an unsolicited gambling ad',
      'flagged_link': 'Google lists this link as unsafe',
      'shortener_blocked': 'The link shortener has blocked this link',
      'opens_app': 'The link opens an app instead of a website',
      'unresolved_link': 'We couldn\'t see where the link goes',
      'harmless_promo': 'This looks like an ordinary promo',
      'brand_mention': 'It mentions a bank, e-wallet or government office',
      'family_money':
          'It asks for money or load, which is normal between family',
      'credential_request': 'It asks for a password, PIN or code',
      'payment_request': 'It asks you to pay or send money',
      'impersonation': 'It may be pretending to be someone else',
      'prize': 'It promises a prize',
      'suspicious_link': 'The link looks suspicious',
      'other': 'We found another warning sign',
    });
    return '$_temp0';
  }

  @override
  String get linkHint => 'Paste the link here';

  @override
  String reallyGoesTo(String destination) {
    return 'Really goes to $destination';
  }

  @override
  String get consentTitle => 'Check links online?';

  @override
  String get consentBody =>
      'To see where a link really goes and whether Google lists it as unsafe, Usisa sends the link to its checking service. If you use AI scan, the message text is sent to an AI service too.';

  @override
  String get consentDecline =>
      'If you say no, Usisa checks everything on your phone only. It can\'t see where links really go, so it may miss some scams.';

  @override
  String get consentLater => 'You can change this later in Settings.';

  @override
  String get consentAllow => 'Yes, check online';

  @override
  String get consentDeny => 'No, phone only';

  @override
  String get historySavedOnPhone => 'Saved only on this phone';

  @override
  String get historySaveSwitch => 'Save my checks';

  @override
  String get historySaveNote => 'Turning this off also clears your History.';

  @override
  String get historyEmpty => 'No saved checks yet.';

  @override
  String get historyOff => 'Saving is off.';

  @override
  String get historyClearAll => 'Clear all';

  @override
  String get historyClearTitle => 'Clear all History?';

  @override
  String get historyClearBody =>
      'This removes every saved check from this phone. It can\'t be undone.';

  @override
  String get historyDelete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get fromYourTexts => 'From your texts';

  @override
  String checkedOnDate(String date) {
    return 'Checked on $date';
  }

  @override
  String get checkAgain => 'Check again';

  @override
  String get settingsDisplay => 'Display';

  @override
  String get settingsTextSize => 'Text size';

  @override
  String get textSizeNormal => 'Normal';

  @override
  String get textSizeLarge => 'Large';

  @override
  String get textSizeExtraLarge => 'Extra large';

  @override
  String get settingsTextSizeNote =>
      'This adds to your phone\'s own text size.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFilipino => 'Filipino';

  @override
  String get settingsProtection => 'Protection';

  @override
  String get settingsOnline => 'Online checks';

  @override
  String get settingsOnlineSwitch => 'Check links and use AI online';

  @override
  String get settingsOnlineOn =>
      'Links go to Usisa\'s checking service. AI scan sends the message text to an AI service.';

  @override
  String get settingsOnlineOff =>
      'Everything is checked on your phone only, so Usisa may miss some scams.';

  @override
  String get settingsAbout => 'About';

  @override
  String get aboutGuide =>
      'Usisa is a guide, not a guarantee. It looks for common scam signs, but it can be wrong. If something feels off, don\'t click, don\'t pay and don\'t share codes. Ask someone you trust.';

  @override
  String get aboutData =>
      'Your checks and History are saved only on this phone. Nothing is sent anywhere unless online checks are on.';
}
