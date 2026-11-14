import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/page_body.dart';
import '../history/history_store.dart';
import '../scan/result_screen.dart';
import '../scan/scan_models.dart';
import '../settings/settings_store.dart';
import 'sms_service.dart';

class SmsReviewScreen extends StatefulWidget {
  const SmsReviewScreen({
    super.key,
    required this.id,
    required this.sms,
    required this.history,
    required this.settings,
  });
  final String id;
  final SmsService sms;
  final HistoryStore history;
  final SettingsStore settings;
  @override
  State<SmsReviewScreen> createState() => _SmsReviewScreenState();
}

class _SmsReviewScreenState extends State<SmsReviewScreen> {
  late Future<SmsReview?> _review = _load();
  bool _saved = true;

  Future<SmsReview?> _load() async {
    final generation = widget.history.generation;
    final retain = widget.history.enabled;
    SmsReview? review;
    try {
      review = await widget.sms.review(widget.id);
    } catch (_) {
      /* Retained history can still be reviewed offline. */
    }
    if (generation != widget.history.generation) return null;
    if (review == null && widget.history.enabled) {
      final retained = widget.history.entries
          .where((r) => r.id == widget.id && r.source == ScanSource.sms)
          .firstOrNull;
      if (retained != null) {
        final age = widget.history.clock().difference(retained.createdAt);
        if (!age.isNegative && age < const Duration(days: 30)) {
          review = SmsReview(
            body: retained.text,
            generation: widget.sms.generation,
            result: retained,
          );
        }
      }
    }
    if (generation != widget.history.generation ||
        review?.generation != widget.sms.generation) {
      return null;
    }
    if (review?.result != null && retain) {
      try {
        await widget.history.save(
          review!.result!,
          expectedGeneration: generation,
        );
      } catch (_) {
        _saved = false;
      }
    }
    if (generation != widget.history.generation ||
        review?.generation != widget.sms.generation) {
      return null;
    }
    return review;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<SmsReview?>(
    future: _review,
    builder: (context, snapshot) {
      final l = AppLocalizations.of(context);
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Scaffold(
          appBar: AppBar(title: Text(l.recentSms)),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      final review = snapshot.data;
      if (review?.result != null) {
        return ResultScreen(
          result: review!.result!,
          saved: _saved,
          history: widget.history,
          settings: widget.settings,
        );
      }
      return Scaffold(
        appBar: AppBar(title: Text(l.recentSms)),
        body: SafeArea(
          bottom: false,
          child: PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.sms_outlined,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  review == null ? l.smsMissing : l.smsPending,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (review != null) ...[
                  const SizedBox(height: 24),
                  SelectableText(review.body),
                ],
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => setState(() {
                    _saved = true;
                    _review = _load();
                  }),
                  child: Text(l.retry),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class SmsInboxScreen extends StatefulWidget {
  const SmsInboxScreen({super.key, required this.sms, required this.onOpen});
  final SmsService sms;
  final void Function(String) onOpen;
  @override
  State<SmsInboxScreen> createState() => _SmsInboxScreenState();
}

class _SmsInboxScreenState extends State<SmsInboxScreen> {
  late Future<List<(String, SmsReview)>> _items = _load();
  Future<List<(String, SmsReview)>> _load() async {
    final items = <(String, SmsReview)>[];
    for (final id in await widget.sms.reviewIds()) {
      final review = await widget.sms.review(id);
      if (review != null) items.add((id, review));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.recentSms),
        actions: [
          IconButton(
            onPressed: () => setState(() => _items = _load()),
            tooltip: l.retry,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.smsTemporary),
              const SizedBox(height: 24),
              FutureBuilder<List<(String, SmsReview)>>(
                future: _items,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) return Text(l.smsMissing);
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) return Text(l.smsEmpty);
                  return Column(
                    children: [
                      for (final item in items)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.sms_outlined),
                          title: Text(
                            item.$2.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            item.$2.result == null
                                ? l.smsPending
                                : l.riskLabel(item.$2.result!.risk.name),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => widget.onOpen(item.$1),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
