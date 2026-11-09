import 'dart:async';

import 'package:flutter/material.dart';

import 'features/history/history_store.dart';
import 'features/history/history_screen.dart';
import 'features/learn/learn_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/settings/settings_store.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/onboarding_screen.dart';
import 'features/sms/sms_service.dart';
import 'features/sms/sms_review_screen.dart';
import 'l10n/app_localizations.dart';
import 'theme/usisa_theme.dart';

class UsisaApp extends StatefulWidget {
  const UsisaApp({super.key, this.storage, this.isPreview = false, this.sms});
  final PrivateStorage? storage;
  final bool isPreview;
  final SmsService? sms;
  @override
  State<UsisaApp> createState() => _UsisaAppState();
}

class _UsisaAppState extends State<UsisaApp> {
  late final PrivateStorage storage = widget.storage ?? MemoryStorage();
  late final SettingsStore settings = SettingsStore(storage);
  late final SmsService sms =
      widget.sms ??
      SmsService(
        nativePlatform: storage is SecureStorage && !widget.isPreview
            ? null
            : false,
      );
  // shortcut: history has one foreground writer; add a durable shared gate before background history writes.
  late final HistoryStore history = HistoryStore(
    storage,
    clearSmsPrivacy: () async {
      if (sms.nativePlatform) await sms.invalidatePrivacy();
    },
  );
  bool ready = false;
  bool loadFailed = false;
  bool sessionStarted = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await settings.load();
      await sms.refresh();
      await sms.setLanguage(settings.language);
      history.enabled = settings.saveHistory;
      await history.load();
    } catch (_) {
      loadFailed = true;
    }
    if (mounted) {
      setState(() => ready = true);
    }
  }

  @override
  void dispose() {
    settings.dispose();
    history.dispose();
    sms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) => MaterialApp(
      title: 'Usisa',
      debugShowCheckedModeBanner: false,
      theme: UsisaTheme.light,
      darkTheme: UsisaTheme.dark,
      themeMode: settings.theme,
      locale: Locale(settings.language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: ready
          ? !settings.onboarded && !sessionStarted
                ? OnboardingScreen(
                    settings: settings,
                    onStart: () => setState(() => sessionStarted = true),
                  )
                : _Shell(
                    settings: settings,
                    history: history,
                    preview: widget.isPreview,
                    loadFailed: loadFailed,
                    sms: sms,
                  )
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
  );
}

class _Shell extends StatefulWidget {
  const _Shell({
    required this.settings,
    required this.history,
    required this.preview,
    required this.loadFailed,
    required this.sms,
  });
  final SettingsStore settings;
  final HistoryStore history;
  final bool preview;
  final bool loadFailed;
  final SmsService sms;
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> with WidgetsBindingObserver {
  int index = 0;
  StreamSubscription<String>? _smsOpens;
  bool _consumingNotification = false;
  bool _smsOpen = false;
  String? _openSmsId;
  String? _queuedSmsId;
  bool _consumeAgain = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _smsOpens = widget.sms.notificationOpens.listen(
      (_) => _consumeNotification(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumeNotification());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _consumeNotification();
  }

  Future<void> _consumeNotification() async {
    if (!mounted) return;
    if (_consumingNotification) {
      _consumeAgain = true;
      return;
    }
    _consumingNotification = true;
    String? id;
    try {
      await widget.sms.refresh();
      id = await widget.sms.takeNotification();
    } catch (_) {
      // The normal scan screen remains usable when the Android bridge is unavailable.
    } finally {
      _consumingNotification = false;
      if (_consumeAgain && mounted) {
        _consumeAgain = false;
        scheduleMicrotask(_consumeNotification);
      }
    }
    if (!mounted || id == null || id == _openSmsId) return;
    if (_smsOpen) {
      _queuedSmsId = id;
      return;
    }
    unawaited(_openSms(id));
  }

  Future<void> _openSms(String id) async {
    if (_smsOpen || !mounted) return;
    _smsOpen = true;
    _openSmsId = id;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SmsReviewScreen(
            id: id,
            sms: widget.sms,
            history: widget.history,
            settings: widget.settings,
          ),
        ),
      );
    } finally {
      _smsOpen = false;
      _openSmsId = null;
      final next = _queuedSmsId;
      _queuedSmsId = null;
      if (mounted && next != null) {
        unawaited(_openSms(next));
      } else if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _consumeNotification(),
        );
      }
    }
  }

  void _reviewSms() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SmsInboxScreen(sms: widget.sms, onOpen: _openSms),
    ),
  );
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _smsOpens?.cancel();
    super.dispose();
  }

  void _settings() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SettingsScreen(
        settings: widget.settings,
        history: widget.history,
        preview: widget.preview,
        sms: widget.sms,
        onReviewSms: _reviewSms,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final destinations = [
      (Icons.search_rounded, l.scan),
      (Icons.history_rounded, l.history),
      (Icons.menu_book_outlined, l.learn),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 600;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Text('Usisa', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _settings,
            tooltip: l.settings,
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Row(
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: (i) => setState(() => index = i),
                labelType: NavigationRailLabelType.all,
                destinations: destinations
                    .map(
                      (d) => NavigationRailDestination(
                        icon: Icon(d.$1),
                        label: Text(d.$2),
                      ),
                    )
                    .toList(),
              ),
            Expanded(
              child: Column(
                children: [
                  if (widget.loadFailed)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(l.saveFailed),
                    ),
                  Expanded(
                    child: IndexedStack(
                      index: index,
                      children: [
                        ScanScreen(
                          history: widget.history,
                          settings: widget.settings,
                          sms: widget.sms,
                          onManageSms: _settings,
                          onReviewSms: _reviewSms,
                        ),
                        HistoryScreen(
                          history: widget.history,
                          settings: widget.settings,
                          onEnable: _settings,
                          onScan: () => setState(() => index = 0),
                        ),
                        const LearnScreen(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => setState(() => index = i),
              destinations: destinations
                  .map(
                    (d) => NavigationDestination(icon: Icon(d.$1), label: d.$2),
                  )
                  .toList(),
            ),
    );
  }
}
