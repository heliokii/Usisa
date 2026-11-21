// PROTOTYPE (throwaway): three UI directions for the Check home and Verdict screens.
// Run: flutter run -d chrome -t lib/prototype_ui/main_prototype.dart   (or -d web-server)
// URL params: ?variant=A|B|C&screen=home|verdict&verdict=safe|careful|danger|unknown&scale=1.0
// The dark bar at the top is prototype chrome, not part of the design.
import 'package:flutter/material.dart';
import 'shared.dart';
import 'variant_a.dart';
import 'variant_b.dart';
import 'variant_c.dart';

void main() => runApp(const ProtoApp());

const variants = ['A', 'B', 'C'];
const variantNames = {'A': VariantA.name, 'B': VariantB.name, 'C': VariantC.name};
const scales = [1.0, 1.3, 1.6];

class ProtoApp extends StatefulWidget {
  const ProtoApp({super.key});
  @override
  State<ProtoApp> createState() => _ProtoAppState();
}

class _ProtoAppState extends State<ProtoApp> {
  final q = Uri.base.queryParameters;
  late String variant = variants.contains(q['variant']) ? q['variant']! : 'A';
  late bool showVerdict = q['screen'] == 'verdict';
  late Verdict verdict = Verdict.values.firstWhere((v) => v.name == q['verdict'], orElse: () => Verdict.danger);
  late double scale = double.tryParse(q['scale'] ?? '') ?? 1.0;

  void cycle(int d) => setState(() => variant = variants[(variants.indexOf(variant) + d) % variants.length]);

  @override
  Widget build(BuildContext context) {
    final props = (showVerdict: showVerdict, verdict: verdict);
    void onCheck() => setState(() => showVerdict = true);
    void onBack() => setState(() => showVerdict = false);
    final page = switch (variant) {
      'B' => VariantB(showVerdict: props.showVerdict, verdict: props.verdict, onCheck: onCheck, onBack: onBack),
      'C' => VariantC(showVerdict: props.showVerdict, verdict: props.verdict, onCheck: onCheck, onBack: onBack),
      _ => VariantA(showVerdict: props.showVerdict, verdict: props.verdict, onCheck: onCheck, onBack: onBack),
    };
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: T.primary, useMaterial3: true),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: Stack(children: [
          child!,
          // Shown in all modes: this entry point is never built for the real app.
          Positioned(left: 0, right: 0, top: 4, child: Center(child: _switcher())),
        ]),
      ),
      home: page,
    );
  }

  Widget _switcher() => MediaQuery.withNoTextScaling(
        child: Material(
          color: const Color(0xEE111111),
          borderRadius: BorderRadius.circular(30),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(onPressed: () => cycle(-1), icon: const Icon(Icons.chevron_left, color: Colors.white)),
              Text('$variant (${variantNames[variant]})', style: const TextStyle(color: Colors.white, fontSize: 12)),
              IconButton(onPressed: () => cycle(1), icon: const Icon(Icons.chevron_right, color: Colors.white)),
              _chip(showVerdict ? 'verdict' : 'home', () => setState(() => showVerdict = !showVerdict)),
              _chip(verdict.name, () => setState(() => verdict = Verdict.values[(verdict.index + 1) % 4])),
              _chip('${scale}x', () => setState(() => scale = scales[(scales.indexOf(scale) + 1) % scales.length])),
            ]),
          ),
        ),
      );

  Widget _chip(String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: ActionChip(label: Text(label, style: const TextStyle(fontSize: 11)), onPressed: onTap, visualDensity: VisualDensity.compact),
      );
}
