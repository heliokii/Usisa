import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/usisa_theme.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_body.dart';
import '../sms/sms_service.dart';
import 'feature_artwork.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.sms,
    required this.onMessage,
    required this.onLink,
    required this.onScreenshot,
    required this.onAi,
    required this.onSms,
    required this.onSmsToggle,
    required this.onRecentSms,
    required this.aiEnabled,
  });

  final SmsService sms;
  final VoidCallback onMessage;
  final VoidCallback onLink;
  final VoidCallback onScreenshot;
  final VoidCallback onAi;
  final VoidCallback onSms;
  final ValueChanged<bool> onSmsToggle;
  final VoidCallback onRecentSms;
  final bool aiEnabled;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final minCardExtent = l.localeName == 'fil' ? 138.0 : 120.0;
    final baseCardExtent = (MediaQuery.sizeOf(context).height * .183)
        .clamp(minCardExtent, 150.0)
        .toDouble();
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final actionCardExtent =
        baseCardExtent + (textScale > 1 ? (textScale - 1) * 112 : 0);
    final gutter = (MediaQuery.sizeOf(context).width * .05)
        .clamp(16.0, 32.0)
        .toDouble();
    return PageBody(
      showBrandWave: false,
      horizontalGutter: gutter,
      bottomPadding: 2,
      fillViewport: true,
      scrollable: textScale > 1.2 || MediaQuery.sizeOf(context).height < 650,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Transform.translate(
            offset: const Offset(0, -12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: SvgPicture.asset(
                      'assets/illustrations/brand_shield.svg',
                      width: 34,
                      height: 34,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      l.homeBrand,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l.recentSms,
                    onPressed: onRecentSms,
                    icon: ExcludeSemantics(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedNotification01,
                        color: colors.onSurface,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -18),
            child: Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 240,
                        child: Text.rich(
                          _accentLastWord(
                            l.homeHeading,
                            theme.textTheme.headlineSmall!.copyWith(
                              fontSize: 30,
                              height: 1.1,
                              letterSpacing: -.35,
                              fontWeight: FontWeight.w700,
                            ),
                            UsisaTheme.coral,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: 245,
                        child: Text(
                          l.homeBody,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface,
                            fontSize: 13.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: -(gutter + 7),
                    top: -12,
                    child: HomeLeafArtwork(width: 128, height: 128),
                  ),
                ],
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 11,
            mainAxisExtent: actionCardExtent,
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _HomeActionCard(
                icon: HugeIcons.strokeRoundedMessageSquareMore,
                title: l.scanMessageCard,
                subtitle: l.scanMessageDescription,
                primary: true,
                onTap: onMessage,
              ),
              _HomeActionCard(
                icon: HugeIcons.strokeRoundedLink04,
                title: l.checkLinkCard,
                subtitle: l.checkLinkDescription,
                onTap: onLink,
              ),
              _HomeActionCard(
                icon: HugeIcons.strokeRoundedImage03,
                title: l.scanScreenshotCard,
                subtitle: l.scanScreenshotDescription,
                onTap: onScreenshot,
              ),
              _HomeActionCard(
                icon: HugeIcons.strokeRoundedArtificialIntelligence04,
                title: l.aiScan,
                subtitle: l.aiHomeDescription,
                badge: l.homeAiBadge,
                enabled: aiEnabled,
                onTap: onAi,
              ),
            ],
          ),
          ListenableBuilder(
            listenable: sms,
            builder: (context, _) {
              return GlassSurface(
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onSms,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
                                  child: ExcludeSemantics(
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedAiPhone01,
                                      color: UsisaTheme.coral,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.autoSmsCard,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      l.autoSmsDescription,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (sms.supported)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Switch(
                          value: sms.enabled,
                          onChanged: onSmsToggle,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.primary = false,
    this.enabled = true,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final bool primary;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = primary ? colors.onPrimary : colors.onSurface;
    final surface = GlassSurface(
      color: primary ? const Color(0xFF0B6048) : colors.surface,
      borderRadius: BorderRadius.circular(primary ? 21 : 16),
      showShadow: !primary,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (primary)
            const CustomPaint(painter: _PrimaryActionArtworkPainter()),
          if (!primary)
            const CustomPaint(painter: _SecondaryActionArtworkPainter()),
          InkWell(
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ExcludeSemantics(
                        child: HugeIcon(
                          icon: icon,
                          color: primary ? colors.onPrimary : UsisaTheme.coral,
                          size: 32,
                        ),
                      ),
                      if (badge != null)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 52),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFFFF806A),
                                  Color(0xFFF2452E),
                                  Color(0xFFED321F),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(
                                color: const Color(0xFFFFB0A3)
                                    .withValues(alpha: .7),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: UsisaTheme.coral.withValues(
                                    alpha: .16,
                                  ),
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                badge!,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: primary
                          ? colors.onPrimary
                          : const Color(0xFF6B706C),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    final card = primary
        ? Container(
            padding: const EdgeInsets.all(1),
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
            child: surface,
          )
        : surface;
    return Semantics(
      button: true,
      enabled: enabled,
      label: '$title. $subtitle',
      child: Opacity(opacity: enabled ? 1 : .55, child: card),
    );
  }
}

class _PrimaryActionArtworkPainter extends CustomPainter {
  const _PrimaryActionArtworkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF168363),
            Color(0xFF0D6B51),
            Color(0xFF075440),
            Color(0xFF033E31),
          ],
          stops: [0, .3, .7, 1],
        ).createShader(bounds),
    );

    final width = size.width;
    final height = size.height;
    final upperCurve = Path()
      ..moveTo(0, 0)
      ..lineTo(width, 0)
      ..lineTo(width, height * .25)
      ..cubicTo(
        width * .72,
        height * .22,
        width * .62,
        height * .3,
        width * .43,
        height * .32,
      )
      ..cubicTo(
        width * .24,
        height * .34,
        width * .14,
        height * .4,
        0,
        height * .57,
      )
      ..close();
    canvas.drawPath(
      upperCurve,
      Paint()..color = const Color(0xFF31A078).withValues(alpha: .28),
    );

    final middleCurve = Path()
      ..moveTo(0, height * .57)
      ..cubicTo(
        width * .18,
        height * .4,
        width * .32,
        height * .5,
        width * .51,
        height * .55,
      )
      ..cubicTo(
        width * .72,
        height * .6,
        width * .82,
        height * .32,
        width,
        height * .3,
      )
      ..lineTo(width, height * .5)
      ..cubicTo(
        width * .8,
        height * .52,
        width * .67,
        height * .71,
        width * .47,
        height * .7,
      )
      ..cubicTo(
        width * .26,
        height * .69,
        width * .15,
        height * .61,
        0,
        height * .77,
      )
      ..close();
    canvas.drawPath(
      middleCurve,
      Paint()..color = const Color(0xFF126D51).withValues(alpha: .52),
    );

    final lowerCurve = Path()
      ..moveTo(0, height * .77)
      ..cubicTo(
        width * .2,
        height * .62,
        width * .35,
        height * .78,
        width * .55,
        height * .79,
      )
      ..cubicTo(
        width * .78,
        height * .8,
        width * .87,
        height * .62,
        width,
        height * .55,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(
      lowerCurve,
      Paint()..color = const Color(0xFF013C30).withValues(alpha: .38),
    );
  }

  @override
  bool shouldRepaint(covariant _PrimaryActionArtworkPainter oldDelegate) =>
      false;
}

class _SecondaryActionArtworkPainter extends CustomPainter {
  const _SecondaryActionArtworkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dottedArea = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height * .88)
      ..cubicTo(
        size.width * .18,
        size.height * .88,
        size.width * .36,
        size.height * .84,
        size.width * .51,
        size.height * .77,
      )
      ..cubicTo(
        size.width * .68,
        size.height * .58,
        size.width * .78,
        size.height * .43,
        size.width * .83,
        size.height * .28,
      )
      ..cubicTo(
        size.width * .89,
        size.height * .19,
        size.width * .96,
        size.height * .08,
        size.width,
        0,
      )
      ..close();
    canvas.save();
    canvas.clipPath(dottedArea);
    final lightGreen = Color.lerp(UsisaTheme.forest, UsisaTheme.cream, .35)!;
    for (var row = 0; row < 10; row++) {
      for (var column = 0; column < 13; column++) {
        final point = Offset(
          size.width * (column / 12),
          size.height * (.025 + row * .105),
        );
        final x = point.dx / size.width;
        final y = point.dy / size.height;
        final cornerDistance = (x - .5).abs() + (y - .5).abs();
        final transition = ((cornerDistance - .12) / .68).clamp(0.0, 1.0);
        final green = Color.lerp(lightGreen, UsisaTheme.forest, transition)!;
        canvas.drawCircle(
          point,
          .9 + transition * .35,
          Paint()..color = green.withValues(alpha: .48),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SecondaryActionArtworkPainter oldDelegate) =>
      false;
}

TextSpan _accentLastWord(String value, TextStyle style, Color accent) {
  final boundary = value.lastIndexOf(' ');
  if (boundary < 0) return TextSpan(text: value, style: style);
  return TextSpan(
    style: style,
    children: [
      TextSpan(text: value.substring(0, boundary + 1)),
      TextSpan(
        text: value.substring(boundary + 1),
        style: TextStyle(color: accent),
      ),
    ],
  );
}
