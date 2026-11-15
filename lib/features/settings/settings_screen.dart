import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/usisa_theme.dart';
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

  Widget _lowerSwitchTile(Widget tile) => ClipRect(
    child: Transform.translate(offset: const Offset(0, 4), child: tile),
  );

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
                Center(
                  child: Text(
                    l.settings,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (widget.preview) ...[
                Text(l.sessionPreview),
                const SizedBox(height: 24),
              ],
              Text(l.detection, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: GlassSurface(
                  child: _lowerSwitchTile(
                    SwitchListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      secondary: SizedBox.square(
                        dimension: 24,
                        child: Transform.translate(
                          offset: const Offset(0, 2),
                          child: const Icon(Icons.sms_outlined, size: 20),
                        ),
                      ),
                      title: Text(
                        l.autoSmsCard,
                        style: theme.textTheme.titleSmall,
                      ),
                      subtitle: Text(
                        widget.sms?.supported == true
                            ? l.autoSmsDescription
                            : l.smsOff,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: GlassSurface(
                  child: _lowerSwitchTile(
                    SwitchListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      secondary: SizedBox.square(
                        dimension: 24,
                        child: Transform.translate(
                          offset: const Offset(0, 2),
                          child: const Icon(
                            Icons.auto_awesome_outlined,
                            size: 20,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              l.aiScan,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 52,
                              maxHeight: 24,
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFFFF806A),
                                    Color(0xFFF2452E),
                                    Color(0xFFED321F),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(9999),
                                border: Border.all(
                                  color: const Color(0xFFFFB0A3)
                                      .withValues(alpha: .7),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: UsisaTheme.coral.withValues(
                                      alpha: .16,
                                    ),
                                    offset: const Offset(0, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  l.aiBeta,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        l.aiScanToggleBody,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                      value: settings.aiScanning,
                      onChanged: _busy || widget.preview
                          ? null
                          : (value) => _change(
                              () => settings.update(aiScanning: value),
                            ),
                    ),
                  ),
                ),
              ),
              if (widget.sms?.supported == true) ...[
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
              GlassSurface(
                child: Column(
                  children: [
                    if (widget.sms?.supported == true) ...[
                      SizedBox(
                        height: 56,
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          leading: SizedBox.square(
                            dimension: 24,
                            child: Transform.translate(
                              offset: const Offset(0, 6),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                size: 20,
                              ),
                            ),
                          ),
                          title: Transform.translate(
                            offset: const Offset(0, 6),
                            child: Text(
                              l.notifications,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          trailing: Transform.translate(
                            offset: const Offset(0, 6),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                            ),
                          ),
                          onTap: _busy
                              ? null
                              : () => _change(widget.sms!.requestNotifications),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                    ],
                    SizedBox(
                      height: 56,
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        leading: SizedBox.square(
                          dimension: 24,
                          child: Transform.translate(
                            offset: const Offset(0, 6),
                            child: const Icon(Icons.language_rounded, size: 20),
                          ),
                        ),
                        title: Transform.translate(
                          offset: const Offset(0, 6),
                          child: Text(
                            l.language,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        trailing: Transform.translate(
                          offset: const Offset(0, 6),
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            initialValue: settings.language,
                            tooltip: l.language,
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'en',
                                child: Text('English'),
                              ),
                              PopupMenuItem(
                                value: 'fil',
                                child: Text('Filipino'),
                              ),
                            ],
                            onSelected: _busy || widget.preview
                                ? null
                                : (value) => _change(() async {
                                    await settings.update(language: value);
                                    await widget.sms?.setLanguage(
                                      settings.language,
                                    );
                                  }),
                            child: SizedBox(
                              width: 112,
                              height: 48,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: Text(
                                      settings.language == 'en'
                                          ? 'English'
                                          : 'Filipino',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    SizedBox(
                      height: 56,
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        leading: SizedBox.square(
                          dimension: 24,
                          child: Transform.translate(
                            offset: const Offset(0, 6),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                        title: Transform.translate(
                          offset: const Offset(0, 6),
                          child: Text(
                            l.about,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        trailing: Transform.translate(
                          offset: const Offset(0, 6),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                          ),
                        ),
                        onTap: () => showModal<void>(
                          context: context,
                          configuration: FadeScaleTransitionConfiguration(
                            transitionDuration:
                                MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            reverseTransitionDuration:
                                MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 120),
                          ),
                          builder: (dialogContext) => AlertDialog(
                            title: Text(l.about),
                            content: Text(l.aboutBody),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: Text(l.back),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(l.privacy, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              GlassSurface(
                child: Column(
                  children: [
                    _lowerSwitchTile(
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        isThreeLine: true,
                        secondary: SizedBox.square(
                          dimension: 24,
                          child: Transform.translate(
                            offset: const Offset(0, 2),
                            child: const Icon(Icons.history_rounded, size: 20),
                          ),
                        ),
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
                                  value
                                      ? l.privateHistoryConsent
                                      : l.deleteBody,
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
                    ),
                    const Divider(height: 1),
                    _lowerSwitchTile(
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        isThreeLine: true,
                        secondary: SizedBox.square(
                          dimension: 24,
                          child: Transform.translate(
                            offset: const Offset(0, 2),
                            child: const Icon(
                              Icons.edit_note_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                        title: Text(
                          l.restoreDraft,
                          style: theme.textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          l.draftDetail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                    ),
                    const Divider(height: 1),
                    _lowerSwitchTile(
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        isThreeLine: true,
                        secondary: SizedBox.square(
                          dimension: 24,
                          child: Transform.translate(
                            offset: const Offset(0, 2),
                            child: const Icon(Icons.public_rounded, size: 20),
                          ),
                        ),
                        title: Text(
                          l.onlineChecks,
                          style: theme.textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          _reputation.configured
                              ? l.onlineSettingsDescription
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
                                    )) {
                                  return;
                                }
                                await _change(
                                  () =>
                                      settings.update(onlineLinkChecks: value),
                                );
                              },
                      ),
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
