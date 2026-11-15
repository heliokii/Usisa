import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/usisa_theme.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_body.dart';
import '../../widgets/usisa_modal.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final backTooltip = MaterialLocalizations.of(context).backButtonTooltip;
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;

    return PageBody(
      scrollable: textScale > 1.25,
      horizontalGutter: 16,
      bottomPadding: 32,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 800;
          final tight = constraints.maxHeight < 560;
          final gap = tight ? 4.0 : 8.0;
          final heroGap = tight ? 8.0 : 32.0;
          final heroHeight = tight ? 88.0 : 136.0;
          final artWidth = (constraints.maxWidth - 56)
              .clamp(0.0, 300.0)
              .toDouble();
          final cardHeight = tight
              ? 68.0
              : (constraints.maxWidth * .24).clamp(76.0, 92.0).toDouble();
          final sectionGap = tight ? 16.0 : 33.0;
          final sectionCardGap = tight ? 6.0 : 20.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: backTooltip,
                      onPressed: onBack,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        color: UsisaTheme.forest,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l.learnStaySafeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              SizedBox(height: heroGap),
              SizedBox(
                height: heroHeight,
                child: Center(
                  child: Image.asset(
                    'assets/image/learn-brand.png',
                    width: artWidth,
                    height: heroHeight,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              SizedBox(height: tight ? 12 : 20),
              Text(
                l.learnScamTips,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: compact ? 22 : null,
                ),
              ),
              SizedBox(height: tight ? 1 : 12),
              Text(
                l.learnScamTipsBody,
                maxLines: tight ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: compact ? 16 : null,
                ),
              ),
              SizedBox(height: sectionGap),
              Text(
                l.learnCommonScams,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: compact ? 18 : null,
                ),
              ),
              SizedBox(height: sectionCardGap),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: cardHeight),
                child: _LearnTipCard(
                  icon: HugeIcons.strokeRoundedBank,
                  iconColor: UsisaTheme.contrastCoral,
                  title: l.learnBankTitle,
                  summary: l.learnBankSummary,
                  message: l.learnBankBody,
                  details: l.learnOtpBody,
                  recoveryTitle: l.learnRecoveryTitle,
                  recoveryBody: l.learnRecoveryBody,
                  compact: compact,
                ),
              ),
              SizedBox(height: gap),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: cardHeight),
                child: _LearnTipCard(
                  icon: HugeIcons.strokeRoundedBank,
                  iconColor: UsisaTheme.contrastCoral,
                  title: l.learnGovernmentTitle,
                  summary: l.learnGovernmentSummary,
                  message: l.learnGovernmentBody,
                  recoveryTitle: l.learnRecoveryTitle,
                  recoveryBody: l.learnRecoveryBody,
                  compact: compact,
                ),
              ),
              SizedBox(height: gap),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: cardHeight),
                child: _LearnTipCard(
                  icon: HugeIcons.strokeRoundedShoppingCart01,
                  iconColor: UsisaTheme.contrastCoral,
                  title: l.learnSellerTitle,
                  summary: l.learnSellerSummary,
                  message: l.learnSellerBody,
                  details: l.learnDeliveryBody,
                  recoveryTitle: l.learnRecoveryTitle,
                  recoveryBody: l.learnRecoveryBody,
                  compact: compact,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LearnTipCard extends StatelessWidget {
  const _LearnTipCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.summary,
    required this.message,
    required this.recoveryTitle,
    required this.recoveryBody,
    required this.compact,
    this.details,
  });

  final List<List<dynamic>> icon;
  final Color iconColor;
  final String title;
  final String summary;
  final String message;
  final String? details;
  final String recoveryTitle;
  final String recoveryBody;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return GlassSurface(
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          UsisaModal.show(
            context: context,
            title: title,
            message: message,
            primaryLabel: l.continueAction,
            variant: UsisaModalVariant.info,
            details: Column(
              children: [
                if (details != null) ...[
                  Text(
                    details!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                ],
                Text(
                  recoveryTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recoveryBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 10 : 14,
            compact ? 5 : 8,
            compact ? 30 : 14,
            compact ? 5 : 8,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Center(
                  child: HugeIcon(icon: icon, color: iconColor, size: 44),
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: UsisaTheme.forest.withValues(alpha: .12),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: UsisaTheme.forest,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 230),
                      child: Text(
                        summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: UsisaTheme.forest.withValues(alpha: .82),
                          fontSize: compact ? 13 : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: UsisaTheme.forest,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
