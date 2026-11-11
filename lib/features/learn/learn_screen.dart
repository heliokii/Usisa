import 'package:flutter/material.dart';

import '../../features/home/feature_artwork.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/usisa_theme.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_body.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.learnStaySafeTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          GlassSurface(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                const LearnSafetyArtwork(height: 132),
                ExpansionTile(
                  title: Text(
                    l.learnScamTips,
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    l.learnScamTipsBody,
                    style: theme.textTheme.bodyMedium,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${l.learnOtpBody}\n\n${l.learnRecoveryBody}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(l.learnCommonScams, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          _TipCard(
            icon: Icons.account_balance_outlined,
            title: l.learnBankTitle,
            subtitle: l.learnBankBody,
            extra: l.learnOtpBody,
          ),
          const SizedBox(height: 10),
          _TipCard(
            icon: Icons.account_balance_outlined,
            title: l.learnGovernmentTitle,
            subtitle: l.learnGovernmentBody,
          ),
          const SizedBox(height: 10),
          _TipCard(
            icon: Icons.storefront_outlined,
            title: l.learnSellerTitle,
            subtitle: l.learnSellerBody,
            extra: l.learnDeliveryBody,
          ),
          const SizedBox(height: 24),
          Text(l.aboutBody, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.extra,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return GlassSurface(
      child: ExpansionTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: UsisaTheme.contrastCoral),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              extra == null ? subtitle : '$subtitle\n\n$extra',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
