import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/page_body.dart';
import '../../widgets/glass_surface.dart';
import '../history/history_store.dart';
import '../settings/settings_store.dart';
import '../sms/sms_service.dart';
import 'scan_controller.dart';
import 'scan_models.dart';
import 'result_screen.dart';
import 'ocr_service.dart';
import 'ocr_models.dart';
import 'screenshot_review_screen.dart';
import 'ai_models.dart';
import 'ai_scan_client.dart';
import 'ai_review_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.history,
    required this.settings,
    this.sms,
    this.onManageSms,
    this.onReviewSms,
    this.ocr,
    this.aiFactory,
    this.initialMode = 0,
    this.singleMode = true,
    this.aiAssisted = false,
  });
  final HistoryStore history;
  final SettingsStore settings;
  final SmsService? sms;
  final VoidCallback? onManageSms;
  final VoidCallback? onReviewSms;
  final OcrService? ocr;
  final AiScanClient Function()? aiFactory;
  final int initialMode;
  final bool singleMode;
  final bool aiAssisted;
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
  late int _mode = widget.initialMode;
  bool _opening = false;
  late bool _aiAssisted = widget.aiAssisted;
  int _aiRevision = 0;
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
    var value =
        reviewed ??
        ScanInput(
          _inputs[_mode].text,
          source: _mode == 1 ? ScanSource.link : ScanSource.text,
        );
    var sendAi = false;
    if (_aiAssisted) {
      _opening = true;
      final choice = await Navigator.of(context).push<AiReviewChoice>(
        MaterialPageRoute(builder: (_) => AiReviewScreen(input: value)),
      );
      _opening = false;
      if (!mounted ||
          choice == null ||
          generation != widget.history.generation) {
        return;
      }
      value = ScanInput(choice.text, source: value.source);
      sendAi = choice.send;
      if (reviewed == null) _inputs[_mode].text = value.text;
    }
    await _scan.check(value);
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
          aiFactory: widget.aiFactory,
          initialAiInput: sendAi
              ? ReviewedAiInput(
                  text: result.text,
                  source: result.source,
                  responseLanguage:
                      Localizations.localeOf(context).languageCode == 'fil'
                      ? 'fil'
                      : 'en',
                  inputRevision: ++_aiRevision,
                  privacyGeneration: generation,
                )
              : null,
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
      final title = widget.aiAssisted
          ? l.aiScan
          : _mode == 1
          ? l.linkCheckerTitle
          : _mode == 2
          ? l.scanScreenshotCard
          : l.scanMessageCard;
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: widget.aiAssisted
              ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Text(
                        l.aiBeta,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ]
              : null,
        ),
        body: SafeArea(
          top: false,
          child: PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_mode != 1) ...[
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
                          _aiAssisted ? l.aiManualOnly : l.localPrivate,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ] else
                  const SizedBox(height: 8),
                if (_recovered != null) ...[
                  GlassSurface(
                    child: ListTile(
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
                  ),
                  const SizedBox(height: 16),
                ],
                if (!widget.singleMode) ...[
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
                ],
                if (!widget.aiAssisted && !widget.singleMode) ...[
                  Text(l.analysisMode, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(l.onDevice),
                        selected: !_aiAssisted,
                        showCheckmark: false,
                        onSelected: _scan.busy || _reading
                            ? null
                            : (_) => setState(() => _aiAssisted = false),
                      ),
                      ChoiceChip(
                        label: Text(l.aiAssisted),
                        selected: _aiAssisted,
                        showCheckmark: false,
                        onSelected: _scan.busy || _reading
                            ? null
                            : (_) => setState(() => _aiAssisted = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                if (_mode < 2) ...[
                  GlassSurface(
                    focusHighlight: true,
                    child: TextField(
                      controller: _inputs[_mode],
                      key: ValueKey(_mode),
                      enabled: !_scan.busy,
                      minLines: _mode == 1 ? 1 : 6,
                      maxLines: _mode == 1 ? 1 : 12,
                      style: theme.textTheme.bodyLarge,
                      keyboardType: _mode == 1
                          ? TextInputType.url
                          : TextInputType.multiline,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: _mode == 1 ? null : l.message,
                        hintText: _mode == 1
                            ? 'https://example.com'
                            : l.inputHint,
                        errorText: _scan.error == null
                            ? null
                            : l.errorMessage(_scan.error!),
                        errorMaxLines: 5,
                        prefixIcon: _mode == 1
                            ? const Icon(Icons.link_rounded)
                            : null,
                        suffixIcon: _mode == 1
                            ? IconButton(
                                tooltip: l.clear,
                                onPressed: _scan.busy
                                    ? null
                                    : () {
                                        _inputs[_mode].clear();
                                        setState(() => _scan.error = null);
                                      },
                                icon: const Icon(Icons.close_rounded),
                              )
                            : null,
                      ),
                      onChanged: (_) {
                        if (_mode == 0) _scheduleDraft();
                        if (_scan.error != null) {
                          setState(() => _scan.error = null);
                        }
                      },
                    ),
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
                      if (_mode == 0)
                        TextButton(
                          onPressed: _scan.busy
                              ? null
                              : () async {
                                  _inputs[_mode].clear();
                                  _draftTimer?.cancel();
                                  _draftRevision++;
                                  try {
                                    await widget.history.clearDraft();
                                  } catch (_) {
                                    _draftError();
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
                          : _aiAssisted
                          ? l.aiReviewTitle
                          : _mode == 1
                          ? l.checkLink
                          : l.checkMessage,
                    ),
                  ),
                  if (_scan.busy)
                    TextButton(onPressed: _scan.cancel, child: Text(l.cancel)),
                ] else ...[
                  GlassSurface(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.image_search_outlined,
                            size: 56,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l.screenshotIntro,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_ocr.available) Text(l.ocrNativeOnly),
                  const SizedBox(height: 12),
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
              ],
            ),
          ),
        ),
      );
    },
  );
}
