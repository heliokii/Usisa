import 'package:flutter/material.dart';

import '../theme/usisa_theme.dart';
import 'usisa_action_button_painter.dart';

class UsisaActionButton extends StatelessWidget {
  const UsisaActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.danger = false,
    this.borderRadius = 22,
    this.minimumSize = const Size(48, 54),
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  });

  UsisaActionButton.icon({
    super.key,
    required this.onPressed,
    required Widget icon,
    required Widget label,
    this.danger = false,
    this.borderRadius = 22,
    this.minimumSize = const Size(48, 54),
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  }) : child = Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           icon,
           const SizedBox(width: 10),
           Flexible(child: label),
         ],
       );

  final VoidCallback? onPressed;
  final Widget child;
  final bool danger;
  final double borderRadius;
  final Size minimumSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(borderRadius);
    final foreground = UsisaTheme.cream;
    final accent = danger ? UsisaTheme.coral : UsisaTheme.forest;

    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: danger
              ? const Color(0xFFFFA291).withValues(alpha: .8)
              : const Color(0xFF2C9A76).withValues(alpha: .76),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .2),
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: onPressed == null
                  ? const ColoredBox(color: Color(0xFF9DB5A8))
                  : CustomPaint(
                      painter: UsisaActionButtonPainter(danger: danger),
                    ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: radius,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: minimumSize.width,
                    minHeight: minimumSize.height,
                  ),
                  child: Padding(
                    padding: padding,
                    child: Center(
                      heightFactor: 1,
                      child: DefaultTextStyle.merge(
                        style: theme.textTheme.labelLarge!.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                        child: IconTheme.merge(
                          data: IconThemeData(color: foreground),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
