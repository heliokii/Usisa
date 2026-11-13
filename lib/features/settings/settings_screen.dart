import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/page_body.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/usisa_modal.dart';
import '../../widgets/usisa_action_button.dart';
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

  Future<bool> _confirm(
    String title,
    String body,
    String action, {
    UsisaModalVariant variant = UsisaModalVariant.confirm,
  }) async =>
      (await UsisaModal.show(
        context: context,
        title: title,
        message: body,
        primaryLabel: action,
        secondaryLabel: AppLocalizations.of(context).cancel,
        variant: variant,
      )) ==
      true;
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
        bottom: false,
        child: PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.embedded) ...[
                Text(l.settings, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 12),
              ],
              if (widget.preview) ...[
                Text(l.sessionPreview),
                const SizedBox(height: 24),
              ],
              Text(l.detection, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              GlassSurface(
                child: SwitchListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  secondary: const Icon(Icons.sms_outlined),
                  title: Text(l.autoSmsCard, style: theme.textTheme.titleSmall),
                  subtitle: Text(
                    widget.sms?.enabled == true
                        ? l.smsEnabled
                        : widget.sms?.supported == true
                        ? widget.sms!.smsPermission
                              ? l.smsDisabled
                              : l.smsPermissionNeeded
                        : l.smsOff,
                    style: theme.textTheme.bodySmall,
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
                                variant: UsisaModalVariant.info,
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
              ),
              const SizedBox(height: 8),
              GlassSurface(
                child: SwitchListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  secondary: const Icon(Icons.auto_awesome_outlined),
                  title: Text(l.aiScan, style: theme.textTheme.titleSmall),
                  subtitle: Text(
                    l.aiScanToggleBody,
                    style: theme.textTheme.bodySmall,
                  ),
                  value: settings.aiScanning,
                  onChanged: _busy || widget.preview
                      ? null
                      : (value) =>
                            _change(() => settings.update(aiScanning: value)),
                ),
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
              Text(l.general, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (widget.sms?.supported == true)
                GlassSurface(
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    leading: const Icon(Icons.notifications_none_rounded),
                    title: Text(
                      l.notifications,
                      style: theme.textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      widget.sms!.notifications
                          ? l.smsNotificationsEnabled
                          : l.smsAlertsOff,
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _busy
                        ? null
                        : () => _change(widget.sms!.requestNotifications),
                  ),
                ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 20),
              Text(l.privacy, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              GlassSurface(
                child: Column(
                  children: [
                    SwitchListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      secondary: const Icon(Icons.history_rounded),
                      title: Text(
                        l.saveHistory,
                        style: theme.textTheme.titleSmall,
                      ),
                      subtitle: Text(
                        l.historyOffBody,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                      value: settings.saveHistory,
                      onChanged: _busy || widget.preview
                          ? null
                          : (value) async {
                              final confirmed = await _confirm(
                                value ? l.enableHistory : l.deleteTitle,
                                value ? l.privateHistoryConsent : l.deleteBody,
                                value ? l.enableHistory : l.delete,
                                variant: value
                                    ? UsisaModalVariant.info
                                    : UsisaModalVariant.warning,
                              );
                              if (!confirmed) return;
                              await _change(() async {
                                await settings.update(saveHistory: value);
                                await widget.history.setEnabled(value);
                              });
                            },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      secondary: const Icon(Icons.edit_note_rounded),
                      title: Text(
                        l.restoreDraft,
                        style: theme.textTheme.titleSmall,
                      ),
                      subtitle: Text(
                        l.draftDetail,
                        style: theme.textTheme.bodySmall,
                      ),
                      value: settings.restoreDraft,
                      onChanged: _busy || widget.preview
                          ? null
                          : (value) => _change(() async {
                              await settings.update(restoreDraft: value);
                              if (!value) await widget.history.clearDraft();
                            }),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      secondary: const Icon(Icons.public_rounded),
                      title: Text(
                        l.onlineChecks,
                        style: theme.textTheme.titleSmall,
                      ),
                      subtitle: Text(
                        _reputation.configured
                            ? l.onlineBody
                            : l.gatewayMissing,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
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
                                    variant: UsisaModalVariant.info,
                                  ))
                                return;
                              await _change(
                                () => settings.update(onlineLinkChecks: value),
                              );
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              UsisaActionButton.icon(
                danger: true,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(l.clearSavedData),
                onPressed: _busy
                    ? null
                    : () async {
                        if (await _confirm(
                          l.clearSavedData,
                          l.deleteBody,
                          l.delete,
                          variant: UsisaModalVariant.warning,
                        )) {
                          await _change(widget.history.clear);
                        }
                      },
              ),
              if (widget.onReviewSms != null) ...[
                const SizedBox(height: 12),
                UsisaActionButton.icon(
                  onPressed: widget.onReviewSms,
                  icon: const Icon(Icons.sms_outlined),
                  label: Text(l.recentSms),
                ),
              ],
              const SizedBox(height: 32),
              Text(l.about, style: theme.textTheme.titleMedium),
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
