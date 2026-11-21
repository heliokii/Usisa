import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'app/theme.dart';
import 'features/check/check.dart';
import 'features/check/consent_screen.dart';
import 'features/check/gateway_link_checker.dart';
import 'features/check/home_screen.dart';
import 'features/check/paste_screen.dart';
import 'features/check/screenshot_screen.dart';
import 'features/history/history_screen.dart';
import 'features/history/history_store.dart';
import 'features/scan/ocr_service.dart';
import 'features/settings/settings_store.dart';
import 'l10n/app_localizations.dart';

class UsisaApp extends StatefulWidget {
  const UsisaApp({super.key, this.storage, this.runCheck, this.readScreenshot, this.gatewayClient});

  final PrivateStorage? storage;

  /// Runs a Check; widget tests pass a fake. Without one, the real pipeline runs behind the online consent.
  final RunCheck? runCheck;

  /// HTTP client for the gateway; widget tests pass a fake.
  final http.Client? gatewayClient;

  /// Picks a picture and reads its text; widget tests pass a fake.
  final ScreenshotReader? readScreenshot;

  @override
  State<UsisaApp> createState() => _UsisaAppState();
}

class _UsisaAppState extends State<UsisaApp> {
  late final SettingsStore settings = SettingsStore(widget.storage ?? MemoryStorage());
  late final HistoryStore history = HistoryStore(settings.storage);
  late final http.Client _gateway = widget.gatewayClient ?? http.Client();
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
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
        .catchError((_) {})
        .whenComplete(() {
          if (mounted) setState(() {});
        });
  }

  @override
  void dispose() {
    settings.dispose();
    history.dispose();
    if (widget.gatewayClient == null) _gateway.close();
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
    return CheckPipeline(linkChecker: online ? gatewayLinkChecker(_gateway, gatewayBase) : null).run(input);
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
      home: _Shell(
        // Every Check from every screen is saved to History here.
        runCheck: history.recording(widget.runCheck ?? _runCheck),
        history: history,
        settings: settings,
        readScreenshot: widget.readScreenshot ?? () async => (await OcrService().readScreenshot())?.text,
      ),
    ),
  );
}

class _Shell extends StatefulWidget {
  const _Shell({required this.runCheck, required this.readScreenshot, required this.history, required this.settings});
  final RunCheck runCheck;
  final HistoryStore history;
  final SettingsStore settings;
  final ScreenshotReader readScreenshot;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _tab = 0;
  // shortcut: visual-only switch until SMS protection is wired to SmsService (ticket #40).
  bool _smsOn = false;

  void _startCheck(CheckKind kind) {
    if (kind == CheckKind.message || kind == CheckKind.link) {
      final link = kind == CheckKind.link;
      Navigator.of(context).push(
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
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ScreenshotScreen(readScreenshot: widget.readScreenshot, runCheck: widget.runCheck),
        ),
      );
      return;
    }
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.comingSoon)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
        body: IndexedStack(
          index: _tab,
          children: [
            HomeScreen(onCheck: _startCheck, smsOn: _smsOn, onSmsChanged: (on) => setState(() => _smsOn = on)),
            HistoryScreen(history: widget.history, settings: widget.settings, runCheck: widget.runCheck),
            _Placeholder(title: l.navLearn),
            _Placeholder(title: l.navSettings),
          ],
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
            onDestinationSelected: (i) => setState(() => _tab = i),
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

/// Stand-in for tabs that later tickets build.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: tt.headlineSmall),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).comingSoon, style: tt.bodyLarge),
          ],
        ),
      ),
    );
  }
}
