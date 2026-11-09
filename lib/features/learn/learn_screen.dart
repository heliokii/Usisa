import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/page_body.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final articles = [
      (Icons.password_rounded, l.learnOtpTitle, l.learnOtpBody),
      (Icons.account_balance_outlined, l.learnBankTitle, l.learnBankBody),
      (
        Icons.account_balance_wallet_outlined,
        l.learnGovernmentTitle,
        l.learnGovernmentBody,
      ),
      (
        Icons.local_shipping_outlined,
        l.learnDeliveryTitle,
        l.learnDeliveryBody,
      ),
      (Icons.storefront_outlined, l.learnSellerTitle, l.learnSellerBody),
      (Icons.support_agent_rounded, l.learnRecoveryTitle, l.learnRecoveryBody),
    ];
    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.learnHeading, style: theme.textTheme.headlineLarge),
          const SizedBox(height: 12),
          Text(l.learnIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 28),
          for (final article in articles)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: Icon(article.$1),
              title: Text(article.$2, style: theme.textTheme.titleMedium),
              childrenPadding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(article.$3, style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          const SizedBox(height: 24),
          Text(l.aboutBody),
        ],
      ),
    );
  }
}
