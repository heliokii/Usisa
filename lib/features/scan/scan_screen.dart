import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/page_body.dart';
import '../history/history_store.dart';
import '../settings/settings_store.dart';
import '../sms/sms_service.dart';
import 'scan_controller.dart';
import 'scan_models.dart';
import 'result_screen.dart';
import 'ocr_service.dart';
import 'ocr_models.dart';
import 'screenshot_review_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.history,
    required this.settings,
    this.sms,
    this.onManageSms,
    this.onReviewSms,
    this.ocr,
  });
  final HistoryStore history;
  final SettingsStore settings;
  final SmsService? sms;
  final VoidCallback? onManageSms;
  final VoidCallback? onReviewSms;
  final OcrService? ocr;
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  final _inputs = [TextEditingController(), TextEditingController()];
  final _scan = ScanController();
  late final _ocr = widget.ocr ?? OcrService();
  bool _reading = false;
  OcrDraft? _recovered;
  int _ocrRevision = 0;
  int _mode = 0;
  bool _opening = false;
  Timer? _draftTimer;
  int _draftRevision = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.settings.addListener(_settingsChanged);
    if (widget.settings.restoreDraft) {
      _restoreDraft();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverScreenshot());
  }

  Future<void> _restoreDraft() async {
    final generation = widget.history.generation;
    final revision = _draftRevision;
    try {
      final text = await widget.history.loadDraft();
      if (mounted &&
          generation == widget.history.generation &&
          revision == _draftRevision &&
          text != null) {
        _inputs[0].text = text;
      }
    } catch (_) {
      _draftError();
    }
  }

  void _draftError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saveFailed)),
      );
    }
  }

  void _settingsChanged() {
    if (!widget.settings.restoreDraft) {
      _draftTimer?.cancel();
    } else if (_inputs[0].text.isNotEmpty) {
      _scheduleDraft();
    }
  }

  void _scheduleDraft() {
    _draftRevision++;
    _draftTimer?.cancel();
    if (!widget.settings.restoreDraft) {
      return;
    }
    final text = _inputs[0].text;
    final generation = widget.history.generation;
    _draftTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!widget.settings.restoreDraft) {
        return;
      }
      try {
        await widget.history.saveDraft(text, expectedGeneration: generation);
      } catch (_) {
        _draftError();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.settings.removeListener(_settingsChanged);
    _draftTimer?.cancel();
    for (final input in _inputs) {
      input.dispose();
    }
    _scan.dispose();
    super.dispose();
  }

  Future<void> _check({ScanInput? reviewed}) async {
    if (_scan.busy || _opening) {
      return;
    }
    FocusScope.of(context).unfocus();
    final generation = widget.history.generation;
    final retain = widget.history.enabled;
    await _scan.check(
      reviewed ??
          ScanInput(
            _inputs[_mode].text,
            source: _mode == 1 ? ScanSource.link : ScanSource.text,
          ),
    );
    if (!mounted || _scan.result == null) {
      return;
    }
    _opening = true;
    final result = _scan.result!;
    var saved = true;
    try {
      if (retain) {
        await widget.history.save(result, expectedGeneration: generation);
      }
    } catch (_) {
      saved = false;
    }
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          result: result,
          saved: saved,
          history: widget.history,
          settings: widget.settings,
        ),
      ),
    );
    _opening = false;
  }

  void _ocrError(Object error) {
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l.errorMessage(error is ScanException ? error.code : 'ocrFailed'),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recoverScreenshot();
  }

  Future<void> _recoverScreenshot() async {
    if (!mounted || !_ocr.available || _reading || _recovered != null) return;
    setState(() => _reading = true);
    final revision = ++_ocrRevision;
    try {
      final draft = await _ocr.recoverScreenshot();
      if (mounted && revision == _ocrRevision) {
        setState(() => _recovered = draft);
      }
    } catch (error) {
      if (mounted && revision == _ocrRevision) _ocrError(error);
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  Future<void> _importScreenshot({OcrDraft? recovered}) async {
    if (_reading) {
      return;
    }
    setState(() {
      _reading = true;
      if (recovered != null) {
        _recovered = null;
        _mode = 2;
      }
    });
    final revision = ++_ocrRevision;
    try {
      final draft = recovered ?? await _ocr.readScreenshot();
      if (!mounted || draft == null || revision != _ocrRevision) {
        return;
      }
      final text = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => ScreenshotReviewScreen(draft: draft)),
      );
      if (mounted && text != null && revision == _ocrRevision) {
        await _check(reviewed: ScanInput(text, source: ScanSource.screenshot));
      }
    } catch (e) {
      if (mounted && revision == _ocrRevision) {
        _ocrError(e);
      }
    } finally {
      if (mounted) {
        setState(() => _reading = false);
      }
    }
  }

  Future<void> _paste() async {
    final mode = _mode;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted || data?.text == null) {
        return;
      }
      _inputs[mode].text = data!.text!;
      if (mode == 0) {
        _scheduleDraft();
      }
      _scan.cancel();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).errorMessage('clipboard'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _scan,
    builder: (context, _) {
      final l = AppLocalizations.of(context);
      final theme = Theme.of(context);
      return PageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.scanHeading, style: theme.textTheme.headlineLarge),
            const SizedBox(height: 12),
            Text(l.scanIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.localPrivate,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (_recovered != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.image_outlined),
                title: Text(l.reviewRecoveredScreenshot),
                onTap: _reading
                    ? null
                    : () => _importScreenshot(recovered: _recovered),
                trailing: IconButton(
                  tooltip: l.discardRecoveredScreenshot,
                  onPressed: _reading
                      ? null
                      : () => setState(() => _recovered = null),
                  icon: const Icon(Icons.close),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [l.message, l.link, l.screenshot]
                  .asMap()
                  .entries
                  .map(
                    (e) => ChoiceChip(
                      label: Text(e.value),
                      selected: _mode == e.key,
                      showCheckmark: false,
                      onSelected: _scan.busy || _reading
                          ? null
                          : (_) => setState(() => _mode = e.key),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            if (_mode < 2) ...[
              TextField(
                controller: _inputs[_mode],
                key: ValueKey(_mode),
                enabled: !_scan.busy,
                minLines: _mode == 1 ? 2 : 6,
                maxLines: _mode == 1 ? 5 : 12,
                style: theme.textTheme.bodyLarge,
                keyboardType: _mode == 1
                    ? TextInputType.url
                    : TextInputType.multiline,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: _mode == 1 ? l.link : l.message,
                  hintText: _mode == 1 ? 'https://example.com' : l.inputHint,
                  errorText: _scan.error == null
                      ? null
                      : l.errorMessage(_scan.error!),
                  errorMaxLines: 5,
                ),
                onChanged: (_) {
                  if (_mode == 0) {
                    _scheduleDraft();
                  }
                  if (_scan.error != null) {
                    setState(() => _scan.error = null);
                  }
                },
              ),
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _scan.busy ? null : _paste,
                    icon: const Icon(Icons.content_paste_rounded, size: 18),
                    label: Text(_mode == 1 ? l.pasteLink : l.pasteText),
                  ),
                  TextButton(
                    onPressed: _scan.busy
                        ? null
                        : () async {
                            _inputs[_mode].clear();
                            if (_mode == 0) {
                              _draftTimer?.cancel();
                              _draftRevision++;
                              try {
                                await widget.history.clearDraft();
                              } catch (_) {
                                _draftError();
                              }
                            }
                            if (!mounted) return;
                            setState(() => _scan.error = null);
                          },
                    child: Text(l.clear),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _scan.busy ? null : _check,
                icon: _scan.busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(
                  _scan.busy
                      ? l.checking
                      : _mode == 1
                      ? l.checkLink
                      : l.checkMessage,
                ),
              ),
              if (_scan.busy)
                TextButton(onPressed: _scan.cancel, child: Text(l.cancel)),
            ] else ...[
              Text(l.screenshotIntro, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              if (!_ocr.available) Text(l.ocrNativeOnly),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: !_ocr.available || _reading
                    ? null
                    : _importScreenshot,
                icon: const Icon(Icons.image_outlined),
                label: Text(_reading ? l.readingImage : l.chooseScreenshot),
              ),
              if (_reading)
                TextButton(
                  onPressed: () => setState(() {
                    _ocrRevision++;
                    _mode = 0;
                  }),
                  child: Text(l.cancel),
                ),
            ],
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: widget.sms ?? widget.settings,
              builder: (context, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sms_outlined, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.sms?.supported == true
                              ? widget.sms!.enabled
                                    ? l.smsEnabled
                                    : l.smsDisabled
                              : l.smsOff,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.sms?.supported == true
                              ? widget.sms!.degraded
                                    ? l.smsDegraded
                                    : l.smsLimits
                              : l.smsDetail,
                        ),
                        if (widget.sms?.supported == true) ...[
                          if (!widget.sms!.notifications) Text(l.smsAlertsOff),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: widget.onManageSms,
                                child: Text(l.manageSms),
                              ),
                              TextButton(
                                onPressed: widget.onReviewSms,
                                child: Text(l.recentSms),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(l.reminderTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l.reminderBody),
          ],
        ),
      );
    },
  );
}
