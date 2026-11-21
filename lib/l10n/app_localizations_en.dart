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
}
