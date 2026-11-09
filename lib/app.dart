import 'package:flutter/material.dart';

import 'features/history/history_store.dart';
import 'features/history/history_screen.dart';
import 'features/learn/learn_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/settings/settings_store.dart';
import 'features/settings/settings_screen.dart';
import 'l10n/app_localizations.dart';
import 'theme/usisa_theme.dart';

class UsisaApp extends StatefulWidget {
  const UsisaApp({super.key, this.storage, this.isPreview = false});
  final PrivateStorage? storage;
  final bool isPreview;
  @override
  State<UsisaApp> createState() => _UsisaAppState();
}

class _UsisaAppState extends State<UsisaApp> {
  late final PrivateStorage storage = widget.storage ?? MemoryStorage();
  late final SettingsStore settings = SettingsStore(storage);
  late final HistoryStore history = HistoryStore(storage);
  bool ready = false;
  bool loadFailed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await settings.load();
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
          ? _Shell(
              settings: settings,
              history: history,
              preview: widget.isPreview,
              loadFailed: loadFailed,
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
  });
  final SettingsStore settings;
  final HistoryStore history;
  final bool preview;
  final bool loadFailed;
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int index = 0;
  void _settings() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SettingsScreen(
        settings: widget.settings,
        history: widget.history,
        preview: widget.preview,
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
