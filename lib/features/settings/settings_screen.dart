import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../history/history_screen.dart';
import '../history/history_store.dart';
import 'settings_store.dart';

/// The Settings tab: one page of cards for Display, Protection, Online checks, History and About.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.history,
    required this.smsOn,
    required this.onSmsChanged,
  });
  final SettingsStore settings;
  final HistoryStore history;

  /// The same SMS protection state as the home card.
  final bool smsOn;
  final ValueChanged<bool> onSmsChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    final muted = tt.bodyMedium?.copyWith(color: UsisaColors.inkMuted);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          children: [
            Semantics(header: true, child: Text(l.navSettings, style: tt.headlineSmall)),
            const SizedBox(height: 16),
            _Section(
              title: l.settingsDisplay,
              children: [
                _Label(l.settingsTextSize),
                RadioGroup<String>(
                  groupValue: settings.textSize,
                  onChanged: (v) => settings.update(textSize: v),
                  child: Column(
                    children: [
                      for (final (value, label) in [
                        ('normal', l.textSizeNormal),
                        ('large', l.textSizeLarge),
                        ('extraLarge', l.textSizeExtraLarge),
                      ])
                        RadioListTile<String>(value: value, title: Text(label, style: tt.bodyLarge)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(l.settingsTextSizeNote, style: muted),
                ),
                _Label(l.settingsLanguage),
                RadioGroup<String>(
                  groupValue: settings.language,
                  onChanged: (v) => settings.update(language: v),
                  child: Column(
                    children: [
                      RadioListTile<String>(value: 'en', title: Text(l.languageEnglish, style: tt.bodyLarge)),
                      RadioListTile<String>(value: 'fil', title: Text(l.languageFilipino, style: tt.bodyLarge)),
                    ],
                  ),
                ),
              ],
            ),
            _Section(
              title: l.settingsProtection,
              children: [
                // Hook for SMS protection (#42): bound to the same state as the home card.
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  title: Text(l.smsCardTitle, style: tt.titleMedium),
                  subtitle: Text(smsOn ? l.smsCardOn : l.smsCardOff, style: tt.bodyMedium),
                  value: smsOn,
                  onChanged: onSmsChanged,
                ),
              ],
            ),
            _Section(
              title: l.settingsOnline,
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  title: Text(l.settingsOnlineSwitch, style: tt.titleMedium),
                  subtitle: Text(
                    settings.onlineLinkChecks ? l.settingsOnlineOn : l.settingsOnlineOff,
                    style: tt.bodyMedium,
                  ),
                  value: settings.onlineLinkChecks,
                  // The switch is the consent: answering here means the first-use question isn't asked.
                  onChanged: (on) => settings.update(onlineLinkChecks: on, onlineConsentAsked: true),
                ),
              ],
            ),
            _Section(
              title: l.navHistory,
              children: [
                HistorySavingSwitch(history: history, settings: settings),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  title: Text(l.historyClearAll, style: tt.titleMedium?.copyWith(color: UsisaColors.danger)),
                  onTap: () => confirmClearHistory(context, history),
                ),
              ],
            ),
            _Section(
              title: l.settingsAbout,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.aboutGuide, style: tt.bodyLarge),
                      const SizedBox(height: 12),
                      Text(l.aboutData, style: tt.bodyLarge),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Card(
      color: UsisaColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UsisaRadius.card)),
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
            ),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}
