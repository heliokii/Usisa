import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../l10n/app_localizations.dart';

class UsisaLoadingIndicator extends StatelessWidget {
  const UsisaLoadingIndicator({
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? AppLocalizations.of(context).loading,
      child: ExcludeSemantics(
        child: TickerMode(
          enabled: !MediaQuery.disableAnimationsOf(context),
          child: SpinKitFadingCircle(
            size: size,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
