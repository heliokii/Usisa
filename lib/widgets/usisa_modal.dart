import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../theme/usisa_theme.dart';
import 'usisa_action_button.dart';

enum UsisaModalVariant { confirm, success, warning, info }

class UsisaModal extends StatelessWidget {
  const UsisaModal({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.dismissLabel,
    required this.variant,
    this.details,
    this.showClose = true,
    this.primaryEnabled = true,
    this.secondaryEnabled = true,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final String? secondaryLabel;
  final String dismissLabel;
  final UsisaModalVariant variant;
  final Widget? details;
  final bool showClose;
  final bool primaryEnabled;
  final bool secondaryEnabled;

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required String primaryLabel,
    required UsisaModalVariant variant,
    String? secondaryLabel,
    Widget? details,
    bool showClose = true,
    bool primaryEnabled = true,
    bool secondaryEnabled = true,
    bool barrierDismissible = true,
  }) {
    final l = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => UsisaModal(
        title: title,
        message: message,
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
        dismissLabel: l.cancel,
        variant: variant,
        details: details,
        showClose: showClose,
        primaryEnabled: primaryEnabled,
        secondaryEnabled: secondaryEnabled,
      ),
    );
  }

  String get _illustration => switch (variant) {
    UsisaModalVariant.confirm => 'assets/illustrations/modal_confirm.svg',
    UsisaModalVariant.success => 'assets/illustrations/modal_success.svg',
    UsisaModalVariant.warning => 'assets/illustrations/modal_warning.svg',
    UsisaModalVariant.info => 'assets/illustrations/modal_info.svg',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final width = math.min(420.0, size.width - 32);
    final danger = variant == UsisaModalVariant.warning;

    return AlertDialog(
      constraints: const BoxConstraints(minWidth: 0, maxWidth: 420),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.none,
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      actionsPadding: EdgeInsets.zero,
      actions: const [],
      content: SizedBox(
        width: width,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: UsisaTheme.forest.withValues(alpha: .18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: .82),
                blurRadius: 2,
                spreadRadius: 1,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: ColoredBox(
              color: theme.colorScheme.surface,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 48,
                    child: ExcludeSemantics(
                      child: SvgPicture.asset(
                        'assets/illustrations/modal_wave.svg',
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: size.height * .86),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: showClose
                                ? IconButton(
                                    tooltip: dismissLabel,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 48,
                                      height: 48,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.close_rounded),
                                  )
                                : const SizedBox(width: 48, height: 48),
                          ),
                        ),
                        Flexible(
                          fit: FlexFit.loose,
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    _illustration,
                                    width: 164,
                                    height: 112,
                                    fit: BoxFit.contain,
                                    excludeFromSemantics: true,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontSize: 24,
                                          height: 1.2,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    message,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      height: 1.4,
                                    ),
                                  ),
                                  if (details != null) ...[
                                    const SizedBox(height: 14),
                                    details!,
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 54),
                          child: _actions(context, theme, danger: danger),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actions(
    BuildContext context,
    ThemeData theme, {
    required bool danger,
  }) {
    final primaryButton = UsisaActionButton(
      onPressed: primaryEnabled ? () => Navigator.of(context).pop(true) : null,
      danger: danger,
      borderRadius: 9999,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        primaryLabel,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
    final secondary = TextButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      foregroundColor: UsisaTheme.forest,
      disabledForegroundColor: theme.colorScheme.onSurface.withValues(
        alpha: .38,
      ),
      shape: const StadiumBorder(),
      side: BorderSide(
        color: UsisaTheme.forest.withValues(alpha: .28),
        width: 1.5,
      ),
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );

    if (secondaryLabel == null) {
      return SizedBox(width: double.infinity, child: primaryButton);
    }
    return Row(
      children: [
        Expanded(
          child: TextButton(
            style: secondary,
            onPressed: secondaryEnabled
                ? () => Navigator.of(context).pop(false)
                : null,
            child: Text(
              secondaryLabel!,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: primaryButton),
      ],
    );
  }
}
