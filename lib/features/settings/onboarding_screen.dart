import 'package:flutter/material.dart';

import '../../features/home/feature_artwork.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/usisa_theme.dart';
import '../../widgets/page_body.dart';
import 'settings_store.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.settings,
    required this.onStart,
  });
  final SettingsStore settings;
  final VoidCallback onStart;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  bool _busy = false;
  int _page = 0;

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.settings.update(onboarded: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).saveFailed)),
        );
      }
    }
    if (mounted) widget.onStart();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 55,
            child: BrandWave(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (value) => setState(() => _page = value),
                      children: [
                        _WelcomePage(
                          artwork: const ScamShieldArtwork(size: 220),
                          title: 'Usisa',
                          subtitle: l.welcomeBody,
                        ),
                        _WelcomePage(
                          artwork: const AiScanArtwork(size: 196),
                          title: l.onboardingSecondTitle,
                          subtitle: l.onboardingSecondBody,
                        ),
                        _WelcomePage(
                          artwork: Icon(
                            Icons.lock_outline_rounded,
                            size: 122,
                            color: theme.colorScheme.primary,
                          ),
                          title: l.onboardingThirdTitle,
                          subtitle: l.welcomePrivacy,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Semantics(
                        button: true,
                        selected: _page == index,
                        label: 'Onboarding ${index + 1} of 3',
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _pages.animateToPage(
                              index,
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                            ),
                            child: AnimatedContainer(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 160),
                              width: _page == index ? 10 : 7,
                              height: _page == index ? 10 : 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _page == index
                                    ? UsisaTheme.coral
                                    : UsisaTheme.forest.withValues(alpha: .3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: UsisaTheme.contrastCoral,
                        foregroundColor: UsisaTheme.cream,
                      ),
                      onPressed: _busy ? null : _start,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(l.getStarted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.artwork,
    required this.title,
    required this.subtitle,
  });
  final Widget artwork;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final artworkHeight = textScale > 1.5 ? 150.0 : 240.0;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  height: artworkHeight,
                  child: Center(child: artwork),
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 14),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
