import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/usisa_theme.dart';

class HomeLeafArtwork extends StatelessWidget {
  const HomeLeafArtwork({super.key, this.width = 76, this.height = 85});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/illustrations/home_leaves.png',
    width: width,
    height: height,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    excludeFromSemantics: true,
  );
}

class ScamShieldArtwork extends StatelessWidget {
  const ScamShieldArtwork({super.key, this.size = 170});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset(
      'assets/illustrations/scam_shield.svg',
      width: size,
      height: size,
    ),
  );
}

class AiScanArtwork extends StatelessWidget {
  const AiScanArtwork({super.key, this.size = 150});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset(
      'assets/illustrations/ai_chip.svg',
      width: size,
      height: size,
    ),
  );
}

class LearnSafetyArtwork extends StatelessWidget {
  const LearnSafetyArtwork({super.key, this.height = 130});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: ExcludeSemantics(
      child: SvgPicture.asset(
        'assets/illustrations/learn_safety.svg',
        fit: BoxFit.contain,
      ),
    ),
  );
}

class AiAnalysisArtwork extends StatelessWidget {
  const AiAnalysisArtwork({super.key, this.size = 188});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.square(
          dimension: size,
          child: CircularProgressIndicator(
            color: UsisaTheme.coral,
            backgroundColor: UsisaTheme.forest.withValues(alpha: .18),
            strokeWidth: 5,
          ),
        ),
        SvgPicture.asset(
          'assets/illustrations/ai_bot.svg',
          width: size * .68,
          height: size * .68,
          excludeFromSemantics: true,
        ),
      ],
    ),
  );
}
