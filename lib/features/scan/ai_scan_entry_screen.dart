import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/usisa_theme.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_body.dart';
import '../../widgets/usisa_action_button.dart';
import '../../widgets/usisa_action_button_painter.dart';

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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.back,
          onPressed: () => _choosing
              ? setState(() => _choosing = false)
              : Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l.aiScan),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: PageTransitionSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          transitionBuilder: (child, animation, secondaryAnimation) =>
              FadeThroughTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                fillColor: UsisaTheme.cream,
                child: child,
              ),
          child: KeyedSubtree(
            key: ValueKey(_choosing),
            child: _choosing ? _inputChoices(context) : _introduction(context),
          ),
        ),
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
                  onPressed: () => setState(() => _choosing = true),
                  danger: true,
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
          const SizedBox(height: 16),
          Center(
            child: Image.asset(
              'assets/image/ai-brand.png',
              width: 230,
              height: 147,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
          ),
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
          const SizedBox(height: 8),
          _BenefitRow(
            icon: Icons.layers_outlined,
            title: l.aiContextAware,
            subtitle: l.aiContextAwareBody,
          ),
          const SizedBox(height: 8),
          _BenefitRow(
            icon: Icons.shield_outlined,
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
          Text(l.aiInputQuestion, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          _InputCard(
            icon: HugeIcons.strokeRoundedMessageSquareMore,
            title: l.aiTextOption,
            subtitle: l.aiTextOptionBody,
            onTap: () => _choose(0),
            primary: true,
          ),
          const SizedBox(height: 10),
          _InputCard(
            icon: HugeIcons.strokeRoundedLink04,
            title: l.aiLinkOption,
            subtitle: l.aiLinkOptionBody,
            onTap: () => _choose(1),
          ),
          const SizedBox(height: 10),
          _InputCard(
            icon: HugeIcons.strokeRoundedImage03,
            title: l.aiScreenshotOption,
            subtitle: l.aiScreenshotOptionBody,
            onTap: () => _choose(2),
          ),
          const SizedBox(height: 64),
          Center(
            child: Image.asset(
              'assets/image/ai-brand.png',
              width: 230,
              height: 147,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
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
    final theme = Theme.of(context);
    return GlassSurface(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: UsisaTheme.coral, size: 30),
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
    this.primary = false,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = primary ? colors.onPrimary : colors.onSurface;
    final radius = BorderRadius.circular(primary ? 21 : 16);
    final surface = GlassSurface(
      color: primary ? const Color(0xFF0B6048) : colors.surface,
      borderRadius: radius,
      showShadow: !primary,
      child: Stack(
        children: [
          if (primary)
            const Positioned.fill(
              child: CustomPaint(painter: UsisaActionButtonPainter()),
            ),
          InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: primary
                  ? const EdgeInsets.fromLTRB(22, 12, 22, 6)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  HugeIcon(
                    icon: icon,
                    color: primary ? colors.onPrimary : UsisaTheme.coral,
                    size: primary ? 32 : 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: primary
                              ? theme.textTheme.titleSmall?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                )
                              : theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: primary
                              ? theme.textTheme.bodySmall?.copyWith(
                                  color: foreground,
                                  fontSize: 12,
                                )
                              : theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: primary ? colors.onPrimary : UsisaTheme.forest,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (!primary) return surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF2C9A76).withValues(alpha: .76),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064638).withValues(alpha: .2),
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(1), child: surface),
    );
  }
}
