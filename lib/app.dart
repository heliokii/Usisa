import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/theme.dart';
import 'features/check/check.dart';
import 'features/check/home_screen.dart';
import 'features/check/paste_screen.dart';
import 'features/check/screenshot_screen.dart';
import 'features/history/history_store.dart';
import 'features/scan/ocr_service.dart';
import 'features/settings/settings_store.dart';
import 'l10n/app_localizations.dart';

class UsisaApp extends StatefulWidget {
  const UsisaApp({super.key, this.storage, this.runCheck, this.readScreenshot});

  final PrivateStorage? storage;

  /// Runs a Check; widget tests pass a fake. Phone-only until consent and the online clients are wired (#30, #33).
  final RunCheck? runCheck;

  /// Picks a picture and reads its text; widget tests pass a fake.
  final ScreenshotReader? readScreenshot;

  @override
  State<UsisaApp> createState() => _UsisaAppState();
}

class _UsisaAppState extends State<UsisaApp> {
  late final SettingsStore settings = SettingsStore(widget.storage ?? MemoryStorage());

  @override
  void initState() {
    super.initState();
    // Corrupt or unreadable settings keep the defaults rather than blocking the app.
    settings.load().catchError((_) {}).whenComplete(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) => MaterialApp(
      title: 'Usisa',
      debugShowCheckedModeBanner: false,
      theme: buildUsisaTheme(),
      locale: Locale(settings.language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: _Shell(
        runCheck: widget.runCheck ?? const CheckPipeline().run,
        readScreenshot: widget.readScreenshot ?? () async => (await OcrService().readScreenshot())?.text,
      ),
    ),
  );
}

class _Shell extends StatefulWidget {
  const _Shell({required this.runCheck, required this.readScreenshot});
  final RunCheck runCheck;
  final ScreenshotReader readScreenshot;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _tab = 0;
  // shortcut: visual-only switch until SMS protection is wired to SmsService (ticket #40).
  bool _smsOn = false;

  void _startCheck(CheckKind kind) {
    if (kind == CheckKind.message) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PasteScreen(runCheck: widget.runCheck)));
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
            _Placeholder(title: l.navHistory),
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
