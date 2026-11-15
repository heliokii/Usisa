import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/usisa_theme.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_body.dart';
import '../../widgets/usisa_modal.dart';
import '../../widgets/usisa_action_button.dart';
import '../../widgets/usisa_loading_indicator.dart';
import '../home/feature_artwork.dart';
import 'scan_models.dart';
import 'reputation_client.dart';
import 'ai_models.dart';
import 'ai_scan_client.dart';
import 'ai_review_screen.dart';
import 'scan_controller.dart';
import 'scam_analyzer.dart';
import '../history/history_store.dart';
import '../settings/settings_store.dart';

class _ResultBannerPalette {
  const _ResultBannerPalette({
    required this.background,
    required this.gradientStart,
    required this.gradientEnd,
    required this.waveAccent,
    required this.textColor,
    required this.contentType,
  });

  final Color background;
  final Color gradientStart;
  final Color gradientEnd;
  final Color waveAccent;
  final Color textColor;
  final ContentType contentType;
}

const _safeBannerPalette = _ResultBannerPalette(
  background: Color(0xFF2E9B70),
  gradientStart: Color(0xFF39A879),
  gradientEnd: Color(0xFF006B4B),
  waveAccent: Color(0xFF087A56),
  textColor: Colors.white,
  contentType: ContentType.success,
);
const _reviewBannerPalette = _ResultBannerPalette(
  background: Color(0xFFFFC857),
  gradientStart: Color(0xFFFFD77A),
  gradientEnd: Color(0xFFF5A623),
  waveAccent: Color(0xFFE99A16),
  textColor: Color(0xFF704000),
  contentType: ContentType.warning,
);
const _highRiskBannerPalette = _ResultBannerPalette(
  background: Color(0xFFF2452E),
  gradientStart: Color(0xFFFF654F),
  gradientEnd: Color(0xFFD92D20),
  waveAccent: Color(0xFFC92B1D),
  textColor: Colors.white,
  contentType: ContentType.failure,
);
const _unknownBannerPalette = _ResultBannerPalette(
  background: Color(0xFF8E4CC6),
  gradientStart: Color(0xFFA65DDB),
  gradientEnd: Color(0xFF542080),
  waveAccent: Color(0xFF452066),
  textColor: Colors.white,
  contentType: ContentType.help,
);

Color _bannerDarkColor(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - .1).clamp(0.0, 1.0)).toColor();
}

String _bannerIconAsset(ContentType contentType) {
  switch (contentType) {
    case ContentType.failure:
      return 'assets/types/failure.svg';
    case ContentType.success:
      return 'assets/types/success.svg';
    case ContentType.help:
      return 'assets/types/help.svg';
    case ContentType.warning:
      return 'assets/types/warning.svg';
    default:
      return 'assets/types/failure.svg';
  }
}

void _paintResultBanner(
  Canvas canvas,
  Size size,
  _ResultBannerPalette palette,
) {
  final rect = Offset.zero & size;
  final gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [palette.gradientStart, palette.background, palette.gradientEnd],
    stops: const [0, 0.45, 1],
  ).createShader(rect);
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(20)),
    Paint()..shader = gradient,
  );
  final wave = Path()
    ..moveTo(0, size.height * .74)
    ..cubicTo(
      size.width * .18,
      size.height * .62,
      size.width * .31,
      size.height * .92,
      size.width * .5,
      size.height * .76,
    )
    ..cubicTo(
      size.width * .7,
      size.height * .59,
      size.width * .84,
      size.height * .86,
      size.width,
      size.height * .7,
    )
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();
  canvas.drawPath(
    wave,
    Paint()..color = palette.waveAccent.withValues(alpha: .28),
  );
}

class _ResultBannerPainter extends CustomPainter {
  const _ResultBannerPainter(this.palette);

  final _ResultBannerPalette palette;

  @override
  void paint(Canvas canvas, Size size) =>
      _paintResultBanner(canvas, size, palette);

  @override
  bool shouldRepaint(covariant _ResultBannerPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

class _ResultBannerBadgePainter extends CustomPainter {
  const _ResultBannerBadgePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final badge = Path()
      ..moveTo(43.8057, 67.6794)
      ..cubicTo(44.1346, 67.4706, 44.4935, 67.3124, 44.8667, 67.2006)
      ..cubicTo(59.012, 62.9621, 69.3202, 49.8448, 69.3202, 34.32)
      ..cubicTo(69.3202, 15.3656, 53.9546, 0, 35.0002, 0)
      ..cubicTo(16.0458, 0, 0.680176, 15.3656, 0.680176, 34.32)
      ..cubicTo(0.680176, 47.8227, 8.47798, 59.5042, 19.816, 65.1068)
      ..cubicTo(19.8288, 65.1132, 19.8236, 65.1326, 19.8093, 65.1315)
      ..cubicTo(19.8002, 65.1308, 19.7932, 65.1396, 19.796, 65.1483)
      ..lineTo(22.904, 74.9903)
      ..cubicTo(23.6949, 77.4949, 26.644, 78.5705, 28.8616, 77.1631)
      ..lineTo(43.8057, 67.6794)
      ..close();
    canvas
      ..scale(size.height / 78)
      ..drawPath(badge, Paint()..color = _bannerDarkColor(color));
  }

  @override
  bool shouldRepaint(covariant _ResultBannerBadgePainter oldDelegate) =>
      oldDelegate.color != color;
}

// shortcut: package fixes its close button, repaint this slot if its layout changes.
class _ResultBannerCloseMaskPainter extends CustomPainter {
  const _ResultBannerCloseMaskPainter(
    this.palette,
    this.bannerSize,
    this.offset,
  );

  final _ResultBannerPalette palette;
  final Size bannerSize;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(-offset.dx, -offset.dy);
    _paintResultBanner(canvas, bannerSize, palette);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ResultBannerCloseMaskPainter oldDelegate) =>
      oldDelegate.palette != palette ||
      oldDelegate.bannerSize != bannerSize ||
      oldDelegate.offset != offset;
}

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
    this.screenshotPreview,
  });
  final ScanResult result;
  final bool saved;
  final HistoryStore? history;
  final SettingsStore? settings;
  final ReputationClient Function()? reputationFactory;
  final Future<bool> Function(Uri)? advisoryLauncher;
  final AiScanClient Function()? aiFactory;
  final ReviewedAiInput? initialAiInput;
  final Uint8List? screenshotPreview;
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
  bool _initialAiPending = false;
  bool _checkingLinks = false;
  ReputationClient? _client;
  int _linkRevision = 0;
  String _coverageText(BuildContext context, LinkResult link) {
    final l = AppLocalizations.of(context);
    var text = link.reputationExpired
        ? '${link.reputation == ReputationState.matched ? '${l.previousThreat}\n' : ''}${l.reputationExpired}'
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

  Widget _statusBanner(
    String title,
    String message,
    _ResultBannerPalette palette,
  ) {
    final screenSize = MediaQuery.sizeOf(context);
    final mobile = screenSize.width <= 768;
    final horizontalPadding = screenSize.width <= 768
        ? screenSize.width * .01
        : screenSize.width <= 992
        ? screenSize.width * .2
        : screenSize.width * .3;
    final leftSpace = screenSize.width * (mobile ? .12 : .05);
    const badgeHeight = 56.0;
    const badgeIconSize = 28.0;
    const textOffset = 12.0;
    final packageBadgeLeft =
        horizontalPadding +
        leftSpace -
        8 -
        screenSize.width * (mobile ? .075 : .035);
    final badgeWidth = badgeHeight * 70 / 78;
    final badgeLeft = packageBadgeLeft - (badgeWidth - 45 * 70 / 78) / 2;
    final badgeTop =
        -screenSize.height * .015 - (badgeHeight - 45) * 34.32 / 78;
    final iconCenter = Offset(
      badgeLeft + badgeWidth / 2,
      badgeTop + badgeHeight * 34.32 / 78,
    );
    final textLeft = horizontalPadding + leftSpace + textOffset;
    final textRight = horizontalPadding + screenSize.width * .03;
    return Semantics(
      container: true,
      label: '$title. $message',
      liveRegion: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bannerSize = Size(constraints.maxWidth, mobile ? 90 : 130);
          final closeOffset = Offset(constraints.maxWidth - textRight - 48, 5);
          return SizedBox(
            width: constraints.maxWidth,
            height: bannerSize.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomPaint(painter: _ResultBannerPainter(palette)),
                  ),
                ),
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ExcludeSemantics(
                      child: IgnorePointer(
                        child: AwesomeSnackbarContent(
                          title: '',
                          message: '',
                          color: Colors.transparent,
                          contentType: palette.contentType,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: badgeLeft,
                  top: badgeTop,
                  width: badgeWidth,
                  height: badgeHeight,
                  child: CustomPaint(
                    painter: _ResultBannerBadgePainter(palette.background),
                  ),
                ),
                Positioned(
                  left: textLeft,
                  right: textRight,
                  top: 14,
                  bottom: 10,
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              message,
                              maxLines: mobile ? 2 : 3,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.textColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: closeOffset.dy,
                  right: textRight,
                  width: 48,
                  height: 48,
                  child: CustomPaint(
                    painter: _ResultBannerCloseMaskPainter(
                      palette,
                      bannerSize,
                      closeOffset,
                    ),
                  ),
                ),
                Positioned(
                  left: iconCenter.dx - badgeIconSize / 2,
                  top: iconCenter.dy - badgeIconSize / 2,
                  width: badgeIconSize,
                  height: badgeIconSize,
                  child: ExcludeSemantics(
                    child: SvgPicture.asset(
                      _bannerIconAsset(palette.contentType),
                      package: 'awesome_snackbar_content',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
      _initialAiPending = true;
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
    if (_initialAiPending) {
      setState(() => _initialAiPending = false);
    }
    _aiGeneration = input.privacyGeneration;
    _aiScan.result = _result;
    await _aiScan.checkAi(
      input,
      client: widget.aiFactory?.call() ?? AiScanClient(),
      history: widget.history,
    );
  }

  Future<void> _reviewAi() async {
    if (_aiScan.busy || _reviewingAi || widget.settings?.aiScanning == false) {
      return;
    }
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
      final analyzed = ScamAnalyzer().analyze(
        ScanInput(choice.text, source: _result.source),
      );
      _result = ScanResult(
        id: _result.id,
        text: analyzed.text,
        source: analyzed.source,
        findings: analyzed.findings,
        links: analyzed.links,
        createdAt: _result.createdAt,
        ruleVersion: analyzed.ruleVersion,
        reviewedForAi: true,
      );
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
      final confirmed = await UsisaModal.show(
        context: context,
        title: l.onlineDisclosure,
        message: l.onlineBody,
        primaryLabel: l.enableOnline,
        secondaryLabel: l.localOnly,
        variant: UsisaModalVariant.info,
        details: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final link in _result.links.where((link) => link.uri != null))
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

  Future<void> _showEvidence(Finding finding) {
    final l = AppLocalizations.of(context);
    return _showResultSheet(
      l.findingTitle(finding.code),
      children: [
        Text(l.findingBody(finding.code)),
        if (finding.evidence.isNotEmpty) ...[
          const SizedBox(height: 12),
          GlassSurface(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SelectableText('“${finding.evidence}”'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showRecommendations() {
    final l = AppLocalizations.of(context);
    final result = _result;
    final recommendations = <String>{
      result.findings.any((f) => f.code == 'codeRequest')
          ? l.secretAdvice
          : l.verifyAdvice,
      if (result.findings.any((f) => f.code == 'paymentRequest'))
        l.paymentAdvice,
      if (result.risk != RiskLevel.low) l.clickedAdvice,
      ...?result.aiAssessment?.recommendationCodes.map(l.aiAdvice),
    };
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.nextSteps, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              for (final advice in recommendations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(advice, style: theme.textTheme.bodyLarge),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _aiProgress(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.aiScan)),
      body: SafeArea(
        top: false,
        bottom: false,
        child: PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 44),
              const Center(child: AiAnalysisArtwork(size: 188)),
              const SizedBox(height: 24),
              Text(
                l.aiProgressTitle,
                semanticsLabel: l.aiChecking,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  Icons.check_circle_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: Text(l.aiStageReviewed),
              ),
              ListTile(
                leading: Icon(
                  Icons.check_circle_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: Text(l.aiStageLocal),
              ),
              ListTile(
                leading: const SizedBox.square(
                  dimension: 22,
                  child: UsisaLoadingIndicator(
                    size: 22,
                    color: UsisaTheme.contrastCoral,
                  ),
                ),
                title: Text(l.aiStageRequest),
              ),
              ListTile(
                leading: Icon(
                  Icons.radio_button_unchecked_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(l.aiStageResult),
              ),
              const SizedBox(height: 20),
              OutlinedButton(onPressed: _aiScan.cancel, child: Text(l.cancel)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showResultSheet(
    String title, {
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => PageBody(
        bottomPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _showOriginalText() {
    final l = AppLocalizations.of(context);
    return _showResultSheet(
      l.originalText,
      children: [SelectableText(_result.text)],
    );
  }

  Future<void> _showLinkDetails(LinkResult link) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _showResultSheet(
      l.fullLink,
      children: [
        SelectableText(link.original, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        _detailRow(l.linkDomainLabel, link.host),
        if (link.findings.any((finding) => finding.code == 'deceptiveHost'))
          _detailRow(l.linkSimilarityLabel, l.findingBody('deceptiveHost')),
        _detailRow(l.linkStatusLabel, _coverageText(context, link)),
        if (link.provider != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(link.provider!, style: theme.textTheme.bodySmall),
          ),
        if (link.schemeAssumed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l.assumedHttps),
          ),
        if (link.findings.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(l.detectedSigns, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final finding in link.findings) _findingRow(finding),
        ],
        if (link.provider == safeBrowsingProvider &&
            link.currentReputation == ReputationState.matched)
          Wrap(
            children: [
              TextButton(
                onPressed: () => _openHelp(
                  'https://developers.google.com/safe-browsing/v4/advisory',
                ),
                child: Text(l.googleAdvisory),
              ),
              if (link.threatTypes.contains('SOCIAL_ENGINEERING'))
                TextButton(
                  onPressed: () => _openHelp('https://www.antiphishing.org/'),
                  child: Text(l.phishingHelp),
                ),
              if (link.threatTypes.contains('MALWARE'))
                TextButton(
                  onPressed: () =>
                      _openHelp('https://developers.google.com/search/'),
                  child: Text(l.malwareHelp),
                ),
              if (link.threatTypes.contains('UNWANTED_SOFTWARE'))
                TextButton(
                  onPressed: () => _openHelp(
                    'https://www.google.com/about/unwanted-software-policy.html',
                  ),
                  child: Text(l.unwantedHelp),
                ),
            ],
          ),
        if (link.uri != null)
          OutlinedButton.icon(
            onPressed: _checkingLinks ? null : _checkLinksFromSheet,
            icon: const Icon(Icons.travel_explore_rounded),
            label: Text(_checkingLinks ? l.checkingLinks : l.checkOnline),
          ),
      ],
    );
  }

  void _showLinkDetailsFromSheet(LinkResult link) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_showLinkDetails(link));
    });
  }

  void _checkLinksFromSheet() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_checkLinks());
    });
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(child: SelectableText(value)),
      ],
    ),
  );

  Future<void> _showLinks() {
    final l = AppLocalizations.of(context);
    final links = _result.links;
    return _showResultSheet(
      l.linksInMessage,
      children: [
        for (final link in links)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.link_rounded),
            title: Text(link.host),
            subtitle: Text(_coverageText(context, link)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showLinkDetailsFromSheet(link),
          ),
        if (_result.source != ScanSource.link)
          OutlinedButton.icon(
            onPressed: _checkingLinks ? null : _checkLinksFromSheet,
            icon: const Icon(Icons.cloud_outlined),
            label: Text(_checkingLinks ? l.checkingLinks : l.checkOnline),
          ),
      ],
    );
  }

  Future<void> _showAllFindings(List<Finding> findings) {
    final l = AppLocalizations.of(context);
    return _showResultSheet(
      l.detectedSigns,
      children: [for (final finding in findings) _findingRow(finding)],
    );
  }

  Widget _findingRow(Finding finding) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _showEvidence(finding),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              finding.code.contains('link')
                  ? Icons.link_rounded
                  : Icons.warning_amber_rounded,
              color: UsisaTheme.contrastCoral,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.findingTitle(finding.code),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    l.findingBody(finding.code),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _sourceCard(AppLocalizations l, ThemeData theme) {
    final result = _result;
    final link = result.links.isEmpty ? null : result.links.first;
    final sourceIcon = result.source == ScanSource.link
        ? Icons.link_rounded
        : result.source == ScanSource.screenshot
        ? Icons.image_outlined
        : Icons.sms_outlined;
    final sourceTitle = result.source == ScanSource.link
        ? l.fullLink
        : l.sourceLabel(result.source.name);

    Widget sourceText() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sourceTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 3),
        Text(
          result.source == ScanSource.link
              ? link?.host ?? result.text
              : result.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );

    return GlassSurface(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: switch (result.source) {
          ScanSource.screenshot => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.screenshotPreview != null) ...[
                Semantics(
                  button: true,
                  label: l.viewFullImage,
                  child: Tooltip(
                    message: l.viewFullImage,
                    child: InkWell(
                      onTap: _showScreenshotPreview,
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 76,
                        height: 64,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(
                                widget.screenshotPreview!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.broken_image_outlined),
                              ),
                              const Align(
                                alignment: Alignment.bottomRight,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0x99000000),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.zoom_in_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ] else ...[
                Icon(sourceIcon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
              ],
              Expanded(child: sourceText()),
            ],
          ),
          ScanSource.link => InkWell(
            onTap: link == null ? null : () => _showLinkDetails(link),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Icon(sourceIcon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: sourceText()),
                if (link != null) const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          ScanSource.text || ScanSource.sms => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(sourceIcon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(child: sourceText()),
            ],
          ),
        },
      ),
    );
  }

  Future<void> _showScreenshotPreview() {
    final bytes = widget.screenshotPreview;
    if (bytes == null) return Future<void>.value();
    final l = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => PageBody(
        bottomPadding: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.screenshot,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * .68,
              child: InteractiveViewer(
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      Center(child: Text(l.previewUnavailable)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _aiStatus(AppLocalizations l, AiAssessment? assessment) {
    final state = assessment?.state ?? AiScanState.notRequested;
    return switch (state) {
      AiScanState.notRequested => l.aiNotRequested,
      AiScanState.checking => l.aiChecking,
      AiScanState.unavailable => l.aiUnavailable,
      AiScanState.unableToAssess => l.aiUnknown,
      AiScanState.cancelled => l.aiCancelled,
      AiScanState.completed =>
        assessment?.risk == null
            ? l.aiUnknown
            : l.riskLabel(assessment!.risk!.name),
    };
  }

  String _riskCopy(AppLocalizations l, RiskLevel risk) => switch (risk) {
    RiskLevel.high => l.highCopy,
    RiskLevel.caution => l.cautionCopy,
    RiskLevel.low => l.lowCopy,
  };

  Future<void> _showAiAssessment() {
    final l = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ListenableBuilder(
        listenable: _aiScan,
        builder: (context, _) {
          final assessment = _aiScan.result?.id == _result.id
              ? _aiScan.result?.aiAssessment ?? _result.aiAssessment
              : _result.aiAssessment;
          final state = assessment?.state ?? AiScanState.notRequested;
          final theme = Theme.of(context);
          final canReview =
              widget.settings?.aiScanning != false &&
              !_aiScan.busy &&
              !_reviewingAi;
          return PageBody(
            bottomPadding: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: AiAnalysisArtwork(size: 104, loading: false),
                ),
                const SizedBox(height: 8),
                Text(
                  l.aiAssessment,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                GlassSurface(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.aiAssessment,
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(_aiStatus(l, assessment)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state == AiScanState.checking) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      UsisaLoadingIndicator(
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l.aiChecking,
                          softWrap: true,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _aiScan.cancel,
                      child: Text(l.cancel),
                    ),
                  ),
                ],
                if (state == AiScanState.completed &&
                    assessment?.risk != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _riskCopy(l, assessment!.risk!),
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (assessment.risk != _result.localRisk) ...[
                    const SizedBox(height: 8),
                    Text(l.aiDisagreement),
                  ],
                ],
                if (assessment?.modelId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    [
                      'Groq',
                      assessment!.modelId!,
                      if (assessment.promptVersion != null)
                        assessment.promptVersion!,
                    ].join(' · '),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (assessment.checkedAt != null)
                    Text(
                      l.checkedAtLabel(
                        '${MaterialLocalizations.of(context).formatCompactDate(assessment.checkedAt!.toLocal())} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(assessment.checkedAt!.toLocal()))}',
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
                if (assessment?.findings.isNotEmpty == true) ...[
                  const SizedBox(height: 20),
                  Text(l.warningSigns, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final finding in assessment!.findings)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.warning_amber_rounded,
                        color: UsisaTheme.contrastCoral,
                      ),
                      title: Text(l.aiFindingTitle(finding.code)),
                      subtitle: finding.evidence.isEmpty
                          ? null
                          : Text('“${finding.evidence}”'),
                      onTap: () => _showEvidence(finding),
                    ),
                ],
                if (state != AiScanState.checking) ...[
                  const SizedBox(height: 16),
                  Text(l.aiLimitations, style: theme.textTheme.bodySmall),
                  if (canReview) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _reviewAi,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        state == AiScanState.unavailable ||
                                state == AiScanState.cancelled ||
                                state == AiScanState.unableToAssess
                            ? l.aiRetry
                            : l.aiReviewTitle,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _aiSummaryCard(String status, AiScanState state) {
    final canReview =
        widget.settings?.aiScanning != false && !_aiScan.busy && !_reviewingAi;
    return GlassSurface(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _showAiAssessment,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).aiAssessment,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            if (canReview)
              TextButton(
                onPressed: _reviewAi,
                child: Text(AppLocalizations.of(context).checkAiShort),
              ),
            if (state == AiScanState.checking)
              IconButton(
                tooltip: AppLocalizations.of(context).cancel,
                onPressed: _aiScan.cancel,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => GlassSurface(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final result = _result;
    final bannerIsUnknown =
        result.risk == RiskLevel.low && result.hasUncheckedLinks;
    final bannerPalette = bannerIsUnknown
        ? _unknownBannerPalette
        : switch (result.risk) {
            RiskLevel.low => _safeBannerPalette,
            RiskLevel.caution => _reviewBannerPalette,
            RiskLevel.high => _highRiskBannerPalette,
          };
    final findings = <Finding>[
      ...result.findings,
      ...result.links.expand((link) => link.findings),
    ];
    final visibleFindings = findings.take(3).toList();
    final aiState = result.aiAssessment?.state ?? AiScanState.notRequested;
    final showAi =
        aiState != AiScanState.notRequested ||
        result.reviewedForAi ||
        widget.settings?.aiScanning != false;
    final bannerMessage = result.links.isEmpty
        ? _riskCopy(l, result.risk)
        : result.links.any(
            (link) => link.currentReputation == ReputationState.matched,
          )
        ? l.knownThreat
        : result.hasUncheckedLinks
        ? l.unknownLink
        : l.notListed;
    final bannerTitle = bannerIsUnknown
        ? l.unknownStatus
        : l.resultRiskLabel(result.risk.name);
    final anotherLabel = switch (result.source) {
      ScanSource.link => l.checkAnotherLink,
      ScanSource.screenshot => l.checkAnotherScreenshot,
      ScanSource.text || ScanSource.sms => l.newScan,
    };

    if (_initialAiPending || (widget.initialAiInput != null && _aiScan.busy)) {
      return PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) _aiScan.cancel();
        },
        child: _aiProgress(context),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _aiScan.cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            result.source == ScanSource.link
                ? l.linkCheckerTitle
                : result.reviewedForAi || result.aiAssessment != null
                ? l.aiScanResult
                : l.result,
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: UsisaActionButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(anotherLabel, textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showRecommendations,
                    icon: const Icon(Icons.shield_outlined),
                    label: Text(l.safetyRecommendations),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final largeText = MediaQuery.textScalerOf(context).scale(16) > 20;
              final useScrollingLayout =
                  constraints.maxHeight < 560 || largeText;
              return PageBody(
                scrollable: useScrollingLayout,
                bottomPadding: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: useScrollingLayout
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _statusBanner(bannerTitle, bannerMessage, bannerPalette),
                    if (_saveFailed) ...[
                      const SizedBox(height: 6),
                      Text(l.notSaved, style: theme.textTheme.bodySmall),
                    ],
                    if (result.reviewedForAi) ...[
                      const SizedBox(height: 4),
                      Text(l.aiReviewed, style: theme.textTheme.bodySmall),
                    ],
                    const SizedBox(height: 8),
                    _sourceCard(l, theme),
                    if (_checkingLinks) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          UsisaLoadingIndicator(
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l.checkingLinks,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      result.source == ScanSource.link &&
                              result.risk != RiskLevel.low
                          ? l.linkWhyRisky
                          : l.detectedSigns,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (findings.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: GlassSurface(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.verified_outlined,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(l.noWarnings)),
                              ],
                            ),
                          ),
                        ),
                      )
                    else ...[
                      GlassSurface(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < visibleFindings.length;
                                index++
                              ) ...[
                                if (index > 0)
                                  const Divider(height: 1, indent: 34),
                                _findingRow(visibleFindings[index]),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (findings.length > visibleFindings.length)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 32),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _showAllFindings(findings),
                            child: Text(
                              l.resultMoreFindings(
                                findings.length - visibleFindings.length,
                              ),
                            ),
                          ),
                        ),
                    ],
                    if (showAi) ...[
                      const SizedBox(height: 4),
                      _aiSummaryCard(
                        _aiStatus(l, result.aiAssessment),
                        aiState,
                      ),
                    ],
                    if (result.source != ScanSource.link ||
                        result.links.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildDetailTiles(l, result),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTiles(AppLocalizations l, ScanResult result) {
    final tiles = <Widget>[];
    if (result.source == ScanSource.link && result.links.isNotEmpty) {
      final link = result.links.first;
      tiles.add(
        _detailTile(
          icon: Icons.link_rounded,
          title: l.fullLink,
          subtitle: link.host,
          onTap: () => _showLinkDetails(link),
        ),
      );
    } else if (result.links.isNotEmpty) {
      tiles.add(
        _detailTile(
          icon: Icons.link_rounded,
          title: l.linksInMessage,
          subtitle: l.resultLinkCount(result.links.length),
          onTap: _showLinks,
        ),
      );
    }
    if (result.source != ScanSource.link) {
      tiles.add(
        _detailTile(
          icon: Icons.article_outlined,
          title: l.originalText,
          subtitle: l.sourceLabel(result.source.name),
          onTap: _showOriginalText,
        ),
      );
    }
    if (tiles.isEmpty) return const SizedBox.shrink();
    if (tiles.length == 1) return tiles.single;
    return Row(
      children: [
        Expanded(child: tiles[0]),
        const SizedBox(width: 10),
        Expanded(child: tiles[1]),
      ],
    );
  }
}
