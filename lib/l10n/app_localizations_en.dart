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
      'This exact text goes to Usisa’s server and Groq for AI review. Remove codes or personal details you do not want to share. Names, numbers, and links are included. Screenshots and sender details stay on your device. Groq may keep requests for reliability or abuse monitoring, based on account settings. AI can be wrong; it does not verify senders or open links.';

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
      'AI could not assess this message. Use local findings and verify it yourself.';

  @override
  String get aiUnavailable =>
      'Local checks are done, but AI is unavailable. Your text is still here. Review it and try again.';

  @override
  String get aiCancelled =>
      'AI check cancelled. Local findings remain. A sent request may still be processed.';

  @override
  String get aiNotRequested => 'No AI check yet. Review the text to add one.';

  @override
  String get aiDisagreement =>
      'Results differ. Keep the stronger warning; neither proves the message safe.';

  @override
  String get aiReviewed => 'AI used the text you reviewed.';

  @override
  String get aiRetry => 'Review and retry AI';

  @override
  String get aiLimitations =>
      'AI can miss scams or flag safe messages. Quotes show its input, not proof.';

  @override
  String get aiSettingsBody =>
      'AI can check text, links, and screenshot text you approve. Confirm each upload to Usisa and Groq. Auto SMS stays on-device. Link-check consent does not enable AI.';

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
      'Treat code requests with care, even from claimed support. Real OTP messages may warn you not to share the code. Verify through the official app.';

  @override
  String get learnBankTitle => 'Bank & Wallet Scams';

  @override
  String get learnBankBody =>
      'An account suspension threat can pressure you to tap a link. Sender names can be spoofed. Open your bank or e-wallet app directly to check your account; do not use the message\'s link as proof.';

  @override
  String get learnBankSummary => 'Fake messages from BPI,\nGCash, Maya, etc.';

  @override
  String get learnGovernmentTitle => 'Government Impersonation';

  @override
  String get learnGovernmentBody =>
      'Scammers may pose as SSS, PhilHealth, Pag-IBIG, or another agency. Verify unexpected aid, fines, or registration through an official service you open yourself. A logo proves nothing.';

  @override
  String get learnGovernmentSummary =>
      'Scams pretending to be from\nSSS, PAG-IBIG, PhilPost, and more.';

  @override
  String get learnDeliveryTitle => 'Unexpected delivery fees';

  @override
  String get learnDeliveryBody =>
      'Fake redelivery fees can lead to pages that steal card or account details. Check orders in your courier app. Short links hide destinations; Usisa does not expand them.';

  @override
  String get learnSellerTitle => 'Online Selling Scams';

  @override
  String get learnSellerBody =>
      'Be cautious about pressure to move a conversation or payment outside a marketplace\'s normal process. Confirm the seller, item, recipient and payment purpose through trusted records before sending money.';

  @override
  String get learnSellerSummary =>
      'Fake sellers, payment proofs,\nand delivery tricks.';

  @override
  String get learnRecoveryTitle => 'If you already shared details';

  @override
  String get learnRecoveryBody =>
      'Stop payments. Contact your bank or e-wallet through its official app or a trusted contact. Change exposed passwords; keep evidence private. Never share another OTP with a recovery helper.';

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
  String get messageScanPrompt => 'Paste or type a message to scan';

  @override
  String get messageScanSupport =>
      'We\'ll check for suspicious links, scams, and harmful content.';

  @override
  String get scanHeading => 'Check before you tap.';

  @override
  String get scanIntro => 'Check a message or link before you act.';

  @override
  String get localPrivate => 'Checks stay on your device by default.';

  @override
  String get message => 'Message';

  @override
  String get link => 'Link';

  @override
  String get screenshot => 'Screenshot';

  @override
  String get screenshotHeading => 'Scan a screenshot';

  @override
  String get screenshotSelected => 'Screenshot selected';

  @override
  String get changeImage => 'Change image';

  @override
  String get screenshotSupported => 'PNG, JPG, JPEG, or WEBP · Up to 10 MB';

  @override
  String get linkCheckPrompt => 'Check a link’s safety';

  @override
  String get linkCheckSupport => 'See known risk signs before opening a URL.';

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
  String get loading => 'Loading';

  @override
  String get cancel => 'Cancel';

  @override
  String get chooseScreenshot => 'Choose screenshot';

  @override
  String get photos => 'Photos';

  @override
  String get browseFiles => 'Browse files';

  @override
  String get screenshotIntro =>
      'Choose a message screenshot. Review its text before scanning.';

  @override
  String get ocrNativeOnly =>
      'OCR works in the Android and iOS app. You can paste text here.';

  @override
  String get readingImage => 'Reading screenshot…';

  @override
  String get reviewText => 'Review extracted text';

  @override
  String get ocrNotice =>
      'Check names, numbers, and links. OCR can misread them.';

  @override
  String get previewUnavailable =>
      'Preview unavailable. Review and edit the extracted text anyway.';

  @override
  String get checkThisText => 'Check this text';

  @override
  String get noOcrText =>
      'No text found. Choose another image or type the message.';

  @override
  String get smsOff => 'Auto SMS is unavailable.';

  @override
  String get smsDetail =>
      'Manual scans work without SMS access. Auto checks need a supported Android phone.';

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
  String get checkAnotherLink => 'Check another link';

  @override
  String get checkAnotherScreenshot => 'Check another screenshot';

  @override
  String get viewFullImage => 'View full image';

  @override
  String get checkAiShort => 'Check';

  @override
  String get linkDomainLabel => 'Domain';

  @override
  String get linkSimilarityLabel => 'Similarity';

  @override
  String get linkStatusLabel => 'Status';

  @override
  String resultLinkCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count links found',
      one: '1 link found',
    );
    return '$_temp0';
  }

  @override
  String resultMoreFindings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'See $count more signs',
      one: 'See 1 more sign',
    );
    return '$_temp0';
  }

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
      'No common warning signs found. The sender is not verified.';

  @override
  String get cautionCopy =>
      'Some details need a closer look. Verify before replying or paying.';

  @override
  String get highCopy =>
      'Strong warning signs found. Pause before sharing money or details.';

  @override
  String resultRiskLabel(String risk) {
    String _temp0 = intl.Intl.selectLogic(risk, {
      'low': 'Safe',
      'caution': 'Need Review',
      'other': 'High Risk',
    });
    return '$_temp0';
  }

  @override
  String get unknownStatus => 'Unknown';

  @override
  String get analysisSummary => 'Analysis Summary';

  @override
  String get detectedSigns => 'Detected Signs';

  @override
  String get noWarnings => 'No common warning signs detected';

  @override
  String get notChecked => 'Not checked online';

  @override
  String get notListed =>
      'Not on the threat list. That does not prove it is safe.';

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
      'Already shared details? Contact your bank or e-wallet through its official app now.';

  @override
  String get historyHeading => 'Your checks, kept private.';

  @override
  String get historyAll => 'All';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get historyOff => 'History is off';

  @override
  String get historyOffBody => 'Save up to 100 encrypted scans for 30 days.';

  @override
  String get enableHistory => 'Enable private history';

  @override
  String get noHistory => 'No scans yet';

  @override
  String get noHistoryBody =>
      'Saved checks appear here. Start with a message you want to verify.';

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
      'This removes the saved check from Usisa, not the SMS in your messaging app.';

  @override
  String get clearSavedData => 'Clear saved data';

  @override
  String get notSaved => 'Not saved. This result stays in your session.';

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
      'Encrypted text draft for 24 hours. Screenshots are not saved.';

  @override
  String get onlineChecks => 'Online link checks';

  @override
  String get onlineDisclosure => 'Enable online link checks?';

  @override
  String get onlineSettingsDescription =>
      'Check full URLs with Google Safe Browsing.';

  @override
  String get onlineBody =>
      'While enabled, manual link checks send full URLs, including paths and queries, to the Usisa gateway and Google Safe Browsing. Messages, senders, and images stay on-device. SMS checks never upload URLs. Google may miss threats or flag safe sites. Online advisories expire. History saves local findings and last-check details, not online verdicts.';

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
      'Made for messages in the Philippines. Usisa flags possible scam signs; it can miss scams and cannot verify every sender.';

  @override
  String get sessionPreview =>
      'Browser preview stores data for this session only. OCR and incoming SMS need Android.';

  @override
  String get privateHistoryConsent =>
      'Save encrypted message text, links, and findings on this device (latest 100 scans). Reviews expire after 30 days. Usisa deletes expired files while it runs or next time you open it. A stopped app cannot delete them on schedule. Clear saved data deletes them when storage is available.';

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
      'Check suspicious messages and links for warning signs. Built for English, Filipino, and Taglish in the Philippines.';

  @override
  String get welcomePrivacy =>
      'Manual text checks work offline. History, online link checks, and incoming SMS are optional and off by default. Usisa can miss scams. Verify important requests independently.';

  @override
  String get startChecking => 'Start checking';

  @override
  String get smsHeading => 'Incoming SMS checks';

  @override
  String get smsDisclosure => 'Enable incoming SMS checks?';

  @override
  String get smsDisclosureBody =>
      'Checks new SMS on this device only. No inbox access or message uploads. Up to 20 encrypted reviews expire in 15 minutes. Android may delay checks; force-stop stops checks. Some scams may be missed.';

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
      'Checks stay on-device. Android may delay them; coverage is not guaranteed. Low-risk messages stay quiet.';

  @override
  String get smsAlertsOff =>
      'Notifications are off. Recent reviews stay here. Enable alerts in Android settings.';

  @override
  String get enableSmsAlerts => 'Enable review notifications';

  @override
  String get smsDegraded =>
      'Some messages were not checked. Turn SMS checks off, then on again.';

  @override
  String get manageSms => 'Manage SMS checks';

  @override
  String get recentSms => 'Recent SMS reviews';

  @override
  String get smsTemporary =>
      'Temporary encrypted reviews expire 15 minutes after receipt. Low-risk messages are deleted after checking.';

  @override
  String get smsEmpty =>
      'No temporary reviews. They may have expired, been low-risk, or arrived while checks were off.';

  @override
  String get smsMissing =>
      'Review unavailable. It may have expired, been deleted, or SMS checks were off. Copy the message into a manual scan.';

  @override
  String get smsPending =>
      'No check completed yet. Try again soon or copy the message into a manual scan.';

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
      'Check messages, links, and screenshots for scam signs.';

  @override
  String get scanMessageCard => 'Scan Message';

  @override
  String get scanMessageDescription => 'Paste or type a message';

  @override
  String get checkLinkCard => 'Check a Link';

  @override
  String get checkLinkDescription => 'Check a URL before opening.';

  @override
  String get scanScreenshotCard => 'Scan Screenshot';

  @override
  String get scanScreenshotDescription =>
      'Read message text from a screenshot.';

  @override
  String get aiScan => 'AI Scan';

  @override
  String get aiBeta => 'Beta';

  @override
  String get aiHomeDescription => 'Get AI help with scam checks.';

  @override
  String get homeAiBadge => 'New';

  @override
  String get autoSmsCard => 'Auto SMS Detection';

  @override
  String get autoSmsDescription => 'Check incoming SMS for scams.';

  @override
  String get aiIntroTitle => 'AI-Powered Scam Analysis';

  @override
  String get aiIntroBody =>
      'Check a message, link, or screenshot. AI explains possible risks and next steps.';

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
  String get aiInputQuestion => 'What do you want to check?';

  @override
  String get aiTextOption => 'Text / Message';

  @override
  String get aiTextOptionBody => 'Paste or type a suspicious message';

  @override
  String get aiLinkOption => 'URL / Link';

  @override
  String get aiLinkOptionBody => 'Check a link for scam signs.';

  @override
  String get aiScreenshotOption => 'Screenshot / Image';

  @override
  String get aiScreenshotOptionBody => 'Read and review text with OCR.';

  @override
  String get aiProgressTitle => 'Analyzing with AI…';

  @override
  String get aiStageReviewed => 'Text review confirmed';

  @override
  String get aiStageLocal => 'On-device checks complete';

  @override
  String get aiStageRequest => 'Sending text for an AI check…';

  @override
  String get aiStageResult => 'Preparing your result';

  @override
  String get smsDetectionTitle => 'SMS Detection';

  @override
  String get smsDetectionBody =>
      'Checks new SMS for scam signs and alerts you to suspicious messages.';

  @override
  String get smsRecentDetections => 'Recent SMS checks';

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
      'Simple ways to avoid common\nscams in the Philippines.';

  @override
  String get learnCommonScams => 'Common Scams in PH';

  @override
  String get getStarted => 'Get Started';

  @override
  String get onboardingSecondTitle => 'See why a message was flagged.';

  @override
  String get onboardingSecondBody =>
      'See which words, links, and requests need a closer look.';

  @override
  String get onboardingThirdTitle => 'Choose what stays on your device.';

  @override
  String get onboardingThirdBody =>
      'Manual checks stay local. AI and online link checks need your review and consent.';

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
  String get aiScanToggleBody => 'Review before AI checks text.';

  @override
  String get smsNotificationsEnabled => 'SMS notifications are enabled.';

  @override
  String smsRecentTab(int count) {
    return 'Recent ($count)';
  }

  @override
  String smsFlaggedTab(int count) {
    return 'Flagged ($count)';
  }

  @override
  String get smsFlaggedEmpty => 'No flagged messages in recent SMS checks.';

  @override
  String get home => 'Home';
}
