import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'app/launch_splash.dart';
import 'app/motion.dart';
import 'app/theme.dart';
import 'features/check/check.dart';
import 'features/check/ai_scan_screen.dart';
import 'features/check/consent_screen.dart';
import 'features/check/gateway_ai_checker.dart';
import 'features/check/gateway_link_checker.dart';
import 'features/check/home_screen.dart';
import 'features/check/paste_screen.dart';
import 'features/check/screenshot_screen.dart';
import 'features/check/share_source.dart';
import 'features/history/history_screen.dart';
import 'features/history/history_store.dart';
import 'features/learn/learn_screen.dart';
import 'features/scan/scan_models.dart';
import 'features/scan/ocr_service.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/settings_store.dart';
import 'features/sms/sms_service.dart';
import 'features/sms/sms_setup_screen.dart';
import 'l10n/app_localizations.dart';

class UsisaApp extends StatefulWidget {
  const UsisaApp({
    super.key,
    this.storage,
    this.runCheck,
    this.readScreenshot,
    this.takePhoto,
    this.gatewayClient,
    this.shares,
    this.readSharedImage,
    this.sms,
  });

  final PrivateStorage? storage;

  /// Runs a Check; widget tests pass a fake. Without one, the real pipeline runs behind the online consent.
  final RunCheck? runCheck;

  /// HTTP client for the gateway; widget tests pass a fake.
  final http.Client? gatewayClient;

  /// Picks a picture and reads its text; widget tests pass a fake.
  final ScreenshotReader? readScreenshot;

  /// Takes a photo with the camera and reads its text; widget tests pass a fake.
  final ScreenshotReader? takePhoto;

  /// Content shared in from other apps; widget tests pass a fake.
  final Stream<SharedItem>? shares;

  /// Reads the text in a shared picture (a cache path); widget tests pass a fake.
  final Future<String> Function(String path)? readSharedImage;

  /// The native SMS bridge; widget tests pass one over a fake channel.
  final SmsService? sms;

  @override
  State<UsisaApp> createState() => _UsisaAppState();
}

class _UsisaAppState extends State<UsisaApp> {
  late final SettingsStore settings = SettingsStore(widget.storage ?? MemoryStorage());
  // Clearing History also wipes the warned texts Android still holds, so they can't come back.
  late final HistoryStore history = HistoryStore(
    settings.storage,
    clearSmsPrivacy: () async {
      if (sms.bridgeAvailable) await sms.invalidatePrivacy().catchError((_) => 0);
    },
    forgetSmsWarning: (id) async {
      if (sms.bridgeAvailable) await sms.dismiss(id);
    },
  );
  late final http.Client _gateway = widget.gatewayClient ?? http.Client();
  late final SmsService sms = widget.sms ?? SmsService();
  final _navigator = GlobalKey<NavigatorState>();
  late final Stream<SharedItem> _shares = widget.shares ?? (kIsWeb ? const Stream.empty() : channelShares());

  final _savedTexts = <String>{};
  bool _savingTexts = false;

  /// Settings and History have loaded, so first-run setup can decide whether to show.
  bool _ready = false;
  bool _splashGone = false;

  // Coming back from Android settings (Fix, background running) picks up the new permission state.
  late final AppLifecycleListener _lifecycle;

  /// Saves each warned incoming text to History, marked From your texts, with the phone check's verdict.
  /// The entry keeps the text's ID, so tapping its notification later updates it rather than adding one.
  Future<void> _saveWarnedTexts() async {
    if (_savingTexts || !sms.supported) return;
    _savingTexts = true;
    try {
      for (final id in await sms.reviewIds()) {
        if (_savedTexts.contains(id) || history.entries.any((e) => e.id == id)) continue;
        final review = await sms.review(id);
        if (review?.result == null) continue;
        _savedTexts.add(id);
        if (review!.result!.risk == RiskLevel.low) continue;
        final input = CheckInput(review.body, source: CheckSource.sms, historyId: id);
        // Phone check only: nothing about a text goes online until the person opens it.
        await history.recording(const CheckPipeline().run)(input);
      }
    } catch (_) {
      // A text that can't be read now is tried again the next time the bridge reports a change.
    } finally {
      _savingTexts = false;
    }
  }

  @override
  void initState() {
    super.initState();
    sms.addListener(_saveWarnedTexts);
    sms.refresh();
    _lifecycle = AppLifecycleListener(onResume: sms.refresh);
    // Corrupt or unreadable settings keep the defaults rather than blocking the app.
    settings
        .load()
        .catchError((_) {})
        .then((_) {
          // Warm a sleeping gateway once per open, only for people who allowed online checks.
          if (settings.onlineLinkChecks) warmUpGateway(_gateway, gatewayBase);
          history.enabled = settings.saveHistory;
          return history.load();
        })
        .then((_) => _saveWarnedTexts())
        .catchError((_) {})
        .whenComplete(() {
          if (mounted) setState(() => _ready = true);
        });
  }

  @override
  void dispose() {
    sms.removeListener(_saveWarnedTexts);
    _lifecycle.dispose();
    settings.dispose();
    history.dispose();
    if (widget.gatewayClient == null) _gateway.close();
    if (widget.sms == null) sms.dispose();
    super.dispose();
  }

  /// Asks for online consent the first time a Check would go online, then runs the pipeline.
  Future<CheckResult> _runCheck(CheckInput input) async {
    if (!settings.onlineConsentAsked && needsOnline(input)) {
      final allow = await _navigator.currentState!.push(MaterialPageRoute<bool>(builder: (_) => const ConsentScreen()));
      // Back leaves it unanswered: this Check stays on the phone and the question comes back next time.
      if (allow != null) {
        try {
          await settings.update(onlineConsentAsked: true, onlineLinkChecks: allow);
        } catch (_) {}
      }
    }
    final online = settings.onlineLinkChecks;
    return CheckPipeline(
      linkChecker: online ? gatewayLinkChecker(_gateway, gatewayBase) : null,
      aiChecker: online ? gatewayAiChecker(_gateway, gatewayBase, language: () => settings.language) : null,
    ).run(input);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) => MaterialApp(
      title: 'Usisa',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigator,
      theme: buildUsisaTheme(),
      locale: Locale(settings.language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // The in-app text size multiplies the phone's own setting, on every screen.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final factor = SettingsStore.textSizes[settings.textSize]!;
        return MediaQuery(
          data: media.copyWith(textScaler: _TimesTextScaler(media.textScaler, factor)),
          child: child!,
        );
      },
      home: Stack(
        fit: StackFit.expand,
        children: [
          _Shell(
            ready: _ready,
            // Every Check from every screen is saved to History here.
            runCheck: history.recording(widget.runCheck ?? _runCheck),
            history: history,
            settings: settings,
            sms: sms,
            readScreenshot: widget.readScreenshot ?? () async => (await OcrService().readScreenshot())?.text,
            takePhoto: widget.takePhoto ?? () async => (await OcrService().readPhoto())?.text,
            shares: _shares,
            readSharedImage: widget.readSharedImage ?? (path) async => (await OcrService().readImage(XFile(path))).text,
          ),
          if (!_splashGone) LaunchSplash(ready: _ready, onDone: () => setState(() => _splashGone = true)),
        ],
      ),
    ),
  );
}

class _Shell extends StatefulWidget {
  const _Shell({
    required this.ready,
    required this.runCheck,
    required this.readScreenshot,
    required this.takePhoto,
    required this.history,
    required this.settings,
    required this.sms,
    required this.shares,
    required this.readSharedImage,
  });
  final bool ready;
  final RunCheck runCheck;
  final SmsService sms;
  final HistoryStore history;
  final SettingsStore settings;
  final ScreenshotReader readScreenshot;
  final ScreenshotReader takePhoto;
  final Stream<SharedItem> shares;
  final Future<String> Function(String path) readSharedImage;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _tab = 0;
  // One switch for the home card and Settings, backed by the native SMS bridge.
  // shortcut: without a bridge (web preview, widget tests) the switch is visual only.
  final _previewSmsOn = ValueNotifier(false);
  bool get _smsOn => widget.sms.bridgeAvailable ? widget.sms.protectionOn : _previewSmsOn.value;

  // The Check tab keeps its own page stack, so the bottom nav stays visible on its pages.
  final _checkNav = GlobalKey<NavigatorState>();

  /// Shows the Check tab and returns its navigator, emptied back to home.
  NavigatorState _checkTab({bool reset = false}) {
    if (_tab != 0) setState(() => _tab = 0);
    final nav = _checkNav.currentState!;
    if (reset) nav.popUntil((route) => route.isFirst);
    return nav;
  }

  // Once shown, setup stays up until finished, even after turning protection on changes the bridge state.
  bool _inSetup = false;
  bool get _needsSetup {
    if (widget.settings.onboarded) return false;
    _inSetup |= widget.ready && widget.sms.bridgeAvailable && widget.sms.supported && !widget.sms.wanted;
    return _inSetup;
  }

  Future<void> _finishSetup() => widget.settings.update(onboarded: true).catchError((_) {});

  Future<void> _fixSms() async {
    try {
      await widget.sms.fix(language: widget.settings.language);
    } catch (_) {
      await widget.sms.refresh();
    }
  }

  Future<void> _setSms(bool on) async {
    if (!widget.sms.bridgeAvailable) {
      _previewSmsOn.value = on;
      return setState(() {});
    }
    try {
      await widget.sms.setEnabled(on, language: widget.settings.language);
    } catch (_) {
      // A failed request leaves the switch showing what the phone really has.
      await widget.sms.refresh();
    }
  }

  late final StreamSubscription<SharedItem> _shares;
  late final StreamSubscription<String> _textAlerts;

  @override
  void initState() {
    super.initState();
    _shares = widget.shares.listen(_openShare);
    _textAlerts = widget.sms.notificationOpens.listen(_openTextAlert);
    // The notification the app was launched from.
    widget.sms
        .refresh()
        .then((_) => widget.sms.takeNotification())
        .then((id) => id == null ? null : _openTextAlert(id))
        .catchError((_) {});
  }

  @override
  void dispose() {
    _shares.cancel();
    _textAlerts.cancel();
    _previewSmsOn.dispose();
    super.dispose();
  }

  /// A tapped text notification opens Scan a message for that text and runs it (phone plus online link check).
  Future<void> _openTextAlert(String id) async {
    final review = await widget.sms.review(id).catchError((_) => null);
    if (review == null || !mounted) return;
    _checkTab(reset: true).push(
      MaterialPageRoute<void>(
        builder: (_) => PasteScreen(
          runCheck: widget.runCheck,
          source: CheckSource.sms,
          initialText: review.body,
          historyId: id,
          autoRun: true,
        ),
      ),
    );
  }

  /// A share opens the matching tile prefilled; nothing is checked until the person taps Check.
  void _openShare(SharedItem item) {
    final l = AppLocalizations.of(context);
    final image = item.imagePath;
    final text = item.text?.trim() ?? '';
    final link = phoneCheck(text).links.singleOrNull == text;
    _checkTab(reset: true).push(
      MaterialPageRoute<void>(
        builder: (_) => image != null
            ? ScreenshotScreen(
                readScreenshot: widget.readScreenshot,
                takePhoto: widget.takePhoto,
                runCheck: widget.runCheck,
                readShared: () => widget.readSharedImage(image),
              )
            : PasteScreen(
                runCheck: widget.runCheck,
                source: link ? CheckSource.link : CheckSource.share,
                initialText: text,
                title: link ? l.tileLinkTitle : null,
              ),
      ),
    );
  }

  void _startCheck(CheckKind kind) {
    if (kind == CheckKind.message || kind == CheckKind.link) {
      final link = kind == CheckKind.link;
      _checkTab().push(
        MaterialPageRoute<void>(
          builder: (_) => PasteScreen(
            runCheck: widget.runCheck,
            source: link ? CheckSource.link : CheckSource.message,
            title: link ? AppLocalizations.of(context).tileLinkTitle : null,
          ),
        ),
      );
      return;
    }
    if (kind == CheckKind.screenshot) {
      _checkTab().push(
        MaterialPageRoute<void>(
          builder: (_) => ScreenshotScreen(
            readScreenshot: widget.readScreenshot,
            takePhoto: widget.takePhoto,
            runCheck: widget.runCheck,
          ),
        ),
      );
      return;
    }
    _checkTab().push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AiScanScreen(runCheck: widget.runCheck, readScreenshot: widget.readScreenshot, takePhoto: widget.takePhoto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.sms,
      builder: (context, _) => _needsSetup
          ? SmsSetupScreen(sms: widget.sms, language: widget.settings.language, onDone: _finishSetup)
          : _tabs(l),
    );
  }

  Widget _tabs(AppLocalizations l) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status icons over the indigo home header, dark over the lavender tabs.
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _tab == 0 ? Brightness.light : Brightness.dark,
        statusBarBrightness: _tab == 0 ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: ListenableBuilder(
          listenable: widget.sms,
          builder: (context, _) => FadeIndexedStack(
            index: _tab,
            children: [
              // Back pops the Check tab's own pages before leaving the app.
              NavigatorPopHandler<Object?>(
                enabled: _tab == 0,
                onPopWithResult: (_) => _checkNav.currentState?.maybePop(),
                child: Navigator(
                  key: _checkNav,
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => ListenableBuilder(
                      listenable: Listenable.merge([widget.sms, _previewSmsOn]),
                      builder: (context, _) => HomeScreen(
                        onCheck: _startCheck,
                        smsOn: _smsOn,
                        onSmsChanged: _setSms,
                        checkedToday: widget.sms.checkedToday,
                        protectionLost: widget.sms.bridgeAvailable && widget.sms.protectionLost,
                        onFix: _fixSms,
                      ),
                    ),
                  ),
                ),
              ),
              HistoryScreen(history: widget.history, settings: widget.settings, runCheck: widget.runCheck),
              const LearnScreen(),
              SettingsScreen(settings: widget.settings, history: widget.history, smsOn: _smsOn, onSmsChanged: _setSms),
            ],
          ),
        ),
        // Flat white nav with a hairline top border; square corners so no page colour shows through.
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: UsisaColors.hairline)),
          ),
          child: NavigationBar(
            backgroundColor: Colors.white,
            selectedIndex: _tab,
            onDestinationSelected: (i) {
              // Tapping Check again returns to the Check home.
              if (i == 0 && _tab == 0) _checkNav.currentState?.popUntil((route) => route.isFirst);
              setState(() => _tab = i);
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: l.navCheck,
              ),
              NavigationDestination(icon: const Icon(Icons.history_rounded), label: l.navHistory),
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book_rounded),
                label: l.navLearn,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings_rounded),
                label: l.navSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The phone's text scaler times the in-app text size.
class _TimesTextScaler extends TextScaler {
  const _TimesTextScaler(this.phone, this.factor);
  final TextScaler phone;
  final double factor;

  @override
  double scale(double fontSize) => phone.scale(fontSize) * factor;

  @override
  @Deprecated('Use scale instead.')
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) => other is _TimesTextScaler && other.phone == phone && other.factor == factor;

  @override
  int get hashCode => Object.hash(phone, factor);
}
