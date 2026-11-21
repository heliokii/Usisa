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

  /// No description provided for @smsCardChecked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 text checked today} other{{count} texts checked today}}'**
  String smsCardChecked(int count);

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

  /// Title for an AI warning sign; codes match server/ai_schema.mjs warningCodes.
  ///
  /// In en, this message translates to:
  /// **'{code, select, credential_request{Asks for a security secret} payment_request{Requests a payment} urgency{Pressures you to act} impersonation{Possible impersonation} prize{Promises a prize} suspicious_link{Questionable link context} gambling_ad{Gambling ad} other{AI warning sign}}'**
  String aiFindingTitle(String code);

  /// No description provided for @pasteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the text message here'**
  String get pasteHint;

  /// No description provided for @checkButton.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get checkButton;

  /// No description provided for @screenshotIntro.
  ///
  /// In en, this message translates to:
  /// **'Pick a screenshot of the message. We\'ll read the text for you.'**
  String get screenshotIntro;

  /// No description provided for @screenshotChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a screenshot'**
  String get screenshotChoose;

  /// No description provided for @screenshotReview.
  ///
  /// In en, this message translates to:
  /// **'Check the text we read and fix any mistakes.'**
  String get screenshotReview;

  /// No description provided for @screenshotNoText.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read any text in this picture. Try a clearer screenshot.'**
  String get screenshotNoText;

  /// The Verdict word; values match Verdict in lib/features/check/check.dart.
  ///
  /// In en, this message translates to:
  /// **'{verdict, select, looksSafe{Looks safe} beCareful{Be careful} dangerous{Dangerous} other{Couldn\'t check}}'**
  String verdictWord(String verdict);

  /// One plain sentence telling the person what to do next.
  ///
  /// In en, this message translates to:
  /// **'{verdict, select, looksSafe{Nothing suspicious found. Still, never share your OTP or PIN with anyone.} beCareful{Don\'t tap links or send money until you\'re sure who sent this.} dangerous{Don\'t tap the link, don\'t reply, and don\'t send money.} other{We couldn\'t check this fully. Don\'t open any link or enter any details until you\'re sure who sent it.}}'**
  String verdictAction(String verdict);

  /// No description provided for @verdictWhy.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get verdictWhy;

  /// No description provided for @checkedOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Checked on your phone'**
  String get checkedOnPhone;

  /// No description provided for @youChecked.
  ///
  /// In en, this message translates to:
  /// **'You checked'**
  String get youChecked;

  /// One reason on the verdict screen; codes come from decideVerdict and server/ai_schema.mjs.
  ///
  /// In en, this message translates to:
  /// **'{code, select, no_signs{We found no warning signs} otp_with_link{It asks for your OTP or password and has a link} lookalike_domain{The link pretends to be a known brand\'s website} prize_claim{It says you won a prize you have to claim} urgency{It rushes you to act quickly} gambling_ad{This is an unsolicited gambling ad} flagged_link{Google lists this link as unsafe} shortener_blocked{The link shortener has blocked this link} opens_app{The link opens an app instead of a website} unresolved_link{We couldn\'t see where the link goes} harmless_promo{This looks like an ordinary promo} brand_mention{It mentions a bank, e-wallet or government office} family_money{It asks for money or load, which is normal between family} credential_request{It asks for a password, PIN or code} payment_request{It asks you to pay or send money} impersonation{It may be pretending to be someone else} prize{It promises a prize} suspicious_link{The link looks suspicious} other{We found another warning sign}}'**
  String reason(String code);

  /// No description provided for @linkHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the link here'**
  String get linkHint;

  /// The Real destination of a checked link after all redirects.
  ///
  /// In en, this message translates to:
  /// **'Really goes to {destination}'**
  String reallyGoesTo(String destination);

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Check links online?'**
  String get consentTitle;

  /// No description provided for @consentBody.
  ///
  /// In en, this message translates to:
  /// **'To see where a link really goes and whether Google lists it as unsafe, Usisa sends the link to its checking service. If you use AI scan, the message text is sent to an AI service too.'**
  String get consentBody;

  /// No description provided for @consentDecline.
  ///
  /// In en, this message translates to:
  /// **'If you say no, Usisa checks everything on your phone only. It can\'t see where links really go, so it may miss some scams.'**
  String get consentDecline;

  /// No description provided for @consentLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in Settings.'**
  String get consentLater;

  /// No description provided for @consentAllow.
  ///
  /// In en, this message translates to:
  /// **'Yes, check online'**
  String get consentAllow;

  /// No description provided for @consentDeny.
  ///
  /// In en, this message translates to:
  /// **'No, phone only'**
  String get consentDeny;

  /// No description provided for @historySavedOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Saved only on this phone'**
  String get historySavedOnPhone;

  /// No description provided for @historySaveSwitch.
  ///
  /// In en, this message translates to:
  /// **'Save my checks'**
  String get historySaveSwitch;

  /// No description provided for @historySaveNote.
  ///
  /// In en, this message translates to:
  /// **'Turning this off also clears your History.'**
  String get historySaveNote;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved checks yet.'**
  String get historyEmpty;

  /// No description provided for @historyOff.
  ///
  /// In en, this message translates to:
  /// **'Saving is off.'**
  String get historyOff;

  /// No description provided for @historyClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get historyClearAll;

  /// No description provided for @historyClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all History?'**
  String get historyClearTitle;

  /// No description provided for @historyClearBody.
  ///
  /// In en, this message translates to:
  /// **'This removes every saved check from this phone. It can\'t be undone.'**
  String get historyClearBody;

  /// No description provided for @historyDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get historyDelete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @fromYourTexts.
  ///
  /// In en, this message translates to:
  /// **'From your texts'**
  String get fromYourTexts;

  /// Label on a reopened History entry; date is the date and time of the Check.
  ///
  /// In en, this message translates to:
  /// **'Checked on {date}'**
  String checkedOnDate(String date);

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @askAiLookCloser.
  ///
  /// In en, this message translates to:
  /// **'Ask AI to look closer'**
  String get askAiLookCloser;

  /// No description provided for @aiScanIntro.
  ///
  /// In en, this message translates to:
  /// **'What do you want the AI to look at?'**
  String get aiScanIntro;

  /// No description provided for @aiScanMessage.
  ///
  /// In en, this message translates to:
  /// **'A message'**
  String get aiScanMessage;

  /// No description provided for @aiScanLink.
  ///
  /// In en, this message translates to:
  /// **'A link'**
  String get aiScanLink;

  /// No description provided for @aiScanScreenshot.
  ///
  /// In en, this message translates to:
  /// **'A screenshot'**
  String get aiScanScreenshot;

  /// Label on an AI scan verdict when the AI gave no answer; the verdict comes from the phone and link checks.
  ///
  /// In en, this message translates to:
  /// **'AI couldn\'t look at this right now'**
  String get aiUnavailable;

  /// No description provided for @sendToFamily.
  ///
  /// In en, this message translates to:
  /// **'Send to family'**
  String get sendToFamily;

  /// No description provided for @readAloud.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get readAloud;

  /// No description provided for @readAloudNoFilipino.
  ///
  /// In en, this message translates to:
  /// **'There\'s no Filipino voice on this phone, so it\'s reading in English.'**
  String get readAloudNoFilipino;

  /// No description provided for @readAloudUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Read aloud isn\'t available on this phone.'**
  String get readAloudUnavailable;

  /// First line of the Send to family message; verdict is the localized Verdict word.
  ///
  /// In en, this message translates to:
  /// **'I checked a message with Usisa. It says: {verdict}'**
  String shareIntro(String verdict);

  /// No description provided for @settingsDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get settingsDisplay;

  /// No description provided for @settingsTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsTextSize;

  /// No description provided for @textSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textSizeNormal;

  /// No description provided for @textSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// No description provided for @textSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get textSizeExtraLarge;

  /// No description provided for @settingsTextSizeNote.
  ///
  /// In en, this message translates to:
  /// **'This adds to your phone\'s own text size.'**
  String get settingsTextSizeNote;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFilipino.
  ///
  /// In en, this message translates to:
  /// **'Filipino'**
  String get languageFilipino;

  /// No description provided for @settingsProtection.
  ///
  /// In en, this message translates to:
  /// **'Protection'**
  String get settingsProtection;

  /// No description provided for @settingsOnline.
  ///
  /// In en, this message translates to:
  /// **'Online checks'**
  String get settingsOnline;

  /// No description provided for @settingsOnlineSwitch.
  ///
  /// In en, this message translates to:
  /// **'Check links and use AI online'**
  String get settingsOnlineSwitch;

  /// No description provided for @settingsOnlineOn.
  ///
  /// In en, this message translates to:
  /// **'Links go to Usisa\'s checking service. AI scan sends the message text to an AI service.'**
  String get settingsOnlineOn;

  /// No description provided for @settingsOnlineOff.
  ///
  /// In en, this message translates to:
  /// **'Everything is checked on your phone only, so Usisa may miss some scams.'**
  String get settingsOnlineOff;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @aboutGuide.
  ///
  /// In en, this message translates to:
  /// **'Usisa is a guide, not a guarantee. It looks for common scam signs, but it can be wrong. If something feels off, don\'t click, don\'t pay and don\'t share codes. Ask someone you trust.'**
  String get aboutGuide;

  /// No description provided for @aboutData.
  ///
  /// In en, this message translates to:
  /// **'Your checks and History are saved only on this phone. Nothing is sent anywhere unless online checks are on.'**
  String get aboutData;

  /// No description provided for @learnIntro.
  ///
  /// In en, this message translates to:
  /// **'Know the tricks scammers use in the Philippines.'**
  String get learnIntro;

  /// No description provided for @learnSourcesNote.
  ///
  /// In en, this message translates to:
  /// **'Based on public advice from BSP, NTC, PNP-ACG, CICC and DICT.'**
  String get learnSourcesNote;

  /// No description provided for @learnGoldenTitle.
  ///
  /// In en, this message translates to:
  /// **'Golden rules'**
  String get learnGoldenTitle;

  /// One rule per line.
  ///
  /// In en, this message translates to:
  /// **'Never share your OTP, PIN or password with anyone, even someone who says they\'re from your bank or the government.\nDon\'t tap links in unexpected texts. Open the official app or website yourself.\nStop and check before you send money. Call the person or company on a number you already know.'**
  String get learnGoldenRules;

  /// No description provided for @learnSampleLabel.
  ///
  /// In en, this message translates to:
  /// **'Sample fake text'**
  String get learnSampleLabel;

  /// No description provided for @learnRedFlags.
  ///
  /// In en, this message translates to:
  /// **'Red flags'**
  String get learnRedFlags;

  /// Verdict link to a Learn topic; topic is the localized topic title.
  ///
  /// In en, this message translates to:
  /// **'Learn more: {topic}'**
  String learnMore(String topic);

  /// No description provided for @learnReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a scam'**
  String get learnReportTitle;

  /// No description provided for @learnReportIntro.
  ///
  /// In en, this message translates to:
  /// **'If you were targeted or lost money, report it. Keep screenshots of the messages and the sender\'s number.'**
  String get learnReportIntro;

  /// One channel per line, as "name|what to do". Keep official numbers and sites exact.
  ///
  /// In en, this message translates to:
  /// **'CICC hotline 1326|Free, 24 hours a day. The government\'s anti-scam hotline (CICC and DICT).\neGov PH app|Report > Scam > Text Scam, then upload screenshots.\nYour bank or e-wallet|Call its official hotline right away if money or your account is involved. If they don\'t act, complain to BSP Online Buddy (BOB) at bsp.gov.ph.\nPNP Anti-Cybercrime Group|Report online fraud at any police station or at acg.pnp.gov.ph.\nNTC|For scam texts and SIM problems, complain to the NTC at ntc.gov.ph.'**
  String get learnReportChannels;

  /// Learn topic title; values match learnTopics in lib/features/learn/learn_screen.dart.
  ///
  /// In en, this message translates to:
  /// **'{topic, select, phishing{Fake bank and e-wallet texts} prize{Fake prizes and raffles} family{Family emergency texts} aid{Fake government aid (ayuda)} parcel{Fake delivery and parcel fees} job{Fake jobs and online tasks} investment{Investment and crypto scams} other{Online gambling ads}}'**
  String learnTopicTitle(String topic);

  /// What the scam is and what to do.
  ///
  /// In en, this message translates to:
  /// **'{topic, select, phishing{A text that looks like it\'s from your bank, GCash or Maya says your account is locked or needs verifying, and sends you to a link. The site looks real but steals your password and OTP. Banks and e-wallets never ask for your OTP, PIN or password by text, call or link. Open the official app yourself instead.} prize{You \"won\" a raffle you never joined, often naming a mall, TV show or government office. To claim it you must first pay a \"processing fee\" or give your details. Real promos don\'t make winners pay, and DTI-approved raffles carry a permit number you can check.} family{Someone pretends to be your child, grandchild or relative using a new number, or says they\'re a nurse or police officer calling about them. There\'s an emergency, you must send money now, and keep it secret. Call your relative on the number you already have before sending anything.} aid{A text says you qualify for cash aid from DSWD, SSS or PhilHealth, or a refund, and you must register through a link or pay a fee. Government aid is announced on official websites and pages, and agencies don\'t send payout links by text. Ask the agency\'s official page or office.} parcel{A text or call says your parcel is on hold and you must pay a small fee or update your address through a link. Some say customs seized a package with your name. Check orders in the shop\'s own app, and don\'t pay through links in texts.} job{An offer of easy work-from-home pay for liking videos, rating products or doing \"tasks\". The first payouts are small and real. Then you\'re asked to \"deposit\" money to unlock bigger tasks, and you can never withdraw it. Real employers don\'t make you pay to work.} investment{Promises of fast, guaranteed returns, like doubling your money in days, often in crypto, forex or a \"paluwagan\". Early members are paid with new members\' money until it collapses. Check with the SEC whether the company may take investments. Guaranteed high returns are a warning sign.} other{Unsolicited texts offering free credits or bonuses for online casinos, slots or e-sabong. Many of these sites are illegal and unlicensed, and keep your deposits and personal data. Don\'t tap the link or register.}}'**
  String learnTopicAbout(String topic);

  /// A synthetic sample scam text. Every red-flag phrase must appear in it word for word.
  ///
  /// In en, this message translates to:
  /// **'{topic, select, phishing{GCash ALERT: Your account will be suspended today. Verify now at gcash-verify-ph.xyz and enter your MPIN and OTP to keep your balance.} prize{CONGRATULATIONS! You won P50,000 in the Anniversary Raffle! To claim your prize, pay the P1,500 processing fee to this number within 24 hours.} family{Ma, this is my new number, I lost my phone. I\'m in the hospital, please send 5,000 to this GCash now. Don\'t tell Papa yet.} aid{DSWD: You qualify for P8,000 ayuda. Register at dswd-ayuda-claim.online and pay P200 for the release of your payout.} parcel{Your parcel is on hold due to an incomplete address. Pay the P35 re-delivery fee at ph-parcel-track.top or it will be returned today.} job{Hi! We are hiring part-time. Earn P500-P3,000 daily just by liking videos. No experience needed. Message us on Telegram to start.} investment{Guaranteed 30% profit every week! Invest P5,000 today and get P20,000 in one month. Limited slots only, invite friends for a bonus.} other{FREE P888 bonus for new players! Play slots and e-sabong, withdraw anytime. Register now at lucky888bet.vip}}'**
  String learnTopicSample(String topic);

  /// One red flag per line, as "phrase quoted from the sample|why it is a red flag".
  ///
  /// In en, this message translates to:
  /// **'{topic, select, phishing{suspended today|It threatens you so you don\'t stop to think\ngcash-verify-ph.xyz|This isn\'t GCash\'s real website (gcash.com)\nenter your MPIN and OTP|No real bank or e-wallet asks for these} prize{You won P50,000|You can\'t win a raffle you never joined\npay the P1,500 processing fee|Real prizes never ask you to pay first\nwithin 24 hours|A deadline to rush you} family{this is my new number|An unknown number claiming to be family\nsend 5,000 to this GCash now|Pressure to send money right away\nDon\'t tell Papa yet|Secrecy stops you from checking} aid{dswd-ayuda-claim.online|Government websites end in .gov.ph\npay P200 for the release|Government aid is free. Nobody should charge you to receive it} parcel{Pay the P35 re-delivery fee|A small fee to get your card details\nph-parcel-track.top|This isn\'t the courier\'s or shop\'s real website\nreturned today|A deadline to rush you} job{Earn P500-P3,000 daily just by liking videos|Too much pay for almost no work\nMessage us on Telegram|It moves you to a private chat that\'s hard to trace} investment{Guaranteed 30% profit every week|No real investment guarantees high returns\nLimited slots only|Pressure to join before you think\ninvite friends for a bonus|Paying you to recruit is a sign of a pyramid scheme} other{FREE P888 bonus|Free credits to lure you into depositing\nlucky888bet.vip|An unknown gambling site that may be unlicensed}}'**
  String learnTopicFlags(String topic);
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
