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
}
