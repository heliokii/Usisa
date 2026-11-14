import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/usisa_theme.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/usisa_modal.dart';
import '../../widgets/page_body.dart';
import '../../widgets/usisa_action_button.dart';
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
  int _historyTab = 0;
  int _days = 0;
  bool _showSearch = false;
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
            (_historyTab == 0 ||
                (_historyTab == 1 &&
                    (r.source == ScanSource.text ||
                        r.source == ScanSource.sms)) ||
                (_historyTab == 2 && r.source == ScanSource.link) ||
                (_historyTab == 3 && r.reviewedForAi)) &&
            (_days == 0 ||
                widget.history.clock().difference(r.createdAt).inDays <
                    _days) &&
            r.text.toLowerCase().contains(_query.toLowerCase()),
      )
      .toList();

  Future<void> _deleteSelected() async {
    final l = AppLocalizations.of(context);
    final ids = Set<String>.of(_selected);
    final confirmed = await UsisaModal.show(
      context: context,
      title: l.selectedCount(ids.length),
      message: l.deleteBody,
      primaryLabel: l.deleteSelected,
      secondaryLabel: l.cancel,
      variant: UsisaModalVariant.warning,
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
                UsisaActionButton(
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
      final gutter = PageBody.gutterOf(context);
      final matches = _filtered;
      final now = DateUtils.dateOnly(widget.history.clock().toLocal());
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverList.list(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.history,
                                  style: theme.textTheme.headlineSmall,
                                ),
                              ),
                              IconButton(
                                tooltip: l.searchHistory,
                                onPressed: () => setState(() {
                                  _showSearch = !_showSearch;
                                  if (!_showSearch) {
                                    _search.clear();
                                    _query = '';
                                  }
                                }),
                                icon: Icon(
                                  _showSearch
                                      ? Icons.close_rounded
                                      : Icons.search_rounded,
                                ),
                              ),
                              IconButton(
                                tooltip: l.filters,
                                onPressed: _filters,
                                icon: const Icon(Icons.tune_rounded),
                              ),
                              IconButton(
                                tooltip: _selecting ? l.cancel : l.select,
                                onPressed: () => setState(() {
                                  _selecting = !_selecting;
                                  _selected.clear();
                                }),
                                icon: Icon(
                                  _selecting
                                      ? Icons.close_rounded
                                      : Icons.checklist_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!widget.history.enabled)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: gutter,
                              vertical: 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Icon(
                                    Icons.lock_outline_rounded,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  l.historyOff,
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l.historyOffBody,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 24),
                                UsisaActionButton(
                                  onPressed: widget.onEnable,
                                  child: Text(l.enableHistory),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          if (_showSearch)
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                gutter,
                                0,
                                gutter,
                                8,
                              ),
                              child: GlassSurface(
                                focusHighlight: true,
                                child: TextField(
                                  controller: _search,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: l.searchHistory,
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
                            ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _historyChip(l.historyAll, 0),
                                  const SizedBox(width: 6),
                                  _historyChip(l.message, 1),
                                  const SizedBox(width: 6),
                                  _historyChip(l.link, 2),
                                  const SizedBox(width: 6),
                                  _historyChip(l.aiScan, 3),
                                ],
                              ),
                            ),
                          ),
                          if (_selecting)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: gutter),
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  Text(l.selectedCount(_selected.length)),
                                  TextButton(
                                    onPressed: () => setState(
                                      () => _selected.addAll(
                                        matches.map((r) => r.id),
                                      ),
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
                          if (_risk != null ||
                              _source != null ||
                              _days != 0 ||
                              _query.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: gutter),
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _risk = null;
                                      _source = null;
                                      _days = 0;
                                      _query = '';
                                      _search.clear();
                                      _historyTab = 0;
                                    }),
                                    child: Text(l.clearFilters),
                                  ),
                                  if (_risk != null)
                                    InputChip(
                                      label: Text(l.riskLabel(_risk!.name)),
                                      onDeleted: () =>
                                          setState(() => _risk = null),
                                    ),
                                  if (_source != null)
                                    InputChip(
                                      label: Text(l.sourceLabel(_source!.name)),
                                      onDeleted: () =>
                                          setState(() => _source = null),
                                    ),
                                  if (_days != 0)
                                    InputChip(
                                      label: Text(
                                        _days == 7 ? l.last7 : l.last30,
                                      ),
                                      onDeleted: () =>
                                          setState(() => _days = 0),
                                    ),
                                ],
                              ),
                            ),
                          if (matches.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: gutter,
                                vertical: 20,
                              ),
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
                                  UsisaActionButton(
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
                        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
                        sliver: SliverList.separated(
                          itemCount: matches.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final result = matches[index];
                            final date = DateUtils.dateOnly(
                              result.createdAt.toLocal(),
                            );
                            final previousDate = index == 0
                                ? null
                                : DateUtils.dateOnly(
                                    matches[index - 1].createdAt.toLocal(),
                                  );
                            final (color, background, riskIcon) =
                                UsisaTheme.risk(context, result.risk);
                            final time = MaterialLocalizations.of(context)
                                .formatTimeOfDay(
                                  TimeOfDay.fromDateTime(
                                    result.createdAt.toLocal(),
                                  ),
                                );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (date != previousDate)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 10,
                                      bottom: 4,
                                    ),
                                    child: Text(
                                      DateUtils.isSameDay(date, now)
                                          ? l.today
                                          : DateUtils.isSameDay(
                                              date,
                                              now.subtract(
                                                const Duration(days: 1),
                                              ),
                                            )
                                          ? l.yesterday
                                          : MaterialLocalizations.of(context)
                                                .formatMediumDate(date),
                                      style: theme.textTheme.titleSmall,
                                    ),
                                  ),
                                GlassSurface(
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: _selecting
                                        ? Checkbox(
                                            value: _selected.contains(
                                              result.id,
                                            ),
                                            onChanged: (_) => setState(() {
                                              if (!_selected.add(result.id)) {
                                                _selected.remove(result.id);
                                              }
                                            }),
                                          )
                                        : Icon(switch (result.source) {
                                            ScanSource.link =>
                                              Icons.link_rounded,
                                            ScanSource.screenshot =>
                                              Icons.image_outlined,
                                            ScanSource.sms =>
                                              Icons.sms_outlined,
                                            ScanSource.text =>
                                              Icons.chat_bubble_outline_rounded,
                                          }, color: UsisaTheme.forest),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            l.sourceLabel(result.source.name),
                                            style: theme.textTheme.titleSmall,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: background,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                riskIcon,
                                                size: 13,
                                                color: color,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                l.riskLabel(result.risk.name),
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: color,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              result.text,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            time,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: _selecting
                                        ? null
                                        : PopupMenuButton<String>(
                                            tooltip: l.delete,
                                            onSelected: (_) =>
                                                _deleteLater(result),
                                            itemBuilder: (_) => [
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Text(l.delete),
                                              ),
                                            ],
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
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _historyChip(String label, int value) => ChoiceChip(
    label: Text(label),
    selected: _historyTab == value,
    showCheckmark: false,
    onSelected: (_) => setState(() => _historyTab = value),
  );
}
