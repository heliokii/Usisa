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
  String get smsSetupTitle => 'Protect me from scam texts';

  @override
  String get smsSetupBody =>
      'Usisa checks each new text on your phone and warns you only when it may be a scam. Android will ask you to allow SMS and notifications.';

  @override
  String get smsSetupTurnOn => 'Turn on protection';

  @override
  String get smsSetupNotNow => 'Not now';

  @override
  String get smsBackgroundTitle => 'Let Usisa keep running';

  @override
  String get smsBackgroundBody =>
      'Your phone may stop apps that run in the background. On the next screen, allow Usisa to start on its own or remove its battery limit, so new texts keep getting checked.';

  @override
  String get smsBackgroundOpen => 'Open settings';

  @override
  String get smsBackgroundDone => 'Done';

  @override
  String get smsOffBanner => 'Scam text protection is off';

  @override
  String get smsOffBannerBody =>
      'Usisa needs SMS and notification permission to check your texts.';

  @override
  String get smsFix => 'Fix';

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
      'account_threat':
          'It threatens your account or parcel to make you tap a link',
      'easy_money': 'It promises easy money, a job, a loan or an investment that\'s too good to be true',
      'private_contact':
          'It asks you to deal with a stranger by email or chat app',
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
  String smsAlertTitle(String verdict) {
    String _temp0 = intl.Intl.selectLogic(verdict, {
      'dangerous': 'Dangerous text',
      'other': 'Be careful with this text',
    });
    return '$_temp0';
  }

  @override
  String smsAlertFrom(String sender) {
    return 'From $sender';
  }

  @override
  String get smsAlertUnknownSender => 'an unknown number';

  @override
  String get fromYourTexts => 'From your texts';

  @override
  String checkedOnDate(String date) {
    return 'Checked on $date';
  }

  @override
  String get checkAgain => 'Check again';

  @override
  String get askAiLookCloser => 'Ask AI to look closer';

  @override
  String get aiScanIntro => 'What do you want the AI to look at?';

  @override
  String get aiScanMessage => 'A message';

  @override
  String get aiScanLink => 'A link';

  @override
  String get aiScanScreenshot => 'A screenshot';

  @override
  String get aiUnavailable => 'AI couldn\'t look at this right now';

  @override
  String get sendToFamily => 'Send to family';

  @override
  String get readAloud => 'Read aloud';

  @override
  String get readAloudNoFilipino =>
      'There\'s no Filipino voice on this phone, so it\'s reading in English.';

  @override
  String get readAloudUnavailable =>
      'Read aloud isn\'t available on this phone.';

  @override
  String shareIntro(String verdict) {
    return 'I checked a message with Usisa. It says: $verdict';
  }

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

  @override
  String get learnIntro => 'Know the tricks scammers use in the Philippines.';

  @override
  String get learnSourcesNote =>
      'Based on public advice from BSP, NTC, PNP-ACG, CICC and DICT.';

  @override
  String get learnGoldenTitle => 'Golden rules';

  @override
  String get learnGoldenRules =>
      'Never share your OTP, PIN or password with anyone, even someone who says they\'re from your bank or the government.\nDon\'t tap links in unexpected texts. Open the official app or website yourself.\nStop and check before you send money. Call the person or company on a number you already know.';

  @override
  String get learnSampleLabel => 'Sample fake text';

  @override
  String get learnRedFlags => 'Red flags';

  @override
  String learnMore(String topic) {
    return 'Learn more: $topic';
  }

  @override
  String get learnReportTitle => 'Report a scam';

  @override
  String get learnReportIntro =>
      'If you were targeted or lost money, report it. Keep screenshots of the messages and the sender\'s number.';

  @override
  String get learnReportChannels =>
      'CICC hotline 1326|Free, 24 hours a day. The government\'s anti-scam hotline (CICC and DICT).\neGov PH app|Report > Scam > Text Scam, then upload screenshots.\nYour bank or e-wallet|Call its official hotline right away if money or your account is involved. If they don\'t act, complain to BSP Online Buddy (BOB) at bsp.gov.ph.\nPNP Anti-Cybercrime Group|Report online fraud at any police station or at acg.pnp.gov.ph.\nNTC|For scam texts and SIM problems, complain to the NTC at ntc.gov.ph.';

  @override
  String learnTopicTitle(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'phishing': 'Fake bank and e-wallet texts',
      'prize': 'Fake prizes and raffles',
      'family': 'Family emergency texts',
      'aid': 'Fake government aid (ayuda)',
      'parcel': 'Fake delivery and parcel fees',
      'job': 'Fake jobs and online tasks',
      'investment': 'Investment and crypto scams',
      'other': 'Online gambling ads',
    });
    return '$_temp0';
  }

  @override
  String learnTopicAbout(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'phishing': 'A text that looks like it\'s from your bank, GCash or Maya says your account is locked or needs verifying, and sends you to a link. The site looks real but steals your password and OTP. Banks and e-wallets never ask for your OTP, PIN or password by text, call or link. Open the official app yourself instead.',
      'prize': 'You \"won\" a raffle you never joined, often naming a mall, TV show or government office. To claim it you must first pay a \"processing fee\" or give your details. Real promos don\'t make winners pay, and DTI-approved raffles carry a permit number you can check.',
      'family': 'Someone pretends to be your child, grandchild or relative using a new number, or says they\'re a nurse or police officer calling about them. There\'s an emergency, you must send money now, and keep it secret. Call your relative on the number you already have before sending anything.',
      'aid': 'A text says you qualify for cash aid from DSWD, SSS or PhilHealth, or a refund, and you must register through a link or pay a fee. Government aid is announced on official websites and pages, and agencies don\'t send payout links by text. Ask the agency\'s official page or office.',
      'parcel': 'A text or call says your parcel is on hold and you must pay a small fee or update your address through a link. Some say customs seized a package with your name. Check orders in the shop\'s own app, and don\'t pay through links in texts.',
      'job': 'An offer of easy work-from-home pay for liking videos, rating products or doing \"tasks\". The first payouts are small and real. Then you\'re asked to \"deposit\" money to unlock bigger tasks, and you can never withdraw it. Real employers don\'t make you pay to work.',
      'investment': 'Promises of fast, guaranteed returns, like doubling your money in days, often in crypto, forex or a \"paluwagan\". Early members are paid with new members\' money until it collapses. Check with the SEC whether the company may take investments. Guaranteed high returns are a warning sign.',
      'other': 'Unsolicited texts offering free credits or bonuses for online casinos, slots or e-sabong. Many of these sites are illegal and unlicensed, and keep your deposits and personal data. Don\'t tap the link or register.',
    });
    return '$_temp0';
  }

  @override
  String learnTopicSample(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'phishing': 'GCash ALERT: Your account will be suspended today. Verify now at gcash-verify-ph.xyz and enter your MPIN and OTP to keep your balance.',
      'prize': 'CONGRATULATIONS! You won P50,000 in the Anniversary Raffle! To claim your prize, pay the P1,500 processing fee to this number within 24 hours.',
      'family': 'Ma, this is my new number, I lost my phone. I\'m in the hospital, please send 5,000 to this GCash now. Don\'t tell Papa yet.',
      'aid': 'DSWD: You qualify for P8,000 ayuda. Register at dswd-ayuda-claim.online and pay P200 for the release of your payout.',
      'parcel': 'Your parcel is on hold due to an incomplete address. Pay the P35 re-delivery fee at ph-parcel-track.top or it will be returned today.',
      'job': 'Hi! We are hiring part-time. Earn P500-P3,000 daily just by liking videos. No experience needed. Message us on Telegram to start.',
      'investment': 'Guaranteed 30% profit every week! Invest P5,000 today and get P20,000 in one month. Limited slots only, invite friends for a bonus.',
      'other': 'FREE P888 bonus for new players! Play slots and e-sabong, withdraw anytime. Register now at lucky888bet.vip',
    });
    return '$_temp0';
  }

  @override
  String learnTopicFlags(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'phishing': 'suspended today|It threatens you so you don\'t stop to think\ngcash-verify-ph.xyz|This isn\'t GCash\'s real website (gcash.com)\nenter your MPIN and OTP|No real bank or e-wallet asks for these',
      'prize': 'You won P50,000|You can\'t win a raffle you never joined\npay the P1,500 processing fee|Real prizes never ask you to pay first\nwithin 24 hours|A deadline to rush you',
      'family': 'this is my new number|An unknown number claiming to be family\nsend 5,000 to this GCash now|Pressure to send money right away\nDon\'t tell Papa yet|Secrecy stops you from checking',
      'aid': 'dswd-ayuda-claim.online|Government websites end in .gov.ph\npay P200 for the release|Government aid is free. Nobody should charge you to receive it',
      'parcel': 'Pay the P35 re-delivery fee|A small fee to get your card details\nph-parcel-track.top|This isn\'t the courier\'s or shop\'s real website\nreturned today|A deadline to rush you',
      'job': 'Earn P500-P3,000 daily just by liking videos|Too much pay for almost no work\nMessage us on Telegram|It moves you to a private chat that\'s hard to trace',
      'investment': 'Guaranteed 30% profit every week|No real investment guarantees high returns\nLimited slots only|Pressure to join before you think\ninvite friends for a bonus|Paying you to recruit is a sign of a pyramid scheme',
      'other': 'FREE P888 bonus|Free credits to lure you into depositing\nlucky888bet.vip|An unknown gambling site that may be unlicensed',
    });
    return '$_temp0';
  }

  @override
  String get appTagline => 'A little check, a lot safer.';

  @override
  String get homeSubtitle => 'When in doubt, check it first.';

  @override
  String get smsCardEyebrow => 'Your everyday backup';

  @override
  String get pageTagline => 'Your digital kakampi';

  @override
  String get backToCheck => 'Back to check';

  @override
  String get pageEyebrow => 'A little check goes a long way';

  @override
  String get messageIntro => 'Paste the message you want to check.';

  @override
  String get messageLabel => 'Your message';

  @override
  String get pasteButton => 'Paste';

  @override
  String get clearButton => 'Clear';

  @override
  String charCount(int count, int max) {
    return '$count / $max characters';
  }

  @override
  String get checkMessageButton => 'Check message';

  @override
  String get messageFootnote =>
      'Usisa checks the message on your phone first.\nLinks are only looked up online if you allowed it.';

  @override
  String get linkIntro => 'Not sure where a link leads? Check it first.';

  @override
  String get linkLabel => 'Link to check';

  @override
  String get linkTipTitle => 'Looks familiar. Isn\'t always real.';

  @override
  String get linkTipBody =>
      'Scam links copy banks and delivery services with a tiny spelling change. Never open the link to find out: Usisa follows it for you and shows where it really goes.';

  @override
  String get checkLinkButton => 'Check link';

  @override
  String get linkFootnote =>
      'Your link is followed on Usisa\'s server,\nnever opened on your phone.';

  @override
  String get screenshotPageIntro =>
      'Upload a screenshot of a suspicious message.';

  @override
  String get screenshotDropTitle => 'A screenshot is a good start.';

  @override
  String get screenshotDropTypes => 'JPG, PNG or WEBP';

  @override
  String get screenshotGallery => 'Choose from gallery';

  @override
  String get screenshotCamera => 'Take a photo';

  @override
  String get screenshotReading => 'Reading the text…';

  @override
  String get screenshotReviewTitle => 'Review the text we read';

  @override
  String get screenshotStartOver => 'Start over';

  @override
  String get checkScreenshotButton => 'Check screenshot';

  @override
  String get screenshotFootnote =>
      'Your picture stays on this phone.\nOnly the text read from it is checked.';

  @override
  String get aiScanPageIntro =>
      'A closer look starts here. What would you like to check?';

  @override
  String get aiScanMessageSubtitle => 'Take a closer look at a text.';

  @override
  String get aiScanLinkSubtitle => 'See where it leads and why.';

  @override
  String get aiScanScreenshotSubtitle => 'Read a message from a picture.';
}
