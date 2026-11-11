import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import 'features/history/history_store.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/learn/learn_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/scan/ai_scan_entry_screen.dart';
import 'features/settings/settings_store.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/onboarding_screen.dart';
import 'features/sms/sms_service.dart';
import 'features/sms/sms_detection_screen.dart';
import 'features/sms/sms_review_screen.dart';
import 'l10n/app_localizations.dart';
import 'theme/usisa_theme.dart';
import 'widgets/glass_surface.dart';

class UsisaApp extends StatefulWidget {
  const UsisaApp({
    super.key,
    this.storage,
    this.isPreview = false,
    this.sms,
    this.clock,
  });
  final PrivateStorage? storage;
  final bool isPreview;
  final SmsService? sms;
  final DateTime Function()? clock;
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
    clock: widget.clock,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
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
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: UsisaTheme.cream,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: UsisaTheme.cream,
          systemNavigationBarDividerColor: UsisaTheme.cream,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: child!,
      ),
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
  Timer? _retentionTimer;
  bool _retentionActive = true;
  bool _retentionRefreshing = false;
  bool _retentionFailed = false;
  void _scheduleRetention() {
    _retentionTimer?.cancel();
    if (!mounted || !_retentionActive || _retentionRefreshing) return;
    final next = widget.history.nextExpiry;
    if (next == null) return;
    final delay = next.difference(widget.history.clock());
    _retentionTimer = Timer(
      delay <= Duration.zero ? const Duration(minutes: 1) : delay,
      _refreshRetention,
    );
  }

  Future<void> _refreshRetention() async {
    if (!mounted || !_retentionActive || _retentionRefreshing) return;
    _retentionRefreshing = true;
    try {
      await widget.history.load();
      _retentionFailed = false;
    } catch (_) {
      _retentionFailed = true;
    } finally {
      _retentionRefreshing = false;
      if (mounted) {
        setState(() {});
        _scheduleRetention();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.history.addListener(_scheduleRetention);
    _smsOpens = widget.sms.notificationOpens.listen(
      (_) => _consumeNotification(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumeNotification();
      _refreshRetention();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _retentionActive = state == AppLifecycleState.resumed;
    if (_retentionActive) {
      _consumeNotification();
      _refreshRetention();
    } else {
      _retentionTimer?.cancel();
    }
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
    widget.history.removeListener(_scheduleRetention);
    _retentionTimer?.cancel();
    _smsOpens?.cancel();
    super.dispose();
  }

  void _settings() => setState(() => index = 3);

  void _openScan(int mode, {bool aiAssisted = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScanScreen(
          history: widget.history,
          settings: widget.settings,
          sms: widget.sms,
          onManageSms: _settings,
          onReviewSms: _reviewSms,
          initialMode: mode,
          singleMode: true,
          aiAssisted: aiAssisted,
        ),
      ),
    );
  }

  void _openAi() {
    if (!widget.settings.aiScanning) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AiScanEntryScreen(
          onChooseInput: (mode) => _openScan(mode, aiAssisted: true),
        ),
      ),
    );
  }

  void _openSmsDetection() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SmsDetectionScreen(
        sms: widget.sms,
        onToggle: _setSmsEnabled,
        onOpen: _openSms,
      ),
    ),
  );

  Future<void> _setSmsEnabled(bool value) async {
    if (!widget.sms.supported) return;
    final l = AppLocalizations.of(context);
    if (value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.smsDisclosure),
          content: SingleChildScrollView(child: Text(l.smsDisclosureBody)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.enableSmsChecks),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    try {
      await widget.sms.setEnabled(value, language: widget.settings.language);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.saveFailed)));
        await widget.sms.refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final destinations = <(List<List<dynamic>>, String)>[
      (HugeIcons.strokeRoundedHome09, l.home),
      (HugeIcons.strokeRoundedClock01, l.history),
      (HugeIcons.strokeRoundedBook02, l.learn),
      (HugeIcons.strokeRoundedSettings02, l.settings),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && index != 0) setState(() => index = 0);
      },
      child: Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              if (wide && index == 0)
                SizedBox(
                  width: 96,
                  child: NavigationRail(
                    minWidth: 96,
                    scrollable: true,
                    selectedIndex: index,
                    onDestinationSelected: (i) => setState(() => index = i),
                    labelType: NavigationRailLabelType.all,
                    destinations: destinations
                        .map(
                          (d) => NavigationRailDestination(
                            icon: ExcludeSemantics(
                              child: HugeIcon(
                                icon: d.$1,
                                color: colors.onSurfaceVariant,
                                size: 24,
                              ),
                            ),
                            selectedIcon: ExcludeSemantics(
                              child: HugeIcon(
                                icon: d.$1,
                                color: UsisaTheme.coral,
                                size: 24,
                              ),
                            ),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(d.$2),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (widget.loadFailed)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(l.saveFailed),
                      ),
                    if (_retentionFailed)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(l.retentionCleanupFailed),
                      ),
                    if (index != 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(() => index = 0),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: Text(l.home),
                          ),
                        ),
                      ),
                    Expanded(
                      child: IndexedStack(
                        index: index,
                        children: [
                          HomeScreen(
                            sms: widget.sms,
                            aiEnabled: widget.settings.aiScanning,
                            onMessage: () => _openScan(0),
                            onLink: () => _openScan(1),
                            onScreenshot: () => _openScan(2),
                            onAi: _openAi,
                            onSms: _openSmsDetection,
                            onSmsToggle: _setSmsEnabled,
                            onRecentSms: _reviewSms,
                          ),
                          HistoryScreen(
                            history: widget.history,
                            settings: widget.settings,
                            onEnable: _settings,
                            onScan: () => setState(() => index = 0),
                          ),
                          const LearnScreen(),
                          SettingsScreen(
                            settings: widget.settings,
                            history: widget.history,
                            preview: widget.preview,
                            sms: widget.sms,
                            onReviewSms: _reviewSms,
                            embedded: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: wide || index != 0
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: GlassSurface(
                    borderRadius: BorderRadius.circular(32),
                    child: SizedBox(
                      height: 68,
                      child: Row(
                        children: [
                          for (var i = 0; i < destinations.length; i++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Semantics(
                                  button: true,
                                  selected: index == i,
                                  label: destinations[i].$2,
                                  child: InkWell(
                                    customBorder: const StadiumBorder(),
                                    onTap: () => setState(() => index = i),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ExcludeSemantics(
                                          child: HugeIcon(
                                            icon: destinations[i].$1,
                                            color: index == i
                                                ? UsisaTheme.coral
                                                : colors.onSurfaceVariant,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            destinations[i].$2,
                                            softWrap: false,
                                            maxLines: 1,
                                            style: TextStyle(
                                              color: index == i
                                                  ? UsisaTheme.coral
                                                  : colors.onSurfaceVariant,
                                              fontSize: 12,
                                              height: 1.2,
                                              fontWeight: index == i
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
