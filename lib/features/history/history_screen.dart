import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/usisa_theme.dart';
import '../scan/result_screen.dart';
import '../scan/scan_models.dart';
import '../settings/settings_store.dart';
import 'history_store.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.history,
    required this.settings,
    required this.onEnable,
    required this.onScan,
  });
  final HistoryStore history;
  final SettingsStore settings;
  final VoidCallback onEnable;
  final VoidCallback onScan;
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  final _selected = <String>{};
  final _pending = <String, Timer>{};
  Timer? _debounce;
  String _query = '';
  RiskLevel? _risk;
  ScanSource? _source;
  int _days = 0;
  bool _selecting = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      for (final id in _pending.keys.toList()) {
        _commit(id);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _search.dispose();
    for (final entry in _pending.entries) {
      entry.value.cancel();
      unawaited(widget.history.delete({entry.key}).catchError((Object _) {}));
    }
    super.dispose();
  }

  void _error() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saveFailed)),
      );
    }
  }

  Future<void> _commit(String id) async {
    _pending.remove(id)?.cancel();
    try {
      await widget.history.delete({id});
    } catch (_) {
      _error();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _deleteLater(ScanResult result) {
    setState(
      () => _pending[result.id] = Timer(
        const Duration(seconds: 5),
        () => _commit(result.id),
      ),
    );
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(l.deletedScan),
        action: SnackBarAction(
          label: l.undo,
          onPressed: () {
            _pending.remove(result.id)?.cancel();
            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  List<ScanResult> get _filtered => widget.history.entries
      .where(
        (r) =>
            !_pending.containsKey(r.id) &&
            (_risk == null || r.risk == _risk) &&
            (_source == null || r.source == _source) &&
            (_days == 0 ||
                DateTime.now().difference(r.createdAt).inDays < _days) &&
            r.text.toLowerCase().contains(_query.toLowerCase()),
      )
      .toList();

  Future<void> _deleteSelected() async {
    final l = AppLocalizations.of(context);
    final ids = Set<String>.of(_selected);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.selectedCount(ids.length)),
        content: Text(l.deleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.deleteSelected),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await widget.history.delete(ids);
      if (mounted) {
        setState(() {
          _selected.clear();
          _selecting = false;
        });
      }
    } catch (_) {
      _error();
    }
  }

  void _filters() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.filters, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [null, ...RiskLevel.values]
                      .map(
                        (r) => ChoiceChip(
                          label: Text(
                            r == null ? l.allRisk : l.riskLabel(r.name),
                          ),
                          selected: _risk == r,
                          onSelected: (_) {
                            setState(() => _risk = r);
                            update(() {});
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [null, ...ScanSource.values]
                      .map(
                        (s) => ChoiceChip(
                          label: Text(
                            s == null ? l.allSources : l.sourceLabel(s.name),
                          ),
                          selected: _source == s,
                          onSelected: (_) {
                            setState(() => _source = s);
                            update(() {});
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [0, 7, 30]
                      .map(
                        (d) => ChoiceChip(
                          label: Text(
                            d == 0
                                ? l.allDates
                                : d == 7
                                ? l.last7
                                : l.last30,
                          ),
                          selected: _days == d,
                          onSelected: (_) {
                            setState(() => _days = d);
                            update(() {});
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.continueAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.history,
    builder: (context, _) {
      final l = AppLocalizations.of(context);
      final theme = Theme.of(context);
      final matches = _filtered;
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: CustomScrollView(
            slivers: [
              SliverList.list(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Text(
                      l.historyHeading,
                      style: theme.textTheme.headlineLarge,
                    ),
                  ),
                  if (!widget.history.enabled)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Icon(Icons.lock_outline_rounded, size: 40),
                          ),
                          const SizedBox(height: 20),
                          Text(l.historyOff, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 12),
                          Text(
                            l.historyOffBody,
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: widget.onEnable,
                            child: Text(l.enableHistory),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          labelText: l.searchHistory,
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          _debounce?.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 300),
                            () {
                              if (mounted) {
                                setState(() => _query = value);
                              }
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _filters,
                            icon: const Icon(Icons.tune_rounded),
                            label: Text(l.filters),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _selecting = !_selecting;
                              _selected.clear();
                            }),
                            child: Text(_selecting ? l.cancel : l.select),
                          ),
                          if (_risk != null ||
                              _source != null ||
                              _days != 0 ||
                              _query.isNotEmpty)
                            TextButton(
                              onPressed: () => setState(() {
                                _risk = null;
                                _source = null;
                                _days = 0;
                                _query = '';
                                _search.clear();
                              }),
                              child: Text(l.clearFilters),
                            ),
                          if (_risk != null)
                            InputChip(
                              label: Text(l.riskLabel(_risk!.name)),
                              onDeleted: () => setState(() => _risk = null),
                            ),
                          if (_source != null)
                            InputChip(
                              label: Text(l.sourceLabel(_source!.name)),
                              onDeleted: () => setState(() => _source = null),
                            ),
                          if (_days != 0)
                            InputChip(
                              label: Text(_days == 7 ? l.last7 : l.last30),
                              onDeleted: () => setState(() => _days = 0),
                            ),
                        ],
                      ),
                    ),
                    if (_selecting)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            Text(l.selectedCount(_selected.length)),
                            TextButton(
                              onPressed: () => setState(
                                () =>
                                    _selected.addAll(matches.map((r) => r.id)),
                              ),
                              child: Text(l.selectAll),
                            ),
                            TextButton(
                              onPressed: _selected.isEmpty
                                  ? null
                                  : _deleteSelected,
                              child: Text(l.deleteSelected),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(l.resultCount(matches.length)),
                    ),
                    if (matches.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            Text(
                              widget.history.entries.isEmpty
                                  ? l.noHistory
                                  : l.noMatches,
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Text(l.noHistoryBody),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: widget.onScan,
                              child: Text(l.checkMessage),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
              if (widget.history.enabled && matches.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  sliver: SliverList.separated(
                    itemCount: matches.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final result = matches[index];
                      final (color, _, icon) = UsisaTheme.risk(
                        context,
                        result.risk,
                      );
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _selecting
                            ? Checkbox(
                                value: _selected.contains(result.id),
                                onChanged: (_) => setState(() {
                                  if (!_selected.add(result.id)) {
                                    _selected.remove(result.id);
                                  }
                                }),
                              )
                            : Icon(icon, color: color),
                        title: Text(
                          l.riskLabel(result.risk.name),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${result.text}\n${l.sourceLabel(result.source.name)} • ${MaterialLocalizations.of(context).formatMediumDate(result.createdAt.toLocal())}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: _selecting
                            ? null
                            : IconButton(
                                tooltip: l.delete,
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () => _deleteLater(result),
                              ),
                        onLongPress: () => setState(() {
                          _selecting = true;
                          _selected.add(result.id);
                        }),
                        onTap: () {
                          if (_selecting) {
                            setState(() {
                              if (!_selected.add(result.id)) {
                                _selected.remove(result.id);
                              }
                            });
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ResultScreen(
                                  result: result,
                                  history: widget.history,
                                  settings: widget.settings,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
