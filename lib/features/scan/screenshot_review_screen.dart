import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/page_body.dart';
import '../../widgets/glass_surface.dart';
import 'ocr_models.dart';

class ScreenshotReviewScreen extends StatefulWidget {
  const ScreenshotReviewScreen({super.key, required this.draft});
  final OcrDraft draft;
  @override
  State<ScreenshotReviewScreen> createState() => _ScreenshotReviewScreenState();
}

class _ScreenshotReviewScreenState extends State<ScreenshotReviewScreen> {
  late final _text = TextEditingController(text: widget.draft.text);
  late final _preview = widget.draft.bytes.isEmpty
      ? null
      : ResizeImage(
          MemoryImage(widget.draft.bytes),
          width: 1280,
          height: 1280,
          policy: ResizeImagePolicy.fit,
        );
  String? _error;
  @override
  void dispose() {
    _text.dispose();
    if (_preview != null) unawaited(_preview.evict());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.reviewText)),
      body: SafeArea(
        top: false,
        child: PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.ocrNotice, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              if (_preview != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image(
                    image: _preview,
                    height: 220,
                    fit: BoxFit.contain,
                    semanticLabel: l.screenshot,
                    errorBuilder: (context, error, stack) =>
                        Text(l.previewUnavailable),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (widget.draft.text.trim().isEmpty) ...[
                Text(l.noOcrText),
                const SizedBox(height: 16),
              ],
              GlassSurface(
                focusHighlight: true,
                child: TextField(
                  controller: _text,
                  minLines: 6,
                  maxLines: 14,
                  autocorrect: false,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: l.message,
                    errorText: _error == null ? null : l.errorMessage(_error!),
                    errorMaxLines: 4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (_text.text.trim().isEmpty) {
                    setState(() => _error = 'emptyInput');
                    return;
                  }
                  if (_text.text.runes.length > 10000) {
                    setState(() => _error = 'textTooLong');
                    return;
                  }
                  Navigator.pop(context, _text.text);
                },
                child: Text(l.checkThisText),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
