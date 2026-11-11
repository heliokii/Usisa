// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get analysisMode => 'Analysis';

  @override
  String get onDevice => 'On-device';

  @override
  String get aiAssisted => 'AI assisted';

  @override
  String get aiManualOnly => 'AI sends text only after you review and confirm.';

  @override
  String get aiReviewTitle => 'Review for AI check';

  @override
  String get aiDisclosure =>
      'This exact text will be sent to Usisa’s server and Groq for an AI assessment. Remove any codes or personal details you do not want to share. Names, numbers and links in this text are included. Your screenshot and separate sender details stay on your device. Groq may retain requests for reliability or abuse monitoring, depending on account settings. AI can make mistakes; it does not verify the sender or visit links.';

  @override
  String get aiTextLabel => 'Text to send';

  @override
  String get sendAi => 'Send this text for AI check';

  @override
  String get keepOnDevice => 'Keep on device';

  @override
  String get aiAssessment => 'AI assessment';

  @override
  String get onDeviceFindings => 'On-device findings';

  @override
  String get aiChecking => 'On-device checks complete. AI is checking…';

  @override
  String get aiUnknown =>
      'AI could not assess this message. Use the local findings and verify independently.';

  @override
  String get aiUnavailable =>
      'On-device checks complete; AI assessment unavailable. Your text is preserved. You can review it and try again.';

  @override
  String get aiCancelled =>
      'AI check cancelled. Local findings remain available. A request already sent may have been processed.';

  @override
  String get aiNotRequested =>
      'AI was not requested. Review the text to add an optional online assessment.';

  @override
  String get aiDisagreement =>
      'The assessments differ. The stronger warning is kept; neither assessment proves the message is safe.';

  @override
  String get aiReviewed => 'This result uses the text reviewed for AI.';

  @override
  String get aiRetry => 'Review and retry AI';

  @override
  String get aiLimitations =>
      'AI adds context, but may miss scams or flag legitimate messages. Quotes show the text it used; they do not prove its conclusion.';

  @override
  String get aiSettingsBody =>
      'Optional online help for text, links and reviewed screenshot text. You review and confirm each upload to Usisa’s server and Groq. Automatic SMS checks stay on-device. Online link-check consent does not enable AI.';

  @override
  String aiFindingTitle(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'credential_request': 'Asks for a security secret',
      'payment_request': 'Requests a payment',
      'urgency': 'Pressures you to act',
      'impersonation': 'Possible impersonation',
      'prize': 'Promises a prize',
      'suspicious_link': 'Questionable link context',
      'other': 'AI warning sign',
    });
    return '$_temp0';
  }

  @override
  String aiAdvice(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'dont_share_secrets':
          'Do not share OTPs, passwords or PINs with anyone requesting them.',
      'pause_payment':
          'Pause the payment. Confirm the recipient and reason independently.',
      'contact_provider_if_shared': 'If you already shared details, contact your provider through its official app or your own trusted records.',
      'other': 'Verify through the official app or a trusted channel you opened yourself.',
    });
    return '$_temp0';
  }

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
  String get previewUnavailable =>
      'Image preview is unavailable. You can still review and edit the extracted text.';

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
      'Messages stay in this session. Enable encrypted history for the latest 100 checks, with review access expiring after 30 days.';

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
  String get language => 'Language';

  @override
  String get saveHistory => 'Save private history';

  @override
  String get restoreDraft => 'Restore my draft';

  @override
  String get draftDetail =>
      'Restore one encrypted text draft within 24 hours. Expired files are erased while Usisa runs or on next use; a closed or stopped app cannot erase on schedule. Screenshots are never saved.';

  @override
  String get onlineChecks => 'Online link checks';

  @override
  String get onlineDisclosure => 'Enable online link checks?';

  @override
  String get onlineBody =>
      'Full URLs, including path and query, go to the Usisa gateway and Google Safe Browsing for manual link checks until disabled. Messages, senders, and images stay on your device. SMS checks never upload URLs. Google can miss threats or flag legitimate sites. Online advisories expire; saved history keeps local findings and last-check details, not online verdicts.';

  @override
  String get googleAdvisory => 'Advisory provided by Google';

  @override
  String get advisoryUnavailable =>
      'Could not open the help page. Your scan is still available.';

  @override
  String get phishingHelp => 'Learn about phishing';

  @override
  String get malwareHelp => 'Learn about malware';

  @override
  String get unwantedHelp => 'Learn about unwanted software';

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
      'Save encrypted copies of message text, links, and findings on this device (latest 100 scans). Reviews expire after 30 days. Expired files are erased while Usisa runs or on next use; a closed or stopped app cannot erase on schedule. Clear saved data erases them immediately when storage is available.';

  @override
  String get reviewRecoveredScreenshot => 'Review previous screenshot';

  @override
  String get discardRecoveredScreenshot => 'Discard previous screenshot';

  @override
  String get assumedHttps =>
      'HTTPS was assumed because the link has no scheme. No page was opened.';

  @override
  String get reputationExpired =>
      'Previous online result is no longer current. Check again.';

  @override
  String get previousThreat => 'Previously listed as a threat.';

  @override
  String checkedAtLabel(String date) {
    return 'Last checked: $date';
  }

  @override
  String get retentionCleanupFailed =>
      'Some expired data could not be erased. Try Clear saved data in Settings.';

  @override
  String get welcomeTitle => 'A second look before you act.';

  @override
  String get welcomeBody =>
      'Check suspicious messages and links for warning signs. Built for English, Filipino, and Taglish messages in the Philippines.';

  @override
  String get welcomePrivacy =>
      'Manual text checks work offline. History, cloud link checks, and incoming SMS checks are optional and start off. Usisa can miss scams; verify important requests independently.';

  @override
  String get startChecking => 'Start checking';

  @override
  String get smsHeading => 'Incoming SMS checks';

  @override
  String get smsDisclosure => 'Enable incoming SMS checks?';

  @override
  String get smsDisclosureBody =>
      'Usisa reads only new SMS received while this feature is enabled. It checks them locally without uploading messages or reading your inbox or other apps. Up to 20 encrypted reviews expire after 15 minutes; Android may delay file cleanup. Android may delay or stop checks; force-stopping Usisa prevents them. Detection can miss scams.';

  @override
  String get enableSmsChecks => 'Enable SMS checks';

  @override
  String get smsPermissionNeeded => 'SMS permission needed';

  @override
  String get smsEnabled => 'Incoming SMS checks enabled';

  @override
  String get smsDisabled => 'Incoming SMS checks off';

  @override
  String get smsLimits =>
      'Local checks only. Android may delay checks; coverage is not guaranteed. Low-risk messages stay quiet.';

  @override
  String get smsAlertsOff =>
      'Notifications are off. Open recent SMS reviews here. You can also enable notifications in Android app settings.';

  @override
  String get enableSmsAlerts => 'Enable review notifications';

  @override
  String get smsDegraded =>
      'Some messages could not be checked. Coverage is incomplete. Try turning SMS checks off and on again.';

  @override
  String get manageSms => 'Manage SMS checks';

  @override
  String get recentSms => 'Recent SMS reviews';

  @override
  String get smsTemporary =>
      'Temporary encrypted reviews expire 15 minutes after receipt. Low-risk messages are removed after checking.';

  @override
  String get smsEmpty =>
      'No temporary SMS reviews. Messages may have expired, stayed quiet, or not been received while checks were enabled.';

  @override
  String get smsMissing =>
      'This SMS review is unavailable. It may have expired, been erased, or checks were turned off. Copy the message into Text to check it again.';

  @override
  String get smsPending =>
      'This message has no completed check yet. Try again shortly, or copy it into Text for a manual check.';

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

  @override
  String get homeHeading => 'Stay one step ahead of scams.';

  @override
  String get homeBrand => 'Usisa';

  @override
  String get homeBody =>
      'Scan messages, links, or screenshots and get an instant risk analysis.';

  @override
  String get scanMessageCard => 'Scan Message';

  @override
  String get scanMessageDescription => 'Paste or type a message';

  @override
  String get checkLinkCard => 'Check a Link';

  @override
  String get checkLinkDescription => 'Check if a URL is safe';

  @override
  String get scanScreenshotCard => 'Scan Screenshot';

  @override
  String get scanScreenshotDescription => 'Use OCR to read text';

  @override
  String get aiScan => 'AI Scan';

  @override
  String get aiBeta => 'Beta';

  @override
  String get aiHomeDescription => 'Get a deeper AI analysis';

  @override
  String get homeAiBadge => 'New';

  @override
  String get autoSmsCard => 'Auto SMS Detection';

  @override
  String get autoSmsDescription => 'Check incoming SMS for potential scams';

  @override
  String get aiIntroTitle => 'AI-Powered Scam Analysis';

  @override
  String get aiIntroBody =>
      'Analyze a message, link, or screenshot with AI to explain possible risks and suggest safe next steps.';

  @override
  String get aiMultiInput => 'Multi-input';

  @override
  String get aiMultiInputBody => 'Text, links, or screenshots with OCR';

  @override
  String get aiContextAware => 'Context-aware';

  @override
  String get aiContextAwareBody => 'Looks for common scam patterns in PH';

  @override
  String get aiActionable => 'Actionable results';

  @override
  String get aiActionableBody => 'Risk level, explanations, and next steps';

  @override
  String get startAiScan => 'Start AI Scan';

  @override
  String get aiInputQuestion => 'What do you want to analyze?';

  @override
  String get aiTextOption => 'Text / Message';

  @override
  String get aiTextOptionBody => 'Paste or type a suspicious message';

  @override
  String get aiLinkOption => 'URL / Link';

  @override
  String get aiLinkOptionBody => 'Check a link for scam context';

  @override
  String get aiScreenshotOption => 'Screenshot / Image';

  @override
  String get aiScreenshotOptionBody => 'Use OCR to read and review text';

  @override
  String get aiProgressTitle => 'Analyzing with AI…';

  @override
  String get aiStageReviewed => 'Text review confirmed';

  @override
  String get aiStageLocal => 'On-device checks complete';

  @override
  String get aiStageRequest => 'Requesting AI assessment';

  @override
  String get aiStageResult => 'Preparing your result';

  @override
  String get smsDetectionTitle => 'SMS Detection';

  @override
  String get smsDetectionBody =>
      'Automatically checks incoming SMS for potential scams and alerts you if something looks suspicious.';

  @override
  String get smsRecentDetections => 'Recent Detections';

  @override
  String get warningSigns => 'Detected Warning Signs';

  @override
  String get safetyRecommendations => 'Safety Recommendations';

  @override
  String get linkWhyRisky => 'Why is it risky?';

  @override
  String get learnScamTips => 'Scam Safety Tips';

  @override
  String get learnScamTipsBody =>
      'Simple ways to avoid common scams in the Philippines.';

  @override
  String get learnCommonScams => 'Common Scams in PH';

  @override
  String get getStarted => 'Get Started';

  @override
  String get onboardingSecondTitle => 'See why a message was flagged.';

  @override
  String get onboardingSecondBody =>
      'Usisa shows the words, links, and requests that need a closer look.';

  @override
  String get onboardingThirdTitle => 'Choose what stays on your device.';

  @override
  String get onboardingThirdBody =>
      'Manual scans stay local. AI and online link checks only run after review and consent.';

  @override
  String get linkCheckerTitle => 'Link Checker';

  @override
  String get aiScanResult => 'AI Scan Result';

  @override
  String get learnStaySafeTitle => 'Learn & Stay Safe';

  @override
  String get detection => 'Detection';

  @override
  String get general => 'General';

  @override
  String get notifications => 'Notifications';

  @override
  String get aiScanToggleBody =>
      'Use AI-assisted scans for deeper context. Each upload still needs your review and confirmation.';

  @override
  String get smsNotificationsEnabled => 'Generic SMS alerts are enabled.';

  @override
  String smsRecentTab(int count) {
    return 'Recent ($count)';
  }

  @override
  String smsFlaggedTab(int count) {
    return 'Flagged ($count)';
  }

  @override
  String get smsFlaggedEmpty => 'No flagged messages among recent SMS checks.';

  @override
  String get home => 'Home';
}
