import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/usisa_theme.dart';
import '../../widgets/page_body.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/usisa_action_button.dart';
import '../../widgets/usisa_loading_indicator.dart';
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
  static const _messageInputTopSpacing = 50.0;
  static const _messageInputCardHeight = 250.0;
  static const _messageImageTopSpacing = 25.0;
  static const _messageImageBottomSpacing = 25.0;

  final _inputs = [TextEditingController(), TextEditingController()];
  final _scan = ScanController();
  late final _ocr = widget.ocr ?? OcrService();
  bool _reading = false;
  String? _ocrErrorCode;
  OcrDraft? _recovered;
  OcrDraft? _selectedScreenshot;
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
        setState(() => _inputs[0].text = text);
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
          screenshotPreview: value.source == ScanSource.screenshot
              ? _selectedScreenshot?.bytes
              : null,
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
    final code = error is ScanException ? error.code : 'ocrFailed';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _ocrErrorCode = code);
    });
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

  Future<bool?> _chooseScreenshotSource() => showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l = AppLocalizations.of(context);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.photos),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_rounded),
              title: Text(l.browseFiles),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      );
    },
  );

  Future<void> _importScreenshot({OcrDraft? recovered}) async {
    if (_reading) return;
    setState(() {
      _reading = true;
      _ocrErrorCode = null;
    });
    final revision = ++_ocrRevision;
    try {
      final usePhotos =
          recovered != null || defaultTargetPlatform != TargetPlatform.android
          ? true
          : await _chooseScreenshotSource();
      if (!mounted || usePhotos == null || revision != _ocrRevision) return;
      final draft =
          recovered ?? await _ocr.readScreenshot(usePhotos: usePhotos);
      if (!mounted || draft == null || revision != _ocrRevision) return;
      setState(() {
        _selectedScreenshot = draft;
        _recovered = null;
        _ocrErrorCode = null;
        _mode = 2;
      });
    } catch (e) {
      if (mounted && revision == _ocrRevision) _ocrError(e);
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  Future<void> _reviewSelectedScreenshot() async {
    final draft = _selectedScreenshot;
    if (_reading || draft == null) return;
    setState(() => _reading = true);
    try {
      final text = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => ScreenshotReviewScreen(draft: draft)),
      );
      if (mounted && text != null) {
        await _check(reviewed: ScanInput(text, source: ScanSource.screenshot));
      }
    } finally {
      if (mounted) setState(() => _reading = false);
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
      setState(() => _scan.error = null);
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

  Future<void> _clearMessage() async {
    _inputs[0].clear();
    _draftTimer?.cancel();
    _draftRevision++;
    setState(() => _scan.error = null);
    try {
      await widget.history.clearDraft();
    } catch (_) {
      _draftError();
    }
  }

  Widget _inputCard(
    BuildContext context,
    AppLocalizations l,
    ThemeData theme, {
    bool fillMessageSpace = false,
  }) {
    final compactMessageField = _mode == 0;
    final message = _inputs[0].text;
    final field = TextField(
      controller: _inputs[_mode],
      key: ValueKey(_mode),
      enabled: !_scan.busy,
      minLines: fillMessageSpace
          ? null
          : compactMessageField
          ? 1
          : (_mode == 1 ? 1 : 2),
      maxLines: fillMessageSpace
          ? null
          : compactMessageField
          ? 2
          : (_mode == 1 ? 1 : 4),
      expands: fillMessageSpace,
      textAlignVertical: TextAlignVertical.top,
      style: theme.textTheme.bodyLarge,
      keyboardType: _mode == 1 ? TextInputType.url : TextInputType.multiline,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: _aiAssisted && !compactMessageField ? l.message : null,
        hintText: _mode == 1 ? l.pasteLink : l.inputHint,
        errorText: _scan.error == null ? null : l.errorMessage(_scan.error!),
        errorMaxLines: 5,
        prefixIcon: _mode == 1
            ? HugeIcon(
                icon: HugeIcons.strokeRoundedLink04,
                color: theme.colorScheme.primary,
                size: 20,
              )
            : null,
        suffixIcon: _mode == 1
            ? IconButton(
                tooltip: _inputs[_mode].text.isEmpty ? l.pasteLink : l.clear,
                onPressed: _scan.busy
                    ? null
                    : _inputs[_mode].text.isEmpty
                    ? _paste
                    : () {
                        _inputs[_mode].clear();
                        setState(() => _scan.error = null);
                      },
                icon: Icon(
                  _inputs[_mode].text.isEmpty
                      ? Icons.content_paste_rounded
                      : Icons.close_rounded,
                ),
              )
            : null,
        contentPadding: compactMessageField
            ? const EdgeInsets.symmetric(vertical: 8)
            : null,
      ),
      onChanged: (_) {
        if (_mode == 0) _scheduleDraft();
        setState(() => _scan.error = null);
      },
    );
    final messageInput = Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedMessageSquareMore,
              color: theme.colorScheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: fillMessageSpace ? SizedBox.expand(child: field) : field,
          ),
          if (message.isNotEmpty)
            IconButton(
              tooltip: l.clear,
              onPressed: _scan.busy ? null : _clearMessage,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
    final pasteButton = TextButton(
      style: TextButton.styleFrom(alignment: Alignment.centerLeft),
      onPressed: _scan.busy ? null : _paste,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.content_paste_rounded, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(l.pasteText, softWrap: true)),
        ],
      ),
    );
    final counter = Text(
      '${message.length}/10,000',
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final messageControls = fillMessageSpace
        ? Row(
            children: [
              Expanded(child: pasteButton),
              const SizedBox(width: 8),
              counter,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              pasteButton,
              Align(alignment: Alignment.centerRight, child: counter),
            ],
          );
    final card = GlassSurface(
      focusHighlight: true,
      child: Column(
        mainAxisSize: fillMessageSpace ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (compactMessageField)
            fillMessageSpace ? Expanded(child: messageInput) : messageInput
          else
            field,
          if (_mode == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: messageControls,
            ),
        ],
      ),
    );
    return card;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _scan,
    builder: (context, _) {
      final l = AppLocalizations.of(context);
      final theme = Theme.of(context);
      final messageMode = _mode == 0;
      final largeText = MediaQuery.textScalerOf(context).scale(16) > 20;
      final fillMessageLayout =
          messageMode &&
          !largeText &&
          MediaQuery.sizeOf(context).height +
                  MediaQuery.viewInsetsOf(context).bottom >=
              600;
      final checkLabel = _scan.busy
          ? l.checking
          : _aiAssisted
          ? l.aiReviewTitle
          : _mode == 1
          ? l.checkLink
          : l.checkMessage;
      final Widget messageAction = UsisaActionButton.icon(
        onPressed: _scan.busy || _inputs[0].text.trim().isEmpty ? null : _check,
        icon: _scan.busy
            ? const UsisaLoadingIndicator(size: 18, color: UsisaTheme.cream)
            : const Icon(Icons.arrow_forward_rounded),
        label: Text(
          _scan.busy
              ? l.checking
              : _aiAssisted
              ? l.aiReviewTitle
              : l.scanMessageCard,
        ),
      );
      final Widget primaryAction = messageMode
          ? messageAction
          : _mode == 1
          ? UsisaActionButton(
              onPressed: _scan.busy ? null : _check,
              child: _scan.busy
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const UsisaLoadingIndicator(
                          size: 18,
                          color: UsisaTheme.cream,
                        ),
                        const SizedBox(width: 8),
                        Text(l.checking),
                      ],
                    )
                  : Text(checkLabel),
            )
          : _mode < 2
          ? UsisaActionButton.icon(
              onPressed: _scan.busy ? null : _check,
              icon: _scan.busy
                  ? const UsisaLoadingIndicator(
                      size: 18,
                      color: UsisaTheme.cream,
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(checkLabel),
            )
          : UsisaActionButton.icon(
              onPressed: !_ocr.available || _reading
                  ? null
                  : _selectedScreenshot == null
                  ? _importScreenshot
                  : _reviewSelectedScreenshot,
              icon: _reading
                  ? const UsisaLoadingIndicator(
                      size: 18,
                      color: UsisaTheme.cream,
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(_reading ? l.readingImage : l.scanScreenshotCard),
            );
      final title = _aiAssisted
          ? l.aiScan
          : _mode == 1
          ? l.linkCheckerTitle
          : _mode == 2
          ? l.scanScreenshotCard
          : l.scanMessageCard;
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          top: false,
          bottom: false,
          child: PageBody(
            fillViewport: fillMessageLayout,
            scrollable: true,
            child: Builder(
              builder: (context) {
                final messageIntro = Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: _messageImageTopSpacing,
                        bottom: _messageImageBottomSpacing,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/image/scan-message-brand.png',
                          width: 220,
                          height: 110,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    Text(
                      _aiAssisted ? l.scanHeading : l.messageScanPrompt,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _aiAssisted ? l.scanIntro : l.messageScanSupport,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (_aiAssisted) ...[
                      const SizedBox(height: 16),
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
                              l.aiManualOnly,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
                final linkIntro = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: _messageImageTopSpacing,
                        bottom: _messageImageBottomSpacing,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/image/link-checker-brand.png',
                          width: 280,
                          height: 150,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    Text(
                      l.linkCheckPrompt,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.linkCheckSupport,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 22),
                  ],
                );
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (messageMode)
                      messageIntro
                    else if (_mode == 1)
                      linkIntro
                    else if (_mode == 2 &&
                        _selectedScreenshot == null &&
                        !_reading) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: _messageImageTopSpacing,
                          bottom: _messageImageBottomSpacing,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/image/scan-screenshot-brand.png',
                            width: 280,
                            height: 150,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                      Text(
                        l.screenshotHeading,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.screenshotIntro,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
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
                    if (_mode == 2) ...[
                      if (_reading) ...[
                        const SizedBox(height: 48),
                        const Center(
                          child: UsisaLoadingIndicator(
                            size: 40,
                            color: UsisaTheme.forest,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l.readingImage,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.screenshotIntro,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ] else if (_selectedScreenshot != null) ...[
                        const SizedBox(height: 12),
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                height: 180,
                                color: const Color(0xFF272C2A),
                                child: Image.memory(
                                  _selectedScreenshot!.bytes,
                                  fit: BoxFit.contain,
                                  semanticLabel: l.screenshot,
                                  errorBuilder: (context, error, stack) =>
                                      Center(
                                        child: Text(
                                          l.previewUnavailable,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: UsisaTheme.cream,
                                              ),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton.filled(
                                tooltip: l.clear,
                                onPressed: () => setState(() {
                                  _selectedScreenshot = null;
                                  _ocrErrorCode = null;
                                }),
                                style: IconButton.styleFrom(
                                  backgroundColor: UsisaTheme.forest,
                                  foregroundColor: UsisaTheme.cream,
                                ),
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedImage03,
                              color: UsisaTheme.forest,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedScreenshot!.fileName.isEmpty
                                        ? l.screenshot
                                        : _selectedScreenshot!.fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  Text(
                                    '${(_selectedScreenshot!.bytes.length / 1024).ceil()} KB',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _ocr.available && !_reading
                                ? () => _importScreenshot()
                                : null,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(l.changeImage),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 18),
                        Center(
                          child: SizedBox(
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _DashedOutlinePainter(
                                color: UsisaTheme.forest,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _ocr.available
                                      ? () => _importScreenshot()
                                      : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 22,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        HugeIcon(
                                          icon: HugeIcons.strokeRoundedImage03,
                                          color: theme.colorScheme.primary,
                                          size: 36,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          l.chooseScreenshot,
                                          style: theme.textTheme.titleSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.screenshotSupported,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (_ocrErrorCode != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            l.errorMessage(_ocrErrorCode!),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                        if (!_ocr.available) ...[
                          const SizedBox(height: 12),
                          Text(
                            l.ocrNativeOnly,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
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
                      if (messageMode)
                        SizedBox(
                          height: _aiAssisted ? 8 : _messageInputTopSpacing,
                        ),
                      if (messageMode)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: _messageInputCardHeight,
                            maxHeight: largeText
                                ? double.infinity
                                : _messageInputCardHeight,
                          ),
                          child: _inputCard(
                            context,
                            l,
                            theme,
                            fillMessageSpace: !largeText,
                          ),
                        )
                      else
                        _inputCard(context, l, theme),
                    ],
                  ],
                );
                return content;
              },
            ),
          ),
        ),
        bottomNavigationBar:
            _mode == 2 && _selectedScreenshot == null && !_reading
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      primaryAction,
                      if (_scan.busy)
                        TextButton(
                          onPressed: _scan.cancel,
                          child: Text(l.cancel),
                        )
                      else if (_reading && _mode == 2)
                        TextButton(
                          onPressed: () => setState(() {
                            _ocrRevision++;
                            _reading = false;
                            _selectedScreenshot = null;
                          }),
                          child: Text(l.cancel),
                        ),
                    ],
                  ),
                ),
              ),
      );
    },
  );
}

class _DashedOutlinePainter extends CustomPainter {
  const _DashedOutlinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 1.3;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));

    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 10) {
        final end = distance + 5 < metric.length ? distance + 5 : metric.length;
        canvas.drawPath(metric.extractPath(distance, end), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutlinePainter oldDelegate) =>
      oldDelegate.color != color;
}
