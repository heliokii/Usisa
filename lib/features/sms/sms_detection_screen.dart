import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/usisa_theme.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_body.dart';
import '../scan/scan_models.dart';
import 'sms_service.dart';

class SmsDetectionScreen extends StatefulWidget {
  const SmsDetectionScreen({
    super.key,
    required this.sms,
    required this.onToggle,
    required this.onOpen,
  });
  final SmsService sms;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onOpen;

  @override
  State<SmsDetectionScreen> createState() => _SmsDetectionScreenState();
}

class _SmsDetectionScreenState extends State<SmsDetectionScreen> {
  late Future<List<(String, SmsReview)>> _reviews = _loadReviews();
  bool _flaggedOnly = false;

  Future<List<(String, SmsReview)>> _loadReviews() async {
    final values = <(String, SmsReview)>[];
    for (final id in await widget.sms.reviewIds()) {
      final review = await widget.sms.review(id);
      if (review != null) values.add((id, review));
    }
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.smsDetectionTitle),
        actions: [
          ListenableBuilder(
            listenable: widget.sms,
            builder: (context, _) => Semantics(
              label: l.smsHeading,
              child: Switch(
                value: widget.sms.enabled,
                onChanged: widget.sms.supported ? widget.onToggle : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.sms,
          builder: (context, _) => PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.smsDetectionBody, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text(
                  widget.sms.enabled ? l.smsLimits : l.smsDetail,
                  style: theme.textTheme.bodySmall,
                ),
                if (widget.sms.degraded) ...[
                  const SizedBox(height: 8),
                  Text(l.smsDegraded, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.smsRecentDetections,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: l.retry,
                      onPressed: () =>
                          setState(() => _reviews = _loadReviews()),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<(String, SmsReview)>>(
                  future: _reviews,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) return Text(l.smsMissing);
                    final reviews = snapshot.data ?? const [];
                    final flagged = reviews
                        .where(
                          (item) =>
                              item.$2.result?.risk != null &&
                              item.$2.result!.risk != RiskLevel.low,
                        )
                        .toList();
                    final visible = _flaggedOnly ? flagged : reviews;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<bool>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: false,
                              label: Text(l.smsRecentTab(reviews.length)),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text(l.smsFlaggedTab(flagged.length)),
                            ),
                          ],
                          selected: {_flaggedOnly},
                          onSelectionChanged: (value) =>
                              setState(() => _flaggedOnly = value.single),
                        ),
                        const SizedBox(height: 12),
                        if (visible.isEmpty)
                          GlassSurface(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _flaggedOnly ? l.smsFlaggedEmpty : l.smsEmpty,
                              ),
                            ),
                          )
                        else
                          for (final (id, review) in visible)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ReviewCard(
                                review: review,
                                onTap: () => widget.onOpen(id),
                              ),
                            ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.onTap});
  final SmsReview review;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final risk = review.result?.risk;
    final riskColor = risk == null
        ? colors.onSurfaceVariant
        : UsisaTheme.risk(context, risk).$1;
    final riskBackground = risk == null
        ? colors.surfaceContainerHigh
        : UsisaTheme.risk(context, risk).$2;
    final time = review.result?.createdAt.toLocal();
    return GlassSurface(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sms_outlined, color: colors.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.sourceLabel('sms'),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      review.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: riskBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            risk == null
                                ? l.smsPending
                                : l.riskLabel(risk.name),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: riskColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (time != null)
                          Text(
                            MaterialLocalizations.of(context)
                                .formatTimeOfDay(TimeOfDay.fromDateTime(time)),
                            style: theme.textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
