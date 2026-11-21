// PROTOTYPE (throwaway): Variant B, "Card list". Peach welcome card overlapping an indigo corner,
// the four features as wide list cards (like the job list reference), SMS protection card underneath.
import 'package:flutter/material.dart';
import 'shared.dart';

class VariantB extends StatelessWidget {
  const VariantB({super.key, required this.showVerdict, required this.verdict, required this.onCheck, required this.onBack});
  static const name = 'Card list';
  final bool showVerdict;
  final Verdict verdict;
  final VoidCallback onCheck;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (showVerdict) return VerdictScreen(verdict: verdict, onBack: onBack);
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const ProtoNav(),
      body: SafeArea(
        bottom: false,
        child: ListView(padding: const EdgeInsets.only(bottom: 28), children: [
          SizedBox(
            height: 250,
            child: Stack(children: [
              Positioned(left: 0, right: 0, top: 0, height: 150, child: Container(decoration: const BoxDecoration(color: T.primary, borderRadius: BorderRadius.only(bottomRight: Radius.circular(40))))),
              Positioned(
                left: 20, right: 56, top: 56, bottom: 0,
                child: Container(
                  decoration: BoxDecoration(color: T.peach, borderRadius: BorderRadius.circular(36)),
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text('Magandang araw,', style: tt.titleMedium?.copyWith(color: T.ink)),
                    Text('Check before\nyou tap!', style: tt.headlineMedium?.copyWith(color: T.ink, fontWeight: FontWeight.w800, height: 1.15)),
                  ]),
                ),
              ),
              dot(70, T.yellow, right: 30, top: 40),
              dot(40, T.primary, right: 92, top: 76),
              dot(20, T.coral, right: 36, top: 120),
            ]),
          ),
          const SizedBox(height: 24),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('What do you want to check?', style: tt.titleLarge?.copyWith(color: T.ink, fontWeight: FontWeight.w800))),
          const SizedBox(height: 12),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Material(
                color: const Color(0xFFF6F6FE),
                borderRadius: BorderRadius.circular(26),
                child: InkWell(
                  borderRadius: BorderRadius.circular(26),
                  onTap: onCheck,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Container(width: 60, height: 60, decoration: BoxDecoration(color: f.tint, borderRadius: BorderRadius.circular(20)), child: Icon(f.icon, color: f.iconColor, size: 30)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f.title, style: tt.titleMedium?.copyWith(color: T.ink, fontWeight: FontWeight.w800)),
                        Text(f.subtitle, style: tt.bodyMedium?.copyWith(color: T.muted)),
                      ])),
                      const Icon(Icons.arrow_forward_ios_rounded, color: T.muted, size: 18),
                      const SizedBox(width: 8),
                    ]),
                  ),
                ),
              ),
            ),
          const Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, 0), child: SmsCard()),
        ]),
      ),
    );
  }
}
