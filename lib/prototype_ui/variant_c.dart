// PROTOTYPE (throwaway): Variant C, "Bold hero". A big geometric indigo hero (like the onboarding references),
// the four features as tall pill tiles in a row, recent checks like a transaction list, SMS protection card last.
import 'package:flutter/material.dart';
import 'shared.dart';

class VariantC extends StatelessWidget {
  const VariantC({super.key, required this.showVerdict, required this.verdict, required this.onCheck, required this.onBack});
  static const name = 'Bold hero';
  final bool showVerdict;
  final Verdict verdict;
  final VoidCallback onCheck;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (showVerdict) return VerdictScreen(verdict: verdict, onBack: onBack);
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: T.bg,
      bottomNavigationBar: const ProtoNav(),
      body: SafeArea(
        bottom: false,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 52, 16, 28), children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Container(
              height: 190,
              color: T.primary,
              child: Stack(children: [
                Positioned(right: -30, top: -30, child: Container(width: 160, height: 160, decoration: const BoxDecoration(color: Color(0xFFFF8A4C), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(160))))),
                dot(70, T.yellow, right: 20, bottom: -20),
                dot(36, Colors.white, right: 110, top: 36),
                dot(26, T.coral, left: 150, bottom: 20),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text('Magandang araw!', style: tt.titleMedium?.copyWith(color: Colors.white.withValues(alpha: .9))),
                    Text('Stay safe from\nscam texts', style: tt.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.15)),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          Text('Check something', style: tt.titleLarge?.copyWith(color: T.ink, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(children: [
            for (var i = 0; i < features.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _pill(context, features[i], i == 0)),
            ],
          ]),
          const SizedBox(height: 24),
          Text('Recent checks', style: tt.titleLarge?.copyWith(color: T.ink, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final v in [Verdict.danger, Verdict.safe])
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: looks[v]!.tint, borderRadius: BorderRadius.circular(16)), child: Icon(looks[v]!.icon, color: looks[v]!.fg)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(samples[v]!.sender, style: tt.titleSmall?.copyWith(color: T.ink, fontWeight: FontWeight.w700)),
                  Text(samples[v]!.message, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: T.muted)),
                ])),
                const SizedBox(width: 8),
                Text(looks[v]!.word, style: tt.labelLarge?.copyWith(color: looks[v]!.fg, fontWeight: FontWeight.w800)),
              ]),
            ),
          const SizedBox(height: 14),
          const SmsCard(),
        ]),
      ),
    );
  }

  Widget _pill(BuildContext context, Feature f, bool lead) => Material(
        color: lead ? T.primary : Colors.white,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: onCheck,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            child: Column(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: lead ? Colors.white : f.tint, shape: BoxShape.circle), child: Icon(f.icon, color: f.iconColor)),
              const SizedBox(height: 10),
              FittedBox(fit: BoxFit.scaleDown, child: Text(const {'Scan a message': 'Message', 'Check a link': 'Link', 'Scan a screenshot': 'Screenshot'}[f.title] ?? f.title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: lead ? Colors.white : T.ink, fontWeight: FontWeight.w700))),
            ]),
          ),
        ),
      );
}
