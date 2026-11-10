import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/usisa_theme.dart';
import '../../widgets/page_body.dart';
import 'scan_models.dart';
import 'reputation_client.dart';
import 'ai_models.dart';
import 'ai_scan_client.dart';
import 'ai_review_screen.dart';
import 'scan_controller.dart';
import 'scam_analyzer.dart';
import '../history/history_store.dart';
import '../settings/settings_store.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.result,
    this.saved = true,
    this.history,
    this.settings,
    this.reputationFactory,
    this.advisoryLauncher,
    this.aiFactory,
    this.initialAiInput,
  });
  final ScanResult result;
  final bool saved;
  final HistoryStore? history;
  final SettingsStore? settings;
  final ReputationClient Function()? reputationFactory;
  final Future<bool> Function(Uri)? advisoryLauncher;
  final AiScanClient Function()? aiFactory;
  final ReviewedAiInput? initialAiInput;
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with WidgetsBindingObserver {
  late ScanResult _result = widget.result;
  late bool _saveFailed = !widget.saved;
  late final _aiScan = ScanController(initialResult: widget.result);
  int _aiRevision = 0;
  int? _aiGeneration;
  bool _reviewingAi = false;
  bool _checkingLinks = false;
  ReputationClient? _client;
  int _linkRevision = 0;
  Finding? _highlight;
  bool _originalOpen = false;
  final _originalKey = GlobalKey();
  String _coverageText(BuildContext context, LinkResult link) {
    final l = AppLocalizations.of(context);
    var text = link.reputationExpired
        ? '${link.hasThreatWarning ? '${l.previousThreat}\n' : ''}${l.reputationExpired}'
        : switch (link.currentReputation) {
            ReputationState.matched => l.knownThreat,
            ReputationState.noMatch => l.notListed,
            ReputationState.unavailable => l.linkUnavailable,
            ReputationState.checking => l.checkingLinks,
            ReputationState.notRequested => l.notChecked,
          };
    final at = link.checkedAt?.toLocal();
    if (at != null) {
      final material = MaterialLocalizations.of(context);
      final date =
          '${material.formatCompactDate(at)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';
      text += '\n${l.checkedAtLabel(date)}';
    }
    return text;
  }

  Timer? _coverageTimer;
  Future<void> _openHelp(String address) async {
    final uri = Uri.parse(address);
    try {
      final opened =
          await (widget.advisoryLauncher?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (opened) return;
    } catch (_) {
      /* Keep the current scan available if no browser can open help. */
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).advisoryUnavailable),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _aiScan.addListener(_aiChanged);
    widget.history?.addListener(_privacyChanged);
    _scheduleCoverageExpiry();
    if (widget.initialAiInput != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_startAi(widget.initialAiInput!));
      });
    }
  }

  void _aiChanged() {
    if (!mounted) return;
    setState(() {
      if (_aiScan.result?.id == _result.id) _result = _aiScan.result!;
      if (_aiScan.error == 'saveFailed') _saveFailed = true;
    });
  }

  void _privacyChanged() {
    if (_aiScan.busy && _aiGeneration != widget.history?.generation) {
      _aiScan.cancel();
    }
  }

  Future<void> _startAi(ReviewedAiInput input) async {
    if (_aiScan.busy) return;
    _aiGeneration = input.privacyGeneration;
    _aiScan.result = _result;
    await _aiScan.checkAi(
      input,
      client: widget.aiFactory?.call() ?? AiScanClient(),
      history: widget.history,
    );
  }

  Future<void> _reviewAi() async {
    if (_aiScan.busy || _reviewingAi) return;
    _reviewingAi = true;
    final generation = widget.history?.generation ?? 0;
    final choice = await Navigator.of(context).push<AiReviewChoice>(
      MaterialPageRoute(
        builder: (_) => AiReviewScreen(
          input: ScanInput(_result.text, source: _result.source),
        ),
      ),
    );
    _reviewingAi = false;
    if (!mounted ||
        choice == null ||
        generation != (widget.history?.generation ?? 0)) {
      return;
    }
    _aiScan.cancel();
    if (choice.text != _result.text) {
      _linkRevision++;
      _client?.close();
      _checkingLinks = false;
      _result = ScamAnalyzer().analyze(
        ScanInput(choice.text, source: _result.source),
      );
      _highlight = null;
    }
    if (choice.send) {
      await _startAi(
        ReviewedAiInput(
          text: choice.text,
          source: _result.source,
          responseLanguage:
              Localizations.localeOf(context).languageCode == 'fil'
              ? 'fil'
              : 'en',
          inputRevision: ++_aiRevision,
          privacyGeneration: generation,
        ),
      );
    } else {
      setState(
        () => _result = _result.withAi(
          const AiAssessment(AiScanState.notRequested),
          reviewed: true,
        ),
      );
      _aiScan.result = _result;
      try {
        await widget.history?.save(_result, expectedGeneration: generation);
      } catch (_) {
        if (mounted) setState(() => _saveFailed = true);
      }
    }
  }

  void _scheduleCoverageExpiry() {
    _coverageTimer?.cancel();
    final now = DateTime.now();
    final deadlines =
        _result.links
            .map((l) => l.reputationDeadline)
            .whereType<DateTime>()
            .where((d) => d.isAfter(now))
            .toList()
          ..sort();
    if (deadlines.isNotEmpty) {
      _coverageTimer = Timer(deadlines.first.difference(now), () {
        if (mounted) {
          setState(() {});
          _scheduleCoverageExpiry();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _aiScan.cancel();
    }
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _scheduleCoverageExpiry();
    }
  }

  @override
  void dispose() {
    _coverageTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.history?.removeListener(_privacyChanged);
    _aiScan.removeListener(_aiChanged);
    _aiScan.dispose();
    _linkRevision++;
    _client?.close();
    super.dispose();
  }

  Future<void> _checkLinks() async {
    if (_checkingLinks) {
      return;
    }
    final l = AppLocalizations.of(context);
    final client = widget.reputationFactory?.call() ?? ReputationClient();
    if (!client.configured) {
      client.close();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.gatewayMissing)));
      return;
    }
    if (widget.settings?.onlineLinkChecks != true) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.onlineDisclosure),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.onlineBody),
                const SizedBox(height: 16),
                for (final link in _result.links.where(
                  (link) => link.uri != null,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(link.uri!.removeFragment().toString()),
                        if (link.schemeAssumed) Text(l.assumedHttps),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.localOnly),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.enableOnline),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        client.close();
        return;
      }
      try {
        await widget.settings?.update(onlineLinkChecks: true);
      } catch (_) {
        client.close();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l.saveFailed)));
        }
        return;
      }
    }
    if (!mounted) {
      client.close();
      return;
    }
    final revision = ++_linkRevision;
    final generation = widget.history?.generation;
    _client = client;
    setState(() => _checkingLinks = true);
    final links = List<LinkResult>.of(_result.links);
    final completed = <String, ReputationCheck>{};
    try {
      final uris = links
          .where((link) => link.uri != null)
          .map((link) => link.uri!.toString())
          .toSet()
          .toList();
      for (var offset = 0; offset < uris.length; offset += 2) {
        if (!mounted || revision != _linkRevision) {
          return;
        }
        await Future.wait(
          uris.skip(offset).take(2).map((url) async {
            completed[url] = await client.check(Uri.parse(url));
          }),
        );
      }
      if (!mounted || revision != _linkRevision) {
        return;
      }
      final updated = _result.withLinks(
        links.map((link) {
          final check = completed[link.uri?.toString()];
          return check == null
              ? link
              : link.withReputation(
                  check.state,
                  at: check.checkedAt,
                  until: check.expiresAt,
                  threats: check.threatTypes,
                  provider: check.provider,
                );
        }).toList(),
      );
      setState(() {
        _result = updated;
        _aiScan.result = updated;
      });
      _scheduleCoverageExpiry();
      if (generation != null) {
        try {
          await widget.history!.save(updated, expectedGeneration: generation);
        } catch (_) {
          if (mounted) {
            setState(() => _saveFailed = true);
          }
        }
      }
    } finally {
      client.close();
      if (mounted && revision == _linkRevision) {
        setState(() => _checkingLinks = false);
      }
    }
  }

  void _showEvidence(Finding finding) {
    setState(() {
      _highlight = finding;
      _originalOpen = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_originalKey.currentContext != null) {
        Scrollable.ensureVisible(
          _originalKey.currentContext!,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final result = _result;
    final (color, background, icon) = UsisaTheme.risk(context, result.risk);
    final copy = switch (result.risk) {
      RiskLevel.high => l.highCopy,
      RiskLevel.caution => l.cautionCopy,
      RiskLevel.low => l.lowCopy,
    };
    final next = result.findings.any((f) => f.code == 'codeRequest')
        ? l.secretAdvice
        : result.findings.any((f) => f.code == 'paymentRequest')
        ? l.paymentAdvice
        : l.verifyAdvice;
    final ai = result.aiAssessment;
    final aiState = ai?.state ?? AiScanState.notRequested;
    final aiStatus = switch (aiState) {
      AiScanState.notRequested => l.aiNotRequested,
      AiScanState.checking => l.aiChecking,
      AiScanState.unavailable => l.aiUnavailable,
      AiScanState.unableToAssess => l.aiUnknown,
      AiScanState.cancelled => l.aiCancelled,
      AiScanState.completed => l.riskLabel(ai!.risk!.name),
    };
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _aiScan.cancel();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l.result)),
        body: SafeArea(
          top: false,
          child: PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: color, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          l.riskLabel(result.risk.name),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          copy,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: color,
                          ),
                        ),
                        if (result.hasUncheckedLinks) ...[
                          const SizedBox(height: 16),
                          Text(
                            l.unknownLink,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l.localChecked),
                if (result.reviewedForAi) ...[
                  const SizedBox(height: 8),
                  Text(l.aiReviewed),
                ],
                if (aiState == AiScanState.checking) ...[
                  const SizedBox(height: 12),
                  Semantics(liveRegion: true, child: Text(l.aiChecking)),
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                  TextButton(onPressed: _aiScan.cancel, child: Text(l.cancel)),
                ],
                if (_saveFailed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(l.notSaved),
                  ),
                const SizedBox(height: 24),
                Text(next, style: theme.textTheme.titleLarge),
                const SizedBox(height: 32),
                Text(
                  '${l.onDeviceFindings} · ${l.riskLabel(result.localRisk.name)}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  result.findings.isEmpty ? l.noWarnings : l.whyFlagged,
                  style: theme.textTheme.titleLarge,
                ),
                for (final finding in result.findings)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.info_outline_rounded),
                      title: Text(l.findingTitle(finding.code)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${l.findingBody(finding.code)}\n“${finding.evidence}”',
                        ),
                      ),
                      trailing: const Icon(Icons.expand_more_rounded),
                      onTap: () => _showEvidence(finding),
                    ),
                  ),
                const SizedBox(height: 32),
                Text(l.aiAssessment, style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                if (aiState != AiScanState.checking)
                  Semantics(liveRegion: true, child: Text(aiStatus)),
                if (ai?.modelId != null) ...[
                  const SizedBox(height: 8),
                  Text('Groq · ${ai!.modelId} · ${ai.promptVersion}'),
                  if (ai.checkedAt != null)
                    Text(
                      l.checkedAtLabel(
                        '${MaterialLocalizations.of(context).formatCompactDate(ai.checkedAt!.toLocal())} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(ai.checkedAt!.toLocal()))}',
                      ),
                    ),
                ],
                if (ai?.summary.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(ai!.summary),
                ],
                if (ai?.state == AiScanState.completed &&
                    ai?.risk != result.localRisk) ...[
                  const SizedBox(height: 12),
                  Text(l.aiDisagreement),
                ],
                for (final finding in ai?.findings ?? <Finding>[])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.auto_awesome_outlined),
                    title: Text(l.aiFindingTitle(finding.code)),
                    subtitle: Text('“${finding.evidence}”'),
                    onTap: () => _showEvidence(finding),
                  ),
                for (final code in ai?.recommendationCodes ?? <String>[])
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(l.aiAdvice(code)),
                  ),
                const SizedBox(height: 12),
                Text(l.aiLimitations, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _aiScan.busy || _reviewingAi ? null : _reviewAi,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: Text(
                    aiState == AiScanState.unavailable ||
                            aiState == AiScanState.cancelled ||
                            aiState == AiScanState.unableToAssess
                        ? l.aiRetry
                        : l.aiReviewTitle,
                  ),
                ),
                if (result.links.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(l.linksInMessage, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  for (final link in result.links)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      leading: const Icon(Icons.link_rounded),
                      title: Text(link.host),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_coverageText(context, link)),
                          if (link.provider != null) Text(link.provider!),
                          if (link.provider == safeBrowsingProvider &&
                              link.currentReputation == ReputationState.matched)
                            TextButton(
                              onPressed: () => _openHelp(
                                'https://developers.google.com/safe-browsing/v4/advisory',
                              ),
                              child: Text(l.googleAdvisory),
                            ),
                        ],
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SelectableText(
                                  link.original,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                if (link.schemeAssumed) Text(l.assumedHttps),
                                if (link.provider == safeBrowsingProvider &&
                                    link.currentReputation ==
                                        ReputationState.matched)
                                  Wrap(
                                    children: [
                                      if (link.threatTypes.contains(
                                        'SOCIAL_ENGINEERING',
                                      ))
                                        TextButton(
                                          onPressed: () => _openHelp(
                                            'https://www.antiphishing.org/',
                                          ),
                                          child: Text(l.phishingHelp),
                                        ),
                                      if (link.threatTypes.contains('MALWARE'))
                                        TextButton(
                                          onPressed: () => _openHelp(
                                            'https://developers.google.com/search/',
                                          ),
                                          child: Text(l.malwareHelp),
                                        ),
                                      if (link.threatTypes.contains(
                                        'UNWANTED_SOFTWARE',
                                      ))
                                        TextButton(
                                          onPressed: () => _openHelp(
                                            'https://www.google.com/about/unwanted-software-policy.html',
                                          ),
                                          child: Text(l.unwantedHelp),
                                        ),
                                    ],
                                  ),
                                for (final finding in link.findings)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l.findingTitle(finding.code),
                                          style: theme.textTheme.titleSmall,
                                        ),
                                        Text(l.findingBody(finding.code)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _checkingLinks ? null : _checkLinks,
                    icon: const Icon(Icons.cloud_outlined),
                    label: Text(
                      _checkingLinks ? l.checkingLinks : l.checkOnline,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Text(l.nextSteps, style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final advice in [
                  l.verifyAdvice,
                  l.secretAdvice,
                  if (result.risk != RiskLevel.low) l.clickedAdvice,
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_right_rounded),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(advice, style: theme.textTheme.bodyLarge),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.originalText),
                  trailing: Icon(
                    _originalOpen ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: () => setState(() => _originalOpen = !_originalOpen),
                ),
                if (_originalOpen)
                  Container(
                    key: _originalKey,
                    padding: const EdgeInsets.all(16),
                    color: theme.colorScheme.surface,
                    child: SelectableText.rich(_originalSpan(theme)),
                  ),
                const SizedBox(height: 12),
                Text(
                  '${l.sourceLabel(result.source.name)} • ${MaterialLocalizations.of(context).formatMediumDate(result.createdAt.toLocal())} • ${result.ruleVersion}',
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.newScan),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _originalSpan(ThemeData theme) {
    final text = _result.text;
    final f = _highlight;
    if (f?.start == null ||
        f?.end == null ||
        f!.start! < 0 ||
        f.end! > text.length ||
        f.start! > f.end! ||
        text.substring(f.start!, f.end) != f.evidence) {
      return TextSpan(text: text, style: theme.textTheme.bodyLarge);
    }
    return TextSpan(
      style: theme.textTheme.bodyLarge,
      children: [
        TextSpan(text: text.substring(0, f.start)),
        TextSpan(
          text: f.evidence,
          style: TextStyle(
            backgroundColor: theme.colorScheme.primaryContainer,
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextSpan(text: text.substring(f.end!)),
      ],
    );
  }
}
