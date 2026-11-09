import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/page_body.dart';
import '../history/history_store.dart';
import '../scan/reputation_client.dart';
import '../sms/sms_service.dart';
import 'settings_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.history,
    this.preview = false,
    this.sms,
    this.onReviewSms,
  });
  final SettingsStore settings;
  final HistoryStore history;
  final bool preview;
  final SmsService? sms;
  final VoidCallback? onReviewSms;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  final _reputation = ReputationClient();
  @override
  void dispose() {
    _reputation.close();
    super.dispose();
  }

  Future<void> _change(Future<void> Function() work) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await work();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).saveFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      widget.settings,
      if (widget.sms != null) widget.sms!,
    ]),
    builder: (context, _) {
      final l = AppLocalizations.of(context);
      final settings = widget.settings;
      final theme = Theme.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(l.settings)),
        body: SafeArea(
          top: false,
          child: PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.preview) ...[
                  Text(l.sessionPreview),
                  const SizedBox(height: 24),
                ],
                Text(l.appearance, style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<ThemeMode>(
                  initialValue: settings.theme,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.appearance),
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text(l.systemTheme),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text(l.lightTheme),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text(l.darkTheme),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => _change(() => settings.update(theme: value)),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: settings.language,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.language),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'fil', child: Text('Filipino')),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => _change(() async {
                          await settings.update(language: value);
                          await widget.sms?.setLanguage(settings.language);
                        }),
                ),
                const SizedBox(height: 32),
                Text(l.privacy, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.saveHistory),
                  subtitle: Text(l.historyOffBody),
                  value: settings.saveHistory,
                  onChanged: _busy || widget.preview
                      ? null
                      : (value) async {
                          final confirmed = await _confirm(
                            value ? l.enableHistory : l.deleteTitle,
                            value ? l.privateHistoryConsent : l.deleteBody,
                            value ? l.enableHistory : l.delete,
                          );
                          if (!confirmed) {
                            return;
                          }
                          await _change(() async {
                            await settings.update(saveHistory: value);
                            await widget.history.setEnabled(value);
                          });
                        },
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.restoreDraft),
                  subtitle: Text(l.draftDetail),
                  value: settings.restoreDraft,
                  onChanged: _busy || widget.preview
                      ? null
                      : (value) => _change(() async {
                          await settings.update(restoreDraft: value);
                          if (!value) {
                            await widget.history.clearDraft();
                          }
                        }),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.onlineChecks),
                  subtitle: Text(
                    _reputation.configured ? l.onlineBody : l.gatewayMissing,
                  ),
                  value: settings.onlineLinkChecks,
                  onChanged: _busy || !_reputation.configured
                      ? null
                      : (value) async {
                          if (value &&
                              !await _confirm(
                                l.onlineDisclosure,
                                l.onlineBody,
                                l.enableOnline,
                              )) {
                            return;
                          }
                          await _change(
                            () => settings.update(onlineLinkChecks: value),
                          );
                        },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(l.clearSavedData),
                  onPressed: _busy
                      ? null
                      : () async {
                          if (await _confirm(
                            l.clearSavedData,
                            l.deleteBody,
                            l.delete,
                          )) {
                            await _change(widget.history.clear);
                          }
                        },
                ),
                const SizedBox(height: 32),
                if (widget.sms?.supported == true) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.smsHeading),
                    subtitle: Text(
                      widget.sms!.enabled
                          ? l.smsEnabled
                          : widget.sms!.smsPermission
                          ? l.smsDisabled
                          : l.smsPermissionNeeded,
                    ),
                    value: widget.sms!.enabled,
                    onChanged: _busy
                        ? null
                        : (value) async {
                            if (value &&
                                !await _confirm(
                                  l.smsDisclosure,
                                  l.smsDisclosureBody,
                                  l.enableSmsChecks,
                                )) {
                              return;
                            }
                            await _change(
                              () => widget.sms!.setEnabled(
                                value,
                                language: settings.language,
                              ),
                            );
                          },
                  ),
                  Text(l.smsLimits),
                  if (widget.sms!.degraded)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(l.smsDegraded),
                    ),
                  if (!widget.sms!.notifications) ...[
                    const SizedBox(height: 12),
                    Text(l.smsAlertsOff),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _change(widget.sms!.requestNotifications),
                      child: Text(l.enableSmsAlerts),
                    ),
                  ],
                  if (widget.onReviewSms != null)
                    OutlinedButton.icon(
                      onPressed: widget.onReviewSms,
                      icon: const Icon(Icons.sms_outlined),
                      label: Text(l.recentSms),
                    ),
                ] else ...[
                  Text(l.smsOff, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(l.smsDetail),
                ],
                const SizedBox(height: 32),
                Text(l.about, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(l.aboutBody),
              ],
            ),
          ),
        ),
      );
    },
  );
}
