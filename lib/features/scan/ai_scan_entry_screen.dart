import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/usisa_theme.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_body.dart';
import '../../widgets/usisa_action_button.dart';
import '../home/feature_artwork.dart';

class AiScanEntryScreen extends StatefulWidget {
  const AiScanEntryScreen({super.key, required this.onChooseInput});
  final ValueChanged<int> onChooseInput;

  @override
  State<AiScanEntryScreen> createState() => _AiScanEntryScreenState();
}

class _AiScanEntryScreenState extends State<AiScanEntryScreen> {
  bool _choosing = false;

  void _choose(int mode) {
    final callback = widget.onChooseInput;
    Navigator.of(context).pop();
    callback(mode);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.back,
          onPressed: () => _choosing
              ? setState(() => _choosing = false)
              : Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: _choosing
            ? Text(l.aiScan)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.aiScan),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: UsisaTheme.contrastCoral,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l.aiBeta,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: UsisaTheme.cream,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: _choosing ? _inputChoices(context) : _introduction(context),
      ),
      bottomNavigationBar: _choosing
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  PageBody.gutterOf(context),
                  12,
                  PageBody.gutterOf(context),
                  16,
                ),
                child: UsisaActionButton.icon(
                  onPressed: _choosing
                      ? null
                      : () => setState(() => _choosing = true),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(l.startAiScan),
                ),
              ),
            ),
    );
  }

  Widget _introduction(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          const Center(child: AiScanArtwork(size: 132)),
          const SizedBox(height: 8),
          Text(
            l.aiIntroTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l.aiIntroBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _BenefitRow(
            icon: Icons.bolt_rounded,
            title: l.aiMultiInput,
            subtitle: l.aiMultiInputBody,
          ),
          const SizedBox(height: 10),
          _BenefitRow(
            icon: Icons.psychology_alt_outlined,
            title: l.aiContextAware,
            subtitle: l.aiContextAwareBody,
          ),
          const SizedBox(height: 10),
          _BenefitRow(
            icon: Icons.verified_user_outlined,
            title: l.aiActionable,
            subtitle: l.aiActionableBody,
          ),
        ],
      ),
    );
  }

  Widget _inputChoices(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.aiInputQuestion, style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          _InputCard(
            icon: Icons.sms_outlined,
            title: l.aiTextOption,
            subtitle: l.aiTextOptionBody,
            onTap: () => _choose(0),
          ),
          const SizedBox(height: 12),
          _InputCard(
            icon: Icons.link_rounded,
            title: l.aiLinkOption,
            subtitle: l.aiLinkOptionBody,
            onTap: () => _choose(1),
          ),
          const SizedBox(height: 12),
          _InputCard(
            icon: Icons.image_search_outlined,
            title: l.aiScreenshotOption,
            subtitle: l.aiScreenshotOptionBody,
            onTap: () => _choose(2),
          ),
          const SizedBox(height: 32),
          const Center(child: AiScanArtwork(size: 136)),
          const SizedBox(height: 8),
          Text(
            l.aiManualOnly,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return GlassSurface(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return GlassSurface(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
