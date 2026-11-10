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

  /// No description provided for @deletedScan.
  ///
  /// In en, this message translates to:
  /// **'Saved scan deleted'**
  String get deletedScan;

  /// No description provided for @learnOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'OTP and password requests'**
  String get learnOtpTitle;

  /// No description provided for @learnOtpBody.
  ///
  /// In en, this message translates to:
  /// **'Treat requests to share a code with care, even when a sender claims to be support. An ordinary OTP reminder may tell you never to share the code. Verify requests through the official app you opened yourself.'**
  String get learnOtpBody;

  /// No description provided for @learnBankTitle.
  ///
  /// In en, this message translates to:
  /// **'Fake bank and e-wallet alerts'**
  String get learnBankTitle;

  /// No description provided for @learnBankBody.
  ///
  /// In en, this message translates to:
  /// **'An account suspension threat can pressure you to tap a link. Sender names can be spoofed. Open your bank or e-wallet app directly to check your account; do not use the message\'s link as proof.'**
  String get learnBankBody;

  /// No description provided for @learnGovernmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Government impersonation'**
  String get learnGovernmentTitle;

  /// No description provided for @learnGovernmentBody.
  ///
  /// In en, this message translates to:
  /// **'Messages may claim to come from SSS, PhilHealth, Pag-IBIG, or another agency. Verify unexpected aid, penalty, or registration requests using an independently opened official service. A logo or government name does not prove authenticity.'**
  String get learnGovernmentBody;

  /// No description provided for @learnDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Unexpected delivery fees'**
  String get learnDeliveryTitle;

  /// No description provided for @learnDeliveryBody.
  ///
  /// In en, this message translates to:
  /// **'A small redelivery fee may lead to a page asking for card or account details. Check the order inside the shopping or courier app. A shortened link hides its destination; Usisa does not expand it.'**
  String get learnDeliveryBody;

  /// No description provided for @learnSellerTitle.
  ///
  /// In en, this message translates to:
  /// **'Online seller payments'**
  String get learnSellerTitle;

  /// No description provided for @learnSellerBody.
  ///
  /// In en, this message translates to:
  /// **'Be cautious about pressure to move a conversation or payment outside a marketplace\'s normal process. Confirm the seller, item, recipient and payment purpose through trusted records before sending money.'**
  String get learnSellerBody;

  /// No description provided for @learnRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'If you already shared details'**
  String get learnRecoveryTitle;

  /// No description provided for @learnRecoveryBody.
  ///
  /// In en, this message translates to:
  /// **'Pause further payments and contact your bank or e-wallet through its official app or a trusted contact from your own records. Change affected passwords through the real service. Keep relevant evidence privately. Never share another OTP with someone promising recovery.'**
  String get learnRecoveryBody;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @resultCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultCount(int count);

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @scanHeading.
  ///
  /// In en, this message translates to:
  /// **'Check before you tap.'**
  String get scanHeading;

  /// No description provided for @scanIntro.
  ///
  /// In en, this message translates to:
  /// **'A little pause can protect a lot. Check a message or link before you act.'**
  String get scanIntro;

  /// No description provided for @localPrivate.
  ///
  /// In en, this message translates to:
  /// **'On your device. Private by default.'**
  String get localPrivate;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @screenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get screenshot;

  /// No description provided for @inputHint.
  ///
  /// In en, this message translates to:
  /// **'Paste or type the message here…'**
  String get inputHint;

  /// No description provided for @pasteText.
  ///
  /// In en, this message translates to:
  /// **'Paste text'**
  String get pasteText;

  /// No description provided for @pasteLink.
  ///
  /// In en, this message translates to:
  /// **'Paste link'**
  String get pasteLink;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @checkMessage.
  ///
  /// In en, this message translates to:
  /// **'Check message'**
  String get checkMessage;

  /// No description provided for @checkLink.
  ///
  /// In en, this message translates to:
  /// **'Check link'**
  String get checkLink;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking warning signs…'**
  String get checking;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @chooseScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Choose screenshot'**
  String get chooseScreenshot;

  /// No description provided for @screenshotIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose an image of a message. Review the extracted text before checking it.'**
  String get screenshotIntro;

  /// No description provided for @ocrNativeOnly.
  ///
  /// In en, this message translates to:
  /// **'Screenshot OCR is available in the Android and iOS app. You can paste text here.'**
  String get ocrNativeOnly;

  /// No description provided for @readingImage.
  ///
  /// In en, this message translates to:
  /// **'Reading screenshot…'**
  String get readingImage;

  /// No description provided for @reviewText.
  ///
  /// In en, this message translates to:
  /// **'Review extracted text'**
  String get reviewText;

  /// No description provided for @ocrNotice.
  ///
  /// In en, this message translates to:
  /// **'Images can be misread. Check names, numbers, and links before continuing.'**
  String get ocrNotice;

  /// No description provided for @previewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image preview is unavailable. You can still review and edit the extracted text.'**
  String get previewUnavailable;

  /// No description provided for @checkThisText.
  ///
  /// In en, this message translates to:
  /// **'Check this text'**
  String get checkThisText;

  /// No description provided for @noOcrText.
  ///
  /// In en, this message translates to:
  /// **'No readable text found. Choose another image or type the message.'**
  String get noOcrText;

  /// No description provided for @smsOff.
  ///
  /// In en, this message translates to:
  /// **'Incoming SMS checks unavailable in this build'**
  String get smsOff;

  /// No description provided for @smsDetail.
  ///
  /// In en, this message translates to:
  /// **'Manual checks work without SMS access. Automatic checks need an eligible Android build.'**
  String get smsDetail;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Never share your OTP.'**
  String get reminderTitle;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'Verify requests through the official app or a contact you already trust.'**
  String get reminderBody;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Scan result'**
  String get result;

  /// No description provided for @newScan.
  ///
  /// In en, this message translates to:
  /// **'Check another message'**
  String get newScan;

  /// No description provided for @whyFlagged.
  ///
  /// In en, this message translates to:
  /// **'Why this was flagged'**
  String get whyFlagged;

  /// No description provided for @linksInMessage.
  ///
  /// In en, this message translates to:
  /// **'Links in this message'**
  String get linksInMessage;

  /// No description provided for @nextSteps.
  ///
  /// In en, this message translates to:
  /// **'What you can do'**
  String get nextSteps;

  /// No description provided for @originalText.
  ///
  /// In en, this message translates to:
  /// **'Original message'**
  String get originalText;

  /// No description provided for @localChecked.
  ///
  /// In en, this message translates to:
  /// **'Message warning signs checked on this device'**
  String get localChecked;

  /// No description provided for @unknownLink.
  ///
  /// In en, this message translates to:
  /// **'Link safety is unknown.'**
  String get unknownLink;

  /// No description provided for @lowCopy.
  ///
  /// In en, this message translates to:
  /// **'No common warning signs found. This does not verify who sent the message.'**
  String get lowCopy;

  /// No description provided for @cautionCopy.
  ///
  /// In en, this message translates to:
  /// **'Some details deserve a closer look. Verify the request before replying or paying.'**
  String get cautionCopy;

  /// No description provided for @highCopy.
  ///
  /// In en, this message translates to:
  /// **'This message has strong warning signs. Pause before sharing information or money.'**
  String get highCopy;

  /// No description provided for @noWarnings.
  ///
  /// In en, this message translates to:
  /// **'No common warning signs detected'**
  String get noWarnings;

  /// No description provided for @notChecked.
  ///
  /// In en, this message translates to:
  /// **'Not checked online'**
  String get notChecked;

  /// No description provided for @notListed.
  ///
  /// In en, this message translates to:
  /// **'Not on the provider threat list; this does not prove safety'**
  String get notListed;

  /// No description provided for @linkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Online check unavailable. Try again later.'**
  String get linkUnavailable;

  /// No description provided for @knownThreat.
  ///
  /// In en, this message translates to:
  /// **'Listed as a potential threat'**
  String get knownThreat;

  /// No description provided for @fullLink.
  ///
  /// In en, this message translates to:
  /// **'Full link'**
  String get fullLink;

  /// No description provided for @checkOnline.
  ///
  /// In en, this message translates to:
  /// **'Check links online'**
  String get checkOnline;

  /// No description provided for @checkingLinks.
  ///
  /// In en, this message translates to:
  /// **'Checking links…'**
  String get checkingLinks;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @verifyAdvice.
  ///
  /// In en, this message translates to:
  /// **'Verify through the official app or website you opened yourself.'**
  String get verifyAdvice;

  /// No description provided for @secretAdvice.
  ///
  /// In en, this message translates to:
  /// **'Do not share an OTP, password, PIN, or recovery code.'**
  String get secretAdvice;

  /// No description provided for @paymentAdvice.
  ///
  /// In en, this message translates to:
  /// **'Pause the payment. Confirm the recipient through a trusted channel.'**
  String get paymentAdvice;

  /// No description provided for @clickedAdvice.
  ///
  /// In en, this message translates to:
  /// **'Already shared details? Contact your bank or e-wallet through its official app immediately.'**
  String get clickedAdvice;

  /// No description provided for @historyHeading.
  ///
  /// In en, this message translates to:
  /// **'Your checks, kept private.'**
  String get historyHeading;

  /// No description provided for @historyOff.
  ///
  /// In en, this message translates to:
  /// **'History is off'**
  String get historyOff;

  /// No description provided for @historyOffBody.
  ///
  /// In en, this message translates to:
  /// **'Messages stay in this session. Enable encrypted history for the latest 100 checks, with review access expiring after 30 days.'**
  String get historyOffBody;

  /// No description provided for @enableHistory.
  ///
  /// In en, this message translates to:
  /// **'Enable private history'**
  String get enableHistory;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No scans yet'**
  String get noHistory;

  /// No description provided for @noHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'Your saved checks will appear here. Start with a message you want to verify.'**
  String get noHistoryBody;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching scans'**
  String get noMatches;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @searchHistory.
  ///
  /// In en, this message translates to:
  /// **'Search saved messages'**
  String get searchHistory;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @allRisk.
  ///
  /// In en, this message translates to:
  /// **'All risks'**
  String get allRisk;

  /// No description provided for @allSources.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get allSources;

  /// No description provided for @allDates.
  ///
  /// In en, this message translates to:
  /// **'All dates'**
  String get allDates;

  /// No description provided for @last7.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7;

  /// No description provided for @last30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all matching'**
  String get selectAll;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelected;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete saved scans?'**
  String get deleteTitle;

  /// No description provided for @deleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes saved checks from Usisa only. It does not delete messages from your SMS app.'**
  String get deleteBody;

  /// No description provided for @clearSavedData.
  ///
  /// In en, this message translates to:
  /// **'Clear saved data'**
  String get clearSavedData;

  /// No description provided for @notSaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved. Your result is still available in this session.'**
  String get notSaved;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the change. Try again.'**
  String get saveFailed;

  /// No description provided for @learnHeading.
  ///
  /// In en, this message translates to:
  /// **'Spot the signs. Stay a step ahead.'**
  String get learnHeading;

  /// No description provided for @learnIntro.
  ///
  /// In en, this message translates to:
  /// **'Practical reminders for everyday messages in the Philippines.'**
  String get learnIntro;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy and storage'**
  String get privacy;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'Use device setting'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @saveHistory.
  ///
  /// In en, this message translates to:
  /// **'Save private history'**
  String get saveHistory;

  /// No description provided for @restoreDraft.
  ///
  /// In en, this message translates to:
  /// **'Restore my draft'**
  String get restoreDraft;

  /// No description provided for @draftDetail.
  ///
  /// In en, this message translates to:
  /// **'Restore one encrypted text draft within 24 hours. Expired files are erased while Usisa runs or on next use; a closed or stopped app cannot erase on schedule. Screenshots are never saved.'**
  String get draftDetail;

  /// No description provided for @onlineChecks.
  ///
  /// In en, this message translates to:
  /// **'Online link checks'**
  String get onlineChecks;

  /// No description provided for @onlineDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Enable online link checks?'**
  String get onlineDisclosure;

  /// No description provided for @onlineBody.
  ///
  /// In en, this message translates to:
  /// **'Full URLs, including path and query, will be sent to the Usisa gateway and Google Web Risk for this and future manual scans until disabled. Message text, sender, and images stay on your device. Background SMS checks never upload URLs.'**
  String get onlineBody;

  /// No description provided for @enableOnline.
  ///
  /// In en, this message translates to:
  /// **'Enable online checks'**
  String get enableOnline;

  /// No description provided for @localOnly.
  ///
  /// In en, this message translates to:
  /// **'Keep local only'**
  String get localOnly;

  /// No description provided for @gatewayMissing.
  ///
  /// In en, this message translates to:
  /// **'Online reputation is not configured in this build. Local warning checks still work.'**
  String get gatewayMissing;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About Usisa'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Built for messages in the Philippines. Usisa points out potential scam indicators; it cannot guarantee detection or verify every sender.'**
  String get aboutBody;

  /// No description provided for @sessionPreview.
  ///
  /// In en, this message translates to:
  /// **'Browser preview: session-only storage. Native OCR and incoming SMS need Android.'**
  String get sessionPreview;

  /// No description provided for @privateHistoryConsent.
  ///
  /// In en, this message translates to:
  /// **'Save encrypted copies of message text, links, and findings on this device (latest 100 scans). Reviews expire after 30 days. Expired files are erased while Usisa runs or on next use; a closed or stopped app cannot erase on schedule. Clear saved data erases them immediately when storage is available.'**
  String get privateHistoryConsent;

  /// No description provided for @reviewRecoveredScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Review previous screenshot'**
  String get reviewRecoveredScreenshot;

  /// No description provided for @discardRecoveredScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Discard previous screenshot'**
  String get discardRecoveredScreenshot;

  /// No description provided for @assumedHttps.
  ///
  /// In en, this message translates to:
  /// **'HTTPS was assumed because the link has no scheme. No page was opened.'**
  String get assumedHttps;

  /// No description provided for @reputationExpired.
  ///
  /// In en, this message translates to:
  /// **'Previous online result is no longer current. Check again.'**
  String get reputationExpired;

  /// No description provided for @previousThreat.
  ///
  /// In en, this message translates to:
  /// **'Previously listed as a threat.'**
  String get previousThreat;

  /// No description provided for @checkedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Last checked: {date}'**
  String checkedAtLabel(String date);

  /// No description provided for @retentionCleanupFailed.
  ///
  /// In en, this message translates to:
  /// **'Some expired data could not be erased. Try Clear saved data in Settings.'**
  String get retentionCleanupFailed;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'A second look before you act.'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Check suspicious messages and links for warning signs. Built for English, Filipino, and Taglish messages in the Philippines.'**
  String get welcomeBody;

  /// No description provided for @welcomePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Manual text checks work offline. History, cloud link checks, and incoming SMS checks are optional and start off. Usisa can miss scams; verify important requests independently.'**
  String get welcomePrivacy;

  /// No description provided for @startChecking.
  ///
  /// In en, this message translates to:
  /// **'Start checking'**
  String get startChecking;

  /// No description provided for @smsHeading.
  ///
  /// In en, this message translates to:
  /// **'Incoming SMS checks'**
  String get smsHeading;

  /// No description provided for @smsDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Enable incoming SMS checks?'**
  String get smsDisclosure;

  /// No description provided for @smsDisclosureBody.
  ///
  /// In en, this message translates to:
  /// **'Usisa reads only new SMS received while this feature is enabled. It checks them locally without uploading messages or reading your inbox or other apps. Up to 20 encrypted reviews expire after 15 minutes; Android may delay file cleanup. Android may delay or stop checks; force-stopping Usisa prevents them. Detection can miss scams.'**
  String get smsDisclosureBody;

  /// No description provided for @enableSmsChecks.
  ///
  /// In en, this message translates to:
  /// **'Enable SMS checks'**
  String get enableSmsChecks;

  /// No description provided for @smsPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'SMS permission needed'**
  String get smsPermissionNeeded;

  /// No description provided for @smsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Incoming SMS checks enabled'**
  String get smsEnabled;

  /// No description provided for @smsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Incoming SMS checks off'**
  String get smsDisabled;

  /// No description provided for @smsLimits.
  ///
  /// In en, this message translates to:
  /// **'Local checks only. Android may delay checks; coverage is not guaranteed. Low-risk messages stay quiet.'**
  String get smsLimits;

  /// No description provided for @smsAlertsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. Open recent SMS reviews here. You can also enable notifications in Android app settings.'**
  String get smsAlertsOff;

  /// No description provided for @enableSmsAlerts.
  ///
  /// In en, this message translates to:
  /// **'Enable review notifications'**
  String get enableSmsAlerts;

  /// No description provided for @smsDegraded.
  ///
  /// In en, this message translates to:
  /// **'Some messages could not be checked. Coverage is incomplete. Try turning SMS checks off and on again.'**
  String get smsDegraded;

  /// No description provided for @manageSms.
  ///
  /// In en, this message translates to:
  /// **'Manage SMS checks'**
  String get manageSms;

  /// No description provided for @recentSms.
  ///
  /// In en, this message translates to:
  /// **'Recent SMS reviews'**
  String get recentSms;

  /// No description provided for @smsTemporary.
  ///
  /// In en, this message translates to:
  /// **'Temporary encrypted reviews expire 15 minutes after receipt. Low-risk messages are removed after checking.'**
  String get smsTemporary;

  /// No description provided for @smsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No temporary SMS reviews. Messages may have expired, stayed quiet, or not been received while checks were enabled.'**
  String get smsEmpty;

  /// No description provided for @smsMissing.
  ///
  /// In en, this message translates to:
  /// **'This SMS review is unavailable. It may have expired, been erased, or checks were turned off. Copy the message into Text to check it again.'**
  String get smsMissing;

  /// No description provided for @smsPending.
  ///
  /// In en, this message translates to:
  /// **'This message has no completed check yet. Try again shortly, or copy it into Text for a manual check.'**
  String get smsPending;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @riskLabel.
  ///
  /// In en, this message translates to:
  /// **'{risk, select, high{High risk} caution{Caution} other{Low risk}}'**
  String riskLabel(String risk);

  /// No description provided for @sourceLabel.
  ///
  /// In en, this message translates to:
  /// **'{source, select, link{Link} screenshot{Screenshot} sms{SMS} other{Text}}'**
  String sourceLabel(String source);

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'{code, select, emptyInput{Enter a message or link first.} textTooLong{Keep within 10,000 characters. Nothing was cut.} invalidUrl{Enter one complete HTTP or HTTPS link. Use Text for multiple links.} urlTooLong{A link exceeds 2,048 characters. Edit it first.} tooManyLinks{Check up to 10 distinct links at a time.} imageTooLarge{Choose an image under 20 MB and 20 megapixels.} other{The check could not finish. Your input is still here. Try again.}}'**
  String errorMessage(String code);

  /// No description provided for @findingTitle.
  ///
  /// In en, this message translates to:
  /// **'{code, select, codeRequest{Asks for a security secret} paymentRequest{Requests a payment} urgency{Pressures you to act} prize{Promises a prize} advanceFee{Asks for an upfront fee} deceptiveHost{Brand name on a different domain} userInfo{Misleading link format} httpLink{Unencrypted link} ipHost{Numeric or IP address} shortLink{Shortened destination} unusualHost{Unusual domain characters} invalidLink{Link could not be assessed} other{Warning sign}}'**
  String findingTitle(String code);

  /// No description provided for @findingBody.
  ///
  /// In en, this message translates to:
  /// **'{code, select, codeRequest{Verify independently before sharing a code or password.} paymentRequest{Confirm the recipient and reason before sending money.} urgency{Deadlines and account threats can discourage careful checking.} prize{Verify through an official channel you opened independently.} advanceFee{Verify the purpose and recipient of any upfront fee.} deceptiveHost{This host contains a brand but does not match its reviewed official domain.} userInfo{Text before the @ is not the destination. The real host is shown.} httpLink{This uses HTTP. HTTPS also does not guarantee legitimacy.} ipHost{The link uses an IP address rather than an ordinary domain.} shortLink{The final destination is hidden. Usisa has not expanded this link.} unusualHost{Encoded or mixed-script characters need review; they do not prove fraud.} invalidLink{The format is malformed or unsupported. No safety verdict is available.} other{Verify the request before acting.}}'**
  String findingBody(String code);
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
