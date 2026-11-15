import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

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
    required this.onBack,
  });
  final HistoryStore history;
  final SettingsStore settings;
  final VoidCallback onEnable;
  final VoidCallback onScan;
  final VoidCallback onBack;
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
                          showCheckmark: false,
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
                          showCheckmark: false,
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
                          showCheckmark: false,
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
                          child: SizedBox(
                            height: 48,
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    tooltip: l.back,
                                    onPressed: widget.onBack,
                                    icon: ExcludeSemantics(
                                      child: HugeIcon(
                                        icon: HugeIcons.strokeRoundedArrowLeft01,
                                        color: UsisaTheme.forest,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    l.history,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: UsisaTheme.forest,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: l.searchHistory,
                                        onPressed: () => setState(() {
                                          _showSearch = !_showSearch;
                                          if (!_showSearch) {
                                            _search.clear();
                                            _query = '';
                                          }
                                        }),
                                        icon: ExcludeSemantics(
                                          child: HugeIcon(
                                            icon: _showSearch
                                                ? HugeIcons.strokeRoundedCancel01
                                                : HugeIcons.strokeRoundedSearch01,
                                            color: _showSearch
                                                ? UsisaTheme.coral
                                                : UsisaTheme.forest,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: ExcludeSemantics(
                                          child: HugeIcon(
                                            icon: HugeIcons.strokeRoundedMoreVertical,
                                            color: UsisaTheme.forest,
                                            size: 22,
                                          ),
                                        ),
                                        onSelected: (action) {
                                          if (action == 'filters') {
                                            _filters();
                                          } else {
                                            setState(() {
                                              _selecting = !_selecting;
                                              _selected.clear();
                                            });
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'filters',
                                            child: Row(
                                              children: [
                                                ExcludeSemantics(
                                                  child: HugeIcon(
                                                    icon: HugeIcons
                                                        .strokeRoundedFilterHorizontal,
                                                    color: UsisaTheme.forest,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Flexible(
                                                  child: Text(l.filters, softWrap: true),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'select',
                                            child: Row(
                                              children: [
                                                ExcludeSemantics(
                                                  child: HugeIcon(
                                                    icon: _selecting
                                                        ? HugeIcons
                                                            .strokeRoundedCancel01
                                                        : HugeIcons
                                                            .strokeRoundedCheckList,
                                                    color: _selecting
                                                        ? UsisaTheme.coral
                                                        : UsisaTheme.forest,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Flexible(
                                                  child: Text(
                                                    _selecting ? l.cancel : l.select,
                                                    softWrap: true,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedLock,
                                    color: UsisaTheme.forest,
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
                                    prefixIcon: ExcludeSemantics(
                                      child: HugeIcon(
                                        icon: HugeIcons.strokeRoundedSearch01,
                                        color: UsisaTheme.forest,
                                        size: 22,
                                      ),
                                    ),
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
                                      deleteIcon: _historyDeleteIcon(),
                                      onDeleted: () =>
                                          setState(() => _risk = null),
                                    ),
                                  if (_source != null)
                                    InputChip(
                                      label: Text(l.sourceLabel(_source!.name)),
                                      deleteIcon: _historyDeleteIcon(),
                                      onDeleted: () =>
                                          setState(() => _source = null),
                                    ),
                                  if (_days != 0)
                                    InputChip(
                                      label: Text(
                                        _days == 7 ? l.last7 : l.last30,
                                      ),
                                      deleteIcon: _historyDeleteIcon(),
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
                            final rowTitle = result.reviewedForAi
                                ? l.aiScan
                                : l.sourceLabel(result.source.name);
                            final sourceIcon = result.reviewedForAi
                                ? HugeIcons.strokeRoundedArtificialIntelligence04
                                : switch (result.source) {
                                    ScanSource.link =>
                                      HugeIcons.strokeRoundedLink04,
                                    ScanSource.screenshot =>
                                      HugeIcons.strokeRoundedImage03,
                                    ScanSource.sms =>
                                      HugeIcons.strokeRoundedMessageSquareMore,
                                    ScanSource.text =>
                                      HugeIcons.strokeRoundedMessageSquareMore,
                                  };
                            final iconColor =
                                _historyStatusColors(result).$3;
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
                                Dismissible(
                                  key: ValueKey(result.id),
                                  direction: _selecting
                                      ? DismissDirection.none
                                      : DismissDirection.horizontal,
                                  background: _deleteBackground(
                                    context,
                                    fromLeft: true,
                                  ),
                                  secondaryBackground: _deleteBackground(
                                    context,
                                    fromLeft: false,
                                  ),
                                  onDismissed: (_) => _deleteLater(result),
                                  child: GlassSurface(
                                    child: InkWell(
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
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 48,
                                              height: 48,
                                              child: Center(
                                                child: _selecting
                                                    ? Checkbox(
                                                        value: _selected
                                                            .contains(result.id),
                                                        activeColor:
                                                            UsisaTheme.forest,
                                                        checkColor: Colors.white,
                                                        onChanged: (_) =>
                                                            setState(() {
                                                              if (!_selected
                                                                  .add(
                                                                    result.id,
                                                                  )) {
                                                                _selected
                                                                    .remove(
                                                                      result.id,
                                                                    );
                                                              }
                                                            }),
                                                      )
                                                    : ExcludeSemantics(
                                                        child: _historySourceIcon(
                                                          sourceIcon,
                                                          iconColor,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          rowTitle,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: theme
                                                              .textTheme
                                                              .titleSmall
                                                              ?.copyWith(
                                                                color: UsisaTheme
                                                                    .forest,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      _historyStatusPill(
                                                        context,
                                                        result,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          result.text,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                color: theme
                                                                    .colorScheme
                                                                    .onSurfaceVariant,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        time,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: theme.textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
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

  Widget _historyChip(String label, int value) {
    final selected = _historyTab == value;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      backgroundColor: theme.colorScheme.surface,
      selectedColor: UsisaTheme.forest,
      side: BorderSide(
        color: selected
            ? Colors.transparent
            : UsisaTheme.forest.withValues(alpha: .08),
      ),
      shape: const StadiumBorder(),
      elevation: selected ? 0 : 1,
      pressElevation: 0,
      shadowColor: UsisaTheme.forest.withValues(alpha: .1),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: selected ? Colors.white : UsisaTheme.forest,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => setState(() => _historyTab = value),
    );
  }

  (Color, Color, Color, Color, Color) _historyStatusColors(
    ScanResult result,
  ) {
    if (result.risk == RiskLevel.low && result.hasUncheckedLinks) {
      return (
        const Color(0xFFA65DDB),
        const Color(0xFF8E4CC6),
        const Color(0xFF542080),
        Colors.white,
        const Color(0xFF542080),
      );
    }
    return switch (result.risk) {
      RiskLevel.low => (
          const Color(0xFF39A879),
          const Color(0xFF2E9B70),
          const Color(0xFF006B4B),
          Colors.white,
          const Color(0xFF006B4B),
        ),
      RiskLevel.caution => (
          const Color(0xFFFFD77A),
          const Color(0xFFFFC857),
          const Color(0xFFF5A623),
          const Color(0xFF704000),
          const Color(0xFF704000),
        ),
      RiskLevel.high => (
          const Color(0xFFFF654F),
          const Color(0xFFF2452E),
          const Color(0xFFD92D20),
          Colors.white,
          const Color(0xFFC92B1D),
        ),
    };
  }

  Widget _historyStatusPill(BuildContext context, ScanResult result) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final unknown = result.risk == RiskLevel.low && result.hasUncheckedLinks;
    final label = unknown
        ? l.unknownStatus
        : l.resultRiskLabel(result.risk.name);
    final (start, middle, end, textColor, _) =
        _historyStatusColors(result);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 116),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [start, middle, end],
            stops: const [0, .45, 1],
          ),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: start.withValues(alpha: .7)),
          boxShadow: [
            BoxShadow(
              color: middle.withValues(alpha: .16),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _historySourceIcon(List<List<dynamic>> icon, Color color) {
    return HugeIcon(
      icon: icon,
      color: color,
      size: 36,
      strokeWidth: 2.5,
    );
  }

  Widget _historyDeleteIcon() => ExcludeSemantics(
    child: HugeIcon(
      icon: HugeIcons.strokeRoundedCancel01,
      color: UsisaTheme.coral,
      size: 16,
    ),
  );

  Widget _deleteBackground(
    BuildContext context, {
    required bool fromLeft,
  }) {
    final l = AppLocalizations.of(context);
    final content = fromLeft
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedDelete01,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                l.delete,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.delete,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedDelete01,
                color: Colors.white,
                size: 22,
              ),
            ],
          );
    return Container(
      alignment: fromLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: UsisaTheme.coral,
        borderRadius: BorderRadius.circular(16),
      ),
      child: content,
    );
  }
}
