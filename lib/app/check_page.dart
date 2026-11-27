import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'motion.dart';
import 'theme.dart';

/// "usisa." in heavy type with a yellow dot.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.color = UsisaColors.primary, this.size = 24});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Usisa',
    excludeSemantics: true,
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'usisa',
            style: TextStyle(color: color),
          ),
          const TextSpan(
            text: '.',
            style: TextStyle(color: UsisaColors.orange),
          ),
        ],
      ),
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1),
      textScaler: TextScaler.noScaling,
    ),
  );
}

/// Small spaced capitals, like "A LITTLE CHECK GOES A LONG WAY".
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = UsisaColors.inkMuted});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: color, fontWeight: FontWeight.w700, letterSpacing: 1.4),
  );
}

/// The full-width pill button at the bottom of a check page; lilac while disabled.
class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({super.key, required this.label, required this.onPressed, this.busy = false});
  final String label;
  final VoidCallback? onPressed;

  /// Shows bouncing dots and "Checking…" while the Check runs.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PressScale(
      child: FilledButton(
        onPressed: busy || onPressed == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed!();
              },
        style: FilledButton.styleFrom(
          backgroundColor: UsisaColors.primary,
          // Busy keeps the strong colour so it reads as "working", not "unavailable".
          disabledBackgroundColor: busy ? UsisaColors.primary : const Color(0xFFAFAED6),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(58),
          shape: const StadiumBorder(),
          textStyle: Theme.of(context).textTheme.titleMedium,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: busy
              ? Semantics(
                  liveRegion: true,
                  label: l.checkingLabel,
                  child: Row(
                    key: const ValueKey('busy'),
                    mainAxisSize: MainAxisSize.min,
                    children: [Text(l.checkingLabel), const SizedBox(width: 10), const BusyDots()],
                  ),
                )
              : Text(label, key: const ValueKey('idle')),
        ),
      ),
    );
  }
}

/// The top bar of a full page: wordmark, then the tagline in spaced capitals, over a hairline.
class PageBar extends StatelessWidget {
  const PageBar({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: UsisaColors.hairline)),
    ),
    child: Row(
      children: [
        const Wordmark(),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppLocalizations.of(context).pageTagline.toUpperCase(),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: UsisaColors.inkMuted, letterSpacing: 1.4),
          ),
        ),
      ],
    ),
  );
}

/// An underlined "Back to …" text link that pops the page.
class BackLink extends StatelessWidget {
  const BackLink(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton(
      onPressed: () => Navigator.of(context).maybePop(),
      style: TextButton.styleFrom(
        foregroundColor: UsisaColors.ink,
        padding: EdgeInsets.zero,
        minimumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: UsisaColors.lilac,
          decorationThickness: 2,
        ),
      ),
    ),
  );
}

/// The layout every check page shares: wordmark bar, "Back to check", eyebrow, big title and intro,
/// the page's own content, then a centred footnote and the main button pinned at the bottom.
class CheckPage extends StatelessWidget {
  const CheckPage({
    super.key,
    required this.title,
    required this.intro,
    required this.children,
    this.footnote,
    this.button,
    this.titleColor = UsisaColors.ink,
    this.showEyebrow = true,
  });
  final String title;
  final String intro;
  final List<Widget> children;
  final String? footnote;
  final Widget? button;
  final Color titleColor;
  final bool showEyebrow;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    // Dark status-bar icons over the lavender page.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: UsisaColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageBar(),
              Expanded(
                // Short pages: build everything at once so large text can scroll to any field.
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BackLink(l.backToCheck),
                      const SizedBox(height: 16),
                      if (showEyebrow) ...[Eyebrow(l.pageEyebrow), const SizedBox(height: 10)],
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: tt.headlineLarge?.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(intro, style: tt.bodyLarge?.copyWith(color: UsisaColors.inkMuted)),
                      const SizedBox(height: 24),
                      ...children,
                    ],
                  ),
                ),
              ),
              if (footnote != null || button != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (footnote != null) ...[
                        Text(
                          footnote!,
                          textAlign: TextAlign.center,
                          style: tt.bodySmall?.copyWith(color: UsisaColors.inkMuted, height: 1.5),
                        ),
                        const SizedBox(height: 12),
                      ],
                      ?button,
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A white rounded box with a hairline border, used for the text field and the review card.
BoxDecoration fieldDecoration({bool focused = false}) => BoxDecoration(
  color: UsisaColors.surface,
  borderRadius: BorderRadius.circular(24),
  border: Border.all(color: focused ? UsisaColors.primary : UsisaColors.hairline, width: focused ? 2 : 1.5),
);
