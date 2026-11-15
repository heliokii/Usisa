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

  /// No description provided for @analysisMode.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysisMode;

  /// No description provided for @onDevice.
  ///
  /// In en, this message translates to:
  /// **'On-device'**
  String get onDevice;

  /// No description provided for @aiAssisted.
  ///
  /// In en, this message translates to:
  /// **'AI assisted'**
  String get aiAssisted;

  /// No description provided for @aiManualOnly.
  ///
  /// In en, this message translates to:
  /// **'AI sends text only after you review and confirm.'**
  String get aiManualOnly;

  /// No description provided for @aiReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review for AI check'**
  String get aiReviewTitle;

  /// No description provided for @aiDisclosure.
  ///
  /// In en, this message translates to:
  /// **'This exact text goes to Usisa’s server and Groq for AI review. Remove codes or personal details you do not want to share. Names, numbers, and links are included. Screenshots and sender details stay on your device. Groq may keep requests for reliability or abuse monitoring, based on account settings. AI can be wrong; it does not verify senders or open links.'**
  String get aiDisclosure;

  /// No description provided for @aiTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Text to send'**
  String get aiTextLabel;

  /// No description provided for @sendAi.
  ///
  /// In en, this message translates to:
  /// **'Send this text for AI check'**
  String get sendAi;

  /// No description provided for @keepOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Keep on device'**
  String get keepOnDevice;

  /// No description provided for @aiAssessment.
  ///
  /// In en, this message translates to:
  /// **'AI assessment'**
  String get aiAssessment;

  /// No description provided for @onDeviceFindings.
  ///
  /// In en, this message translates to:
  /// **'On-device findings'**
  String get onDeviceFindings;

  /// No description provided for @aiChecking.
  ///
  /// In en, this message translates to:
  /// **'On-device checks complete. AI is checking…'**
  String get aiChecking;

  /// No description provided for @aiUnknown.
  ///
  /// In en, this message translates to:
  /// **'AI could not assess this message. Use local findings and verify it yourself.'**
  String get aiUnknown;

  /// No description provided for @aiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Local checks are done, but AI is unavailable. Your text is still here. Review it and try again.'**
  String get aiUnavailable;

  /// No description provided for @aiCancelled.
  ///
  /// In en, this message translates to:
  /// **'AI check cancelled. Local findings remain. A sent request may still be processed.'**
  String get aiCancelled;

  /// No description provided for @aiNotRequested.
  ///
  /// In en, this message translates to:
  /// **'No AI check yet. Review the text to add one.'**
  String get aiNotRequested;

  /// No description provided for @aiDisagreement.
  ///
  /// In en, this message translates to:
  /// **'Results differ. Keep the stronger warning; neither proves the message safe.'**
  String get aiDisagreement;

  /// No description provided for @aiReviewed.
  ///
  /// In en, this message translates to:
  /// **'AI used the text you reviewed.'**
  String get aiReviewed;

  /// No description provided for @aiRetry.
  ///
  /// In en, this message translates to:
  /// **'Review and retry AI'**
  String get aiRetry;

  /// No description provided for @aiLimitations.
  ///
  /// In en, this message translates to:
  /// **'AI can miss scams or flag safe messages. Quotes show its input, not proof.'**
  String get aiLimitations;

  /// No description provided for @aiSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'AI can check text, links, and screenshot text you approve. Confirm each upload to Usisa and Groq. Auto SMS stays on-device. Link-check consent does not enable AI.'**
  String get aiSettingsBody;

  /// No description provided for @aiFindingTitle.
  ///
  /// In en, this message translates to:
  /// **'{code, select, credential_request{Asks for a security secret} payment_request{Requests a payment} urgency{Pressures you to act} impersonation{Possible impersonation} prize{Promises a prize} suspicious_link{Questionable link context} other{AI warning sign}}'**
  String aiFindingTitle(String code);

  /// No description provided for @aiAdvice.
  ///
  /// In en, this message translates to:
  /// **'{code, select, dont_share_secrets{Do not share OTPs, passwords or PINs with anyone requesting them.} pause_payment{Pause the payment. Confirm the recipient and reason independently.} contact_provider_if_shared{If you already shared details, contact your provider through its official app or your own trusted records.} other{Verify through the official app or a trusted channel you opened yourself.}}'**
  String aiAdvice(String code);

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
  /// **'Treat code requests with care, even from claimed support. Real OTP messages may warn you not to share the code. Verify through the official app.'**
  String get learnOtpBody;

  /// No description provided for @learnBankTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank & Wallet Scams'**
  String get learnBankTitle;

  /// No description provided for @learnBankBody.
  ///
  /// In en, this message translates to:
  /// **'An account suspension threat can pressure you to tap a link. Sender names can be spoofed. Open your bank or e-wallet app directly to check your account; do not use the message\'s link as proof.'**
  String get learnBankBody;

  /// No description provided for @learnBankSummary.
  ///
  /// In en, this message translates to:
  /// **'Fake messages from BPI,\nGCash, Maya, etc.'**
  String get learnBankSummary;

  /// No description provided for @learnGovernmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Government Impersonation'**
  String get learnGovernmentTitle;

  /// No description provided for @learnGovernmentBody.
  ///
  /// In en, this message translates to:
  /// **'Scammers may pose as SSS, PhilHealth, Pag-IBIG, or another agency. Verify unexpected aid, fines, or registration through an official service you open yourself. A logo proves nothing.'**
  String get learnGovernmentBody;

  /// No description provided for @learnGovernmentSummary.
  ///
  /// In en, this message translates to:
  /// **'Scams pretending to be from\nSSS, PAG-IBIG, PhilPost, and more.'**
  String get learnGovernmentSummary;

  /// No description provided for @learnDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Unexpected delivery fees'**
  String get learnDeliveryTitle;

  /// No description provided for @learnDeliveryBody.
  ///
  /// In en, this message translates to:
  /// **'Fake redelivery fees can lead to pages that steal card or account details. Check orders in your courier app. Short links hide destinations; Usisa does not expand them.'**
  String get learnDeliveryBody;

  /// No description provided for @learnSellerTitle.
  ///
  /// In en, this message translates to:
  /// **'Online Selling Scams'**
  String get learnSellerTitle;

  /// No description provided for @learnSellerBody.
  ///
  /// In en, this message translates to:
  /// **'Be cautious about pressure to move a conversation or payment outside a marketplace\'s normal process. Confirm the seller, item, recipient and payment purpose through trusted records before sending money.'**
  String get learnSellerBody;

  /// No description provided for @learnSellerSummary.
  ///
  /// In en, this message translates to:
  /// **'Fake sellers, payment proofs,\nand delivery tricks.'**
  String get learnSellerSummary;

  /// No description provided for @learnRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'If you already shared details'**
  String get learnRecoveryTitle;

  /// No description provided for @learnRecoveryBody.
  ///
  /// In en, this message translates to:
  /// **'Stop payments. Contact your bank or e-wallet through its official app or a trusted contact. Change exposed passwords; keep evidence private. Never share another OTP with a recovery helper.'**
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

  /// No description provided for @messageScanPrompt.
  ///
  /// In en, this message translates to:
  /// **'Paste or type a message to scan'**
  String get messageScanPrompt;

  /// No description provided for @messageScanSupport.
  ///
  /// In en, this message translates to:
  /// **'We\'ll check for suspicious links, scams, and harmful content.'**
  String get messageScanSupport;

  /// No description provided for @scanHeading.
  ///
  /// In en, this message translates to:
  /// **'Check before you tap.'**
  String get scanHeading;

  /// No description provided for @scanIntro.
  ///
  /// In en, this message translates to:
  /// **'Check a message or link before you act.'**
  String get scanIntro;

  /// No description provided for @localPrivate.
  ///
  /// In en, this message translates to:
  /// **'Checks stay on your device by default.'**
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

  /// No description provided for @screenshotHeading.
  ///
  /// In en, this message translates to:
  /// **'Scan a screenshot'**
  String get screenshotHeading;

  /// No description provided for @screenshotSelected.
  ///
  /// In en, this message translates to:
  /// **'Screenshot selected'**
  String get screenshotSelected;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change image'**
  String get changeImage;

  /// No description provided for @screenshotSupported.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG, JPEG, or WEBP · Up to 10 MB'**
  String get screenshotSupported;

  /// No description provided for @linkCheckPrompt.
  ///
  /// In en, this message translates to:
  /// **'Check a link’s safety'**
  String get linkCheckPrompt;

  /// No description provided for @linkCheckSupport.
  ///
  /// In en, this message translates to:
  /// **'See known risk signs before opening a URL.'**
  String get linkCheckSupport;

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

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

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

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @browseFiles.
  ///
  /// In en, this message translates to:
  /// **'Browse files'**
  String get browseFiles;

  /// No description provided for @screenshotIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose a message screenshot. Review its text before scanning.'**
  String get screenshotIntro;

  /// No description provided for @ocrNativeOnly.
  ///
  /// In en, this message translates to:
  /// **'OCR works in the Android and iOS app. You can paste text here.'**
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
  /// **'Check names, numbers, and links. OCR can misread them.'**
  String get ocrNotice;

  /// No description provided for @previewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Preview unavailable. Review and edit the extracted text anyway.'**
  String get previewUnavailable;

  /// No description provided for @checkThisText.
  ///
  /// In en, this message translates to:
  /// **'Check this text'**
  String get checkThisText;

  /// No description provided for @noOcrText.
  ///
  /// In en, this message translates to:
  /// **'No text found. Choose another image or type the message.'**
  String get noOcrText;

  /// No description provided for @smsOff.
  ///
  /// In en, this message translates to:
  /// **'Auto SMS is unavailable.'**
  String get smsOff;

  /// No description provided for @smsDetail.
  ///
  /// In en, this message translates to:
  /// **'Manual scans work without SMS access. Auto checks need a supported Android phone.'**
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

  /// No description provided for @checkAnotherLink.
  ///
  /// In en, this message translates to:
  /// **'Check another link'**
  String get checkAnotherLink;

  /// No description provided for @checkAnotherScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Check another screenshot'**
  String get checkAnotherScreenshot;

  /// No description provided for @viewFullImage.
  ///
  /// In en, this message translates to:
  /// **'View full image'**
  String get viewFullImage;

  /// No description provided for @checkAiShort.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get checkAiShort;

  /// No description provided for @linkDomainLabel.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get linkDomainLabel;

  /// No description provided for @linkSimilarityLabel.
  ///
  /// In en, this message translates to:
  /// **'Similarity'**
  String get linkSimilarityLabel;

  /// No description provided for @linkStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get linkStatusLabel;

  /// No description provided for @resultLinkCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 link found} other{{count} links found}}'**
  String resultLinkCount(int count);

  /// No description provided for @resultMoreFindings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{See 1 more sign} other{See {count} more signs}}'**
  String resultMoreFindings(int count);

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
  /// **'No common warning signs found. The sender is not verified.'**
  String get lowCopy;

  /// No description provided for @cautionCopy.
  ///
  /// In en, this message translates to:
  /// **'Some details need a closer look. Verify before replying or paying.'**
  String get cautionCopy;

  /// No description provided for @highCopy.
  ///
  /// In en, this message translates to:
  /// **'Strong warning signs found. Pause before sharing money or details.'**
  String get highCopy;

  /// No description provided for @resultRiskLabel.
  ///
  /// In en, this message translates to:
  /// **'{risk, select, low{Safe} caution{Need Review} other{High Risk}}'**
  String resultRiskLabel(String risk);

  /// No description provided for @unknownStatus.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownStatus;

  /// No description provided for @analysisSummary.
  ///
  /// In en, this message translates to:
  /// **'Analysis Summary'**
  String get analysisSummary;

  /// No description provided for @detectedSigns.
  ///
  /// In en, this message translates to:
  /// **'Detected Signs'**
  String get detectedSigns;

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
  /// **'Not on the threat list. That does not prove it is safe.'**
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
  /// **'Already shared details? Contact your bank or e-wallet through its official app now.'**
  String get clickedAdvice;

  /// No description provided for @historyHeading.
  ///
  /// In en, this message translates to:
  /// **'Your checks, kept private.'**
  String get historyHeading;

  /// No description provided for @historyAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyAll;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @historyOff.
  ///
  /// In en, this message translates to:
  /// **'History is off'**
  String get historyOff;

  /// No description provided for @historyOffBody.
  ///
  /// In en, this message translates to:
  /// **'Save up to 100 encrypted scans for 30 days.'**
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
  /// **'Saved checks appear here. Start with a message you want to verify.'**
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
  /// **'This removes the saved check from Usisa, not the SMS in your messaging app.'**
  String get deleteBody;

  /// No description provided for @clearSavedData.
  ///
  /// In en, this message translates to:
  /// **'Clear saved data'**
  String get clearSavedData;

  /// No description provided for @notSaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved. This result stays in your session.'**
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
  /// **'Encrypted text draft for 24 hours. Screenshots are not saved.'**
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

  /// No description provided for @onlineSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Check full URLs with Google Safe Browsing.'**
  String get onlineSettingsDescription;

  /// No description provided for @onlineBody.
  ///
  /// In en, this message translates to:
  /// **'While enabled, manual link checks send full URLs, including paths and queries, to the Usisa gateway and Google Safe Browsing. Messages, senders, and images stay on-device. SMS checks never upload URLs. Google may miss threats or flag safe sites. Online advisories expire. History saves local findings and last-check details, not online verdicts.'**
  String get onlineBody;

  /// No description provided for @googleAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Advisory provided by Google'**
  String get googleAdvisory;

  /// No description provided for @advisoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not open the help page. Your scan is still available.'**
  String get advisoryUnavailable;

  /// No description provided for @phishingHelp.
  ///
  /// In en, this message translates to:
  /// **'Learn about phishing'**
  String get phishingHelp;

  /// No description provided for @malwareHelp.
  ///
  /// In en, this message translates to:
  /// **'Learn about malware'**
  String get malwareHelp;

  /// No description provided for @unwantedHelp.
  ///
  /// In en, this message translates to:
  /// **'Learn about unwanted software'**
  String get unwantedHelp;

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
  /// **'Made for messages in the Philippines. Usisa flags possible scam signs; it can miss scams and cannot verify every sender.'**
  String get aboutBody;

  /// No description provided for @sessionPreview.
  ///
  /// In en, this message translates to:
  /// **'Browser preview stores data for this session only. OCR and incoming SMS need Android.'**
  String get sessionPreview;

  /// No description provided for @privateHistoryConsent.
  ///
  /// In en, this message translates to:
  /// **'Save encrypted message text, links, and findings on this device (latest 100 scans). Reviews expire after 30 days. Usisa deletes expired files while it runs or next time you open it. A stopped app cannot delete them on schedule. Clear saved data deletes them when storage is available.'**
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
  /// **'Check suspicious messages and links for warning signs. Built for English, Filipino, and Taglish in the Philippines.'**
  String get welcomeBody;

  /// No description provided for @welcomePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Manual text checks work offline. History, online link checks, and incoming SMS are optional and off by default. Usisa can miss scams. Verify important requests independently.'**
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
  /// **'Checks new SMS on this device only. No inbox access or message uploads. Up to 20 encrypted reviews expire in 15 minutes. Android may delay checks; force-stop stops checks. Some scams may be missed.'**
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
  /// **'Checks stay on-device. Android may delay them; coverage is not guaranteed. Low-risk messages stay quiet.'**
  String get smsLimits;

  /// No description provided for @smsAlertsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. Recent reviews stay here. Enable alerts in Android settings.'**
  String get smsAlertsOff;

  /// No description provided for @enableSmsAlerts.
  ///
  /// In en, this message translates to:
  /// **'Enable review notifications'**
  String get enableSmsAlerts;

  /// No description provided for @smsDegraded.
  ///
  /// In en, this message translates to:
  /// **'Some messages were not checked. Turn SMS checks off, then on again.'**
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
  /// **'Temporary encrypted reviews expire 15 minutes after receipt. Low-risk messages are deleted after checking.'**
  String get smsTemporary;

  /// No description provided for @smsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No temporary reviews. They may have expired, been low-risk, or arrived while checks were off.'**
  String get smsEmpty;

  /// No description provided for @smsMissing.
  ///
  /// In en, this message translates to:
  /// **'Review unavailable. It may have expired, been deleted, or SMS checks were off. Copy the message into a manual scan.'**
  String get smsMissing;

  /// No description provided for @smsPending.
  ///
  /// In en, this message translates to:
  /// **'No check completed yet. Try again soon or copy the message into a manual scan.'**
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

  /// No description provided for @homeHeading.
  ///
  /// In en, this message translates to:
  /// **'Stay one step ahead of scams.'**
  String get homeHeading;

  /// No description provided for @homeBrand.
  ///
  /// In en, this message translates to:
  /// **'Usisa'**
  String get homeBrand;

  /// No description provided for @homeBody.
  ///
  /// In en, this message translates to:
  /// **'Check messages, links, and screenshots for scam signs.'**
  String get homeBody;

  /// No description provided for @scanMessageCard.
  ///
  /// In en, this message translates to:
  /// **'Scan Message'**
  String get scanMessageCard;

  /// No description provided for @scanMessageDescription.
  ///
  /// In en, this message translates to:
  /// **'Paste or type a message'**
  String get scanMessageDescription;

  /// No description provided for @checkLinkCard.
  ///
  /// In en, this message translates to:
  /// **'Check a Link'**
  String get checkLinkCard;

  /// No description provided for @checkLinkDescription.
  ///
  /// In en, this message translates to:
  /// **'Check a URL before opening.'**
  String get checkLinkDescription;

  /// No description provided for @scanScreenshotCard.
  ///
  /// In en, this message translates to:
  /// **'Scan Screenshot'**
  String get scanScreenshotCard;

  /// No description provided for @scanScreenshotDescription.
  ///
  /// In en, this message translates to:
  /// **'Read message text from a screenshot.'**
  String get scanScreenshotDescription;

  /// No description provided for @aiScan.
  ///
  /// In en, this message translates to:
  /// **'AI Scan'**
  String get aiScan;

  /// No description provided for @aiBeta.
  ///
  /// In en, this message translates to:
  /// **'Beta'**
  String get aiBeta;

  /// No description provided for @aiHomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Get AI help with scam checks.'**
  String get aiHomeDescription;

  /// No description provided for @homeAiBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get homeAiBadge;

  /// No description provided for @autoSmsCard.
  ///
  /// In en, this message translates to:
  /// **'Auto SMS Detection'**
  String get autoSmsCard;

  /// No description provided for @autoSmsDescription.
  ///
  /// In en, this message translates to:
  /// **'Check incoming SMS for scams.'**
  String get autoSmsDescription;

  /// No description provided for @aiIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Scam Analysis'**
  String get aiIntroTitle;

  /// No description provided for @aiIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Check a message, link, or screenshot. AI explains possible risks and next steps.'**
  String get aiIntroBody;

  /// No description provided for @aiMultiInput.
  ///
  /// In en, this message translates to:
  /// **'Multi-input'**
  String get aiMultiInput;

  /// No description provided for @aiMultiInputBody.
  ///
  /// In en, this message translates to:
  /// **'Text, links, or screenshots with OCR'**
  String get aiMultiInputBody;

  /// No description provided for @aiContextAware.
  ///
  /// In en, this message translates to:
  /// **'Context-aware'**
  String get aiContextAware;

  /// No description provided for @aiContextAwareBody.
  ///
  /// In en, this message translates to:
  /// **'Looks for common scam patterns in PH'**
  String get aiContextAwareBody;

  /// No description provided for @aiActionable.
  ///
  /// In en, this message translates to:
  /// **'Actionable results'**
  String get aiActionable;

  /// No description provided for @aiActionableBody.
  ///
  /// In en, this message translates to:
  /// **'Risk level, explanations, and next steps'**
  String get aiActionableBody;

  /// No description provided for @startAiScan.
  ///
  /// In en, this message translates to:
  /// **'Start AI Scan'**
  String get startAiScan;

  /// No description provided for @aiInputQuestion.
  ///
  /// In en, this message translates to:
  /// **'What do you want to check?'**
  String get aiInputQuestion;

  /// No description provided for @aiTextOption.
  ///
  /// In en, this message translates to:
  /// **'Text / Message'**
  String get aiTextOption;

  /// No description provided for @aiTextOptionBody.
  ///
  /// In en, this message translates to:
  /// **'Paste or type a suspicious message'**
  String get aiTextOptionBody;

  /// No description provided for @aiLinkOption.
  ///
  /// In en, this message translates to:
  /// **'URL / Link'**
  String get aiLinkOption;

  /// No description provided for @aiLinkOptionBody.
  ///
  /// In en, this message translates to:
  /// **'Check a link for scam signs.'**
  String get aiLinkOptionBody;

  /// No description provided for @aiScreenshotOption.
  ///
  /// In en, this message translates to:
  /// **'Screenshot / Image'**
  String get aiScreenshotOption;

  /// No description provided for @aiScreenshotOptionBody.
  ///
  /// In en, this message translates to:
  /// **'Read and review text with OCR.'**
  String get aiScreenshotOptionBody;

  /// No description provided for @aiProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyzing with AI…'**
  String get aiProgressTitle;

  /// No description provided for @aiStageReviewed.
  ///
  /// In en, this message translates to:
  /// **'Text review confirmed'**
  String get aiStageReviewed;

  /// No description provided for @aiStageLocal.
  ///
  /// In en, this message translates to:
  /// **'On-device checks complete'**
  String get aiStageLocal;

  /// No description provided for @aiStageRequest.
  ///
  /// In en, this message translates to:
  /// **'Sending text for an AI check…'**
  String get aiStageRequest;

  /// No description provided for @aiStageResult.
  ///
  /// In en, this message translates to:
  /// **'Preparing your result'**
  String get aiStageResult;

  /// No description provided for @smsDetectionTitle.
  ///
  /// In en, this message translates to:
  /// **'SMS Detection'**
  String get smsDetectionTitle;

  /// No description provided for @smsDetectionBody.
  ///
  /// In en, this message translates to:
  /// **'Checks new SMS for scam signs and alerts you to suspicious messages.'**
  String get smsDetectionBody;

  /// No description provided for @smsRecentDetections.
  ///
  /// In en, this message translates to:
  /// **'Recent SMS checks'**
  String get smsRecentDetections;

  /// No description provided for @warningSigns.
  ///
  /// In en, this message translates to:
  /// **'Detected Warning Signs'**
  String get warningSigns;

  /// No description provided for @safetyRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Safety Recommendations'**
  String get safetyRecommendations;

  /// No description provided for @linkWhyRisky.
  ///
  /// In en, this message translates to:
  /// **'Why is it risky?'**
  String get linkWhyRisky;

  /// No description provided for @learnScamTips.
  ///
  /// In en, this message translates to:
  /// **'Scam Safety Tips'**
  String get learnScamTips;

  /// No description provided for @learnScamTipsBody.
  ///
  /// In en, this message translates to:
  /// **'Simple ways to avoid common\nscams in the Philippines.'**
  String get learnScamTipsBody;

  /// No description provided for @learnCommonScams.
  ///
  /// In en, this message translates to:
  /// **'Common Scams in PH'**
  String get learnCommonScams;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @onboardingSecondTitle.
  ///
  /// In en, this message translates to:
  /// **'See why a message was flagged.'**
  String get onboardingSecondTitle;

  /// No description provided for @onboardingSecondBody.
  ///
  /// In en, this message translates to:
  /// **'See which words, links, and requests need a closer look.'**
  String get onboardingSecondBody;

  /// No description provided for @onboardingThirdTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what stays on your device.'**
  String get onboardingThirdTitle;

  /// No description provided for @onboardingThirdBody.
  ///
  /// In en, this message translates to:
  /// **'Manual checks stay local. AI and online link checks need your review and consent.'**
  String get onboardingThirdBody;

  /// No description provided for @linkCheckerTitle.
  ///
  /// In en, this message translates to:
  /// **'Link Checker'**
  String get linkCheckerTitle;

  /// No description provided for @aiScanResult.
  ///
  /// In en, this message translates to:
  /// **'AI Scan Result'**
  String get aiScanResult;

  /// No description provided for @learnStaySafeTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn & Stay Safe'**
  String get learnStaySafeTitle;

  /// No description provided for @detection.
  ///
  /// In en, this message translates to:
  /// **'Detection'**
  String get detection;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @aiScanToggleBody.
  ///
  /// In en, this message translates to:
  /// **'Review before AI checks text.'**
  String get aiScanToggleBody;

  /// No description provided for @smsNotificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'SMS notifications are enabled.'**
  String get smsNotificationsEnabled;

  /// No description provided for @smsRecentTab.
  ///
  /// In en, this message translates to:
  /// **'Recent ({count})'**
  String smsRecentTab(int count);

  /// No description provided for @smsFlaggedTab.
  ///
  /// In en, this message translates to:
  /// **'Flagged ({count})'**
  String smsFlaggedTab(int count);

  /// No description provided for @smsFlaggedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No flagged messages in recent SMS checks.'**
  String get smsFlaggedEmpty;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;
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
