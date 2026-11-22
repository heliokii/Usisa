import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../check/check.dart';
import '../check/verdict_screen.dart';
import '../settings/settings_store.dart';
import 'history_store.dart';

/// The History tab: past checks, newest first, with delete, clear all and the saving switch.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.history, required this.settings, required this.runCheck});
  final HistoryStore history;
  final SettingsStore settings;

  /// Used by Check again; it saves the fresh result like any other Check.
  final RunCheck runCheck;

  void _open(BuildContext context, HistoryEntry entry) {
    var busy = false;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screen) => VerdictScreen(
          result: entry.result,
          checkedAt: entry.checkedAt,
          onCheckAgain: () async {
            if (busy) return;
            busy = true;
            try {
              final fresh = await runCheck(CheckInput(entry.result.text, source: entry.source, aiScan: entry.aiScan));
              if (!screen.mounted) return;
              await Navigator.of(screen)
                  .pushReplacement(MaterialPageRoute<void>(builder: (_) => VerdictScreen(result: fresh)));
            } finally {
              busy = false;
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: Listenable.merge([history, settings]),
      builder: (context, _) {
        final entries = history.entries;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            children: [
              Semantics(header: true, child: Text(l.navHistory, style: tt.headlineSmall)),
              const SizedBox(height: 4),
              Text(l.historySavedOnPhone, style: tt.bodyLarge?.copyWith(color: UsisaColors.inkMuted)),
              const SizedBox(height: 16),
              _Card(
                child: HistorySavingSwitch(history: history, settings: settings),
              ),
              const SizedBox(height: 16),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    settings.saveHistory ? l.historyEmpty : l.historyOff,
                    style: tt.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => confirmClearHistory(context, history),
                    child: Text(l.historyClearAll),
                  ),
                ),
                for (final (i, entry) in entries.indexed)
                  Padding(
                    key: ValueKey(entry.id),
                    padding: const EdgeInsets.only(bottom: 12),
                    // The first screenful rises in one after another; later ones just appear.
                    child: EnterMotion(
                      index: i < 8 ? i : 0,
                      child: _EntryCard(
                        entry: entry,
                        onOpen: () => _open(context, entry),
                        onDelete: () => history.delete({entry.id}),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// The "Save my checks" switch, shared by the History tab and Settings. Off also clears History.
class HistorySavingSwitch extends StatelessWidget {
  const HistorySavingSwitch({super.key, required this.history, required this.settings});
  final HistoryStore history;
  final SettingsStore settings;

  Future<void> _setSaving(bool on) async {
    await settings.update(saveHistory: on);
    await history.setEnabled(on);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(l.historySaveSwitch, style: tt.titleMedium),
        subtitle: Text(l.historySaveNote, style: tt.bodyMedium),
        value: settings.saveHistory,
        onChanged: _setSaving,
      ),
    );
  }
}

/// Asks before clearing every saved check.
Future<void> confirmClearHistory(BuildContext context, HistoryStore history) async {
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.historyClearTitle),
      content: Text(l.historyClearBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: UsisaColors.danger),
          child: Text(l.historyClearAll),
        ),
      ],
    ),
  );
  if (ok == true) await history.clear();
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    color: UsisaColors.surface,
    elevation: 0,
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UsisaRadius.card)),
    child: child,
  );
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.onOpen, required this.onDelete});
  final HistoryEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    final muted = tt.bodyMedium?.copyWith(color: UsisaColors.inkMuted);
    final (color, _, icon) = verdictLooks[entry.result.verdict]!;
    return PressScale(
      child: _Card(
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.verdictWord(entry.result.verdict.name),
                        style: tt.titleMedium?.copyWith(color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: Text(entry.result.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.bodyLarge),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formatCheckedAt(context, entry.checkedAt), style: muted),
                          if (entry.source == CheckSource.sms) Text(l.fromYourTexts, style: muted),
                        ],
                      ),
                    ),
                    TextButton(onPressed: onDelete, child: Text(l.historyDelete)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
