import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fil'),
  ];

  /// No description provided for @navCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get navCheck;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get navLearn;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Kept in Filipino in both languages, per DESIGN.md.
  ///
  /// In en, this message translates to:
  /// **'Magandang umaga!'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Magandang hapon!'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Magandang gabi!'**
  String get greetingEvening;

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Is this text\na scam?'**
  String get homeHeadline;

  /// No description provided for @homePrompt.
  ///
  /// In en, this message translates to:
  /// **'What do you want to check?'**
  String get homePrompt;

  /// No description provided for @tileMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a message'**
  String get tileMessageTitle;

  /// No description provided for @tileMessageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste a text you got'**
  String get tileMessageSubtitle;

  /// No description provided for @tileLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Check a link'**
  String get tileLinkTitle;

  /// No description provided for @tileLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See where it really goes'**
  String get tileLinkSubtitle;

  /// No description provided for @tileScreenshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a screenshot'**
  String get tileScreenshotTitle;

  /// No description provided for @tileScreenshotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a photo of the text'**
  String get tileScreenshotSubtitle;

  /// No description provided for @tileAiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI scan'**
  String get tileAiTitle;

  /// No description provided for @tileAiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask AI to look closely'**
  String get tileAiSubtitle;

  /// No description provided for @smsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto SMS protection'**
  String get smsCardTitle;

  /// No description provided for @smsCardOn.
  ///
  /// In en, this message translates to:
  /// **'New texts will be checked'**
  String get smsCardOn;

  /// No description provided for @smsCardOff.
  ///
  /// In en, this message translates to:
  /// **'Texts are not being checked'**
  String get smsCardOff;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fil'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
