import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/page_body.dart';
import '../../widgets/glass_surface.dart';
import 'scan_models.dart';
import 'scam_analyzer.dart';

class AiReviewChoice {
  const AiReviewChoice(this.text, {required this.send});
  final String text;
  final bool send;
}

class AiReviewScreen extends StatefulWidget {
  const AiReviewScreen({super.key, required this.input});
  final ScanInput input;
  @override
  State<AiReviewScreen> createState() => _AiReviewScreenState();
}

class _AiReviewScreenState extends State<AiReviewScreen> {
  final _form = GlobalKey<FormState>();
  late final _text = TextEditingController(text: widget.input.text);
  bool _submitted = false;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _finish(bool send) {
    if (_submitted || !_form.currentState!.validate()) return;
    _submitted = true;
    Navigator.pop(context, AiReviewChoice(_text.text, send: send));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.aiReviewTitle)),
      body: SafeArea(
        top: false,
        child: PageBody(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l.aiDisclosure,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                GlassSurface(
                  focusHighlight: true,
                  child: TextFormField(
                    controller: _text,
                    minLines: 5,
                    maxLines: 12,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.multiline,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: l.aiTextLabel,
                      errorMaxLines: 5,
                    ),
                    validator: (text) {
                      try {
                        ScamAnalyzer().analyze(
                          ScanInput(text ?? '', source: widget.input.source),
                        );
                        return null;
                      } on ScanException catch (e) {
                        return l.errorMessage(e.code);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _finish(true),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(l.sendAi),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _finish(false),
                  child: Text(l.keepOnDevice),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
