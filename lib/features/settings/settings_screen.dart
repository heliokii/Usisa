import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/page_body.dart';
import '../../widgets/glass_surface.dart';
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
    this.embedded = false,
  });
  final SettingsStore settings;
  final HistoryStore history;
  final bool preview;
  final SmsService? sms;
  final VoidCallback? onReviewSms;
  final bool embedded;
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
          scrollable: true,
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
      final body = SafeArea(
        top: false,
        child: PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.embedded) ...[
                Text(l.settings, style: theme.textTheme.headlineLarge),
                const SizedBox(height: 24),
              ],
              if (widget.preview) ...[
                Text(l.sessionPreview),
                const SizedBox(height: 24),
              ],
              Text(l.detection, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.autoSmsCard),
                subtitle: Text(
                  widget.sms?.enabled == true
                      ? l.smsEnabled
                      : widget.sms?.supported == true
                      ? widget.sms!.smsPermission
                            ? l.smsDisabled
                            : l.smsPermissionNeeded
                      : l.smsOff,
                ),
                value: widget.sms?.enabled == true,
                onChanged: _busy || widget.sms?.supported != true
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.aiScan),
                subtitle: Text(l.aiScanToggleBody),
                value: settings.aiScanning,
                onChanged: _busy || widget.preview
                    ? null
                    : (value) =>
                          _change(() => settings.update(aiScanning: value)),
              ),
              if (widget.sms?.supported == true) ...[
                Text(l.smsLimits),
                if (widget.sms!.degraded)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l.smsDegraded),
                  ),
                if (!widget.sms!.notifications)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _change(widget.sms!.requestNotifications),
                    child: Text(l.enableSmsAlerts),
                  ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(l.smsDetail),
                ),
              ],
              const SizedBox(height: 20),
              Text(l.general, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              if (widget.sms?.supported == true)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_none_rounded),
                  title: Text(l.notifications),
                  subtitle: Text(
                    widget.sms!.notifications
                        ? l.smsNotificationsEnabled
                        : l.smsAlertsOff,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _busy
                      ? null
                      : () => _change(widget.sms!.requestNotifications),
                ),
              const SizedBox(height: 20),
              GlassSurface(
                focusHighlight: true,
                child: DropdownButtonFormField<String>(
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
              if (widget.onReviewSms != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: widget.onReviewSms,
                  icon: const Icon(Icons.sms_outlined),
                  label: Text(l.recentSms),
                ),
              ],
              const SizedBox(height: 32),
              Text(l.about, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l.aboutBody),
            ],
          ),
        ),
      );
      if (widget.embedded) return body;
      return Scaffold(
        appBar: AppBar(title: Text(l.settings)),
        body: body,
      );
    },
  );
}
