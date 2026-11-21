// PROTOTYPE (throwaway): shared tokens, sample data and the verdict screen for the UI direction prototype.
// Style follows the owner's references: indigo blocks, warm pastel accents, big rounded cards, geometric circles.
import 'package:flutter/material.dart';

class T {
  static const primary = Color(0xFF4A44C9); // white on it 7.1:1
  static const bg = Color(0xFFEEF0FF);
  static const ink = Color(0xFF1F1D4D);
  static const muted = Color(0xFF5B5A7A);
  static const yellow = Color(0xFFFFD66B);
  static const peach = Color(0xFFFDE7CF);
  static const coral = Color(0xFFFF8A8A);
  static const lilac = Color(0xFFDCDDFB);
  static const mint = Color(0xFFD5F2EA);
}

enum Verdict { safe, careful, danger, unknown }

class VerdictLook {
  const VerdictLook(this.word, this.icon, this.fg, this.tint, this.action);
  final String word;
  final IconData icon;
  final Color fg;
  final Color tint;
  final String action;
}

const looks = {
  Verdict.safe: VerdictLook('Looks safe', Icons.check_circle_rounded, Color(0xFF166534), Color(0xFFE8F6EC),
      'Nothing suspicious found. Still, never share your OTP or PIN with anyone.'),
  Verdict.careful: VerdictLook('Be careful', Icons.error_rounded, Color(0xFF92400E), Color(0xFFFDF1DC),
      "Don't tap links or send money until you're sure who sent this."),
  Verdict.danger: VerdictLook('Dangerous', Icons.dangerous_rounded, Color(0xFFB91C1C), Color(0xFFFDE8E8),
      "Don't tap the link, don't reply, and don't send money."),
  Verdict.unknown: VerdictLook("Couldn't check", Icons.help_rounded, Color(0xFF334155), Color(0xFFECEFF3),
      "We couldn't check where this link goes. Don't open it or enter any details until you're sure who sent it."),
};

class Sample {
  const Sample(this.sender, this.message, this.reasons, {this.realDestination, this.offline = false});
  final String sender;
  final String message;
  final List<String> reasons;
  final String? realDestination;
  final bool offline;
}

const samples = {
  Verdict.safe: Sample('Anak (Joy)', 'Hi Ma, nakauwi na ako. Pa-send ng pera para sa load ha, salamat!',
      ['It reads like a normal family message', 'No links and no request for codes or passwords']),
  Verdict.careful: Sample('+63 917 555 0142', 'FREE 888 bonus credits! Join LuckyPanalo casino today, instant cash-out. Reply YES',
      ['This is an unsolicited gambling ad', "These often lead to sites that take deposits and don't pay out"]),
  Verdict.danger: Sample('GCASH-INFO', 'GCash: Your account is LOCKED. Verify within 24 hrs at bit.ly/gc-verfy or lose your balance.',
      ['The link goes to a fake GCash website', 'It rushes you with a deadline', 'GCash never asks you to verify through a link'],
      realDestination: 'gcash-verify-ph.xyz'),
  Verdict.unknown: Sample('+63 998 120 4471', 'Hello po, your parcel is on hold. Update your address here: tinyurl.com/ph-parcel',
      ["The link is shortened, so we couldn't see where it goes"], offline: true),
};

/// The four ways to start a Check, as on today's home.
class Feature {
  const Feature(this.title, this.subtitle, this.icon, this.tint, this.iconColor);
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final Color iconColor;
}

const features = [
  Feature('Scan a message', 'Paste a text you got', Icons.sms_rounded, T.peach, Color(0xFFB45309)),
  Feature('Check a link', 'See where it really goes', Icons.link_rounded, T.lilac, T.primary),
  Feature('Scan a screenshot', 'Pick a photo of the text', Icons.image_rounded, T.mint, Color(0xFF0F766E)),
  Feature('AI scan', 'Ask AI to look closely', Icons.auto_awesome_rounded, Color(0xFFFFE1E1), Color(0xFFBE123C)),
];

/// Decorative circles from the references. Purely visual.
Widget dot(double size, Color color, {double? top, double? left, double? right, double? bottom}) => Positioned(
      top: top, left: left, right: right, bottom: bottom,
      child: IgnorePointer(child: Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle))),
    );

class ProtoNav extends StatelessWidget {
  const ProtoNav({super.key});
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE3E4F7)))),
        child: NavigationBar(
          selectedIndex: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorColor: T.lilac,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: T.primary), label: 'Check'),
            NavigationDestination(icon: Icon(Icons.history_rounded), label: 'History'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Learn'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          ],
        ),
      );
}

class SmsCard extends StatefulWidget {
  const SmsCard({super.key});
  @override
  State<SmsCard> createState() => _SmsCardState();
}

class _SmsCardState extends State<SmsCard> {
  bool on = true;
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: T.primary,
        padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
        child: Stack(clipBehavior: Clip.none, children: [
          // Decoration kept on the left/bottom so it never sits behind the switch.
          dot(70, const Color(0xFF6C66E0), left: -40, bottom: -46),
          dot(16, T.yellow, left: 150, top: -10),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Auto SMS protection', style: tt.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(on ? '12 texts checked today' : 'Texts are not being checked', style: tt.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: .9))),
            ])),
            Switch(
              value: on,
              onChanged: (v) => setState(() => on = v),
              activeThumbColor: T.primary,
              activeTrackColor: T.yellow,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: .25),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// One verdict screen, in the reference style: coloured header block with circles, white sheet, action pills.
class VerdictScreen extends StatelessWidget {
  const VerdictScreen({super.key, required this.verdict, required this.onBack});
  final Verdict verdict;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final l = looks[verdict]!;
    final s = samples[verdict]!;
    return Scaffold(
      backgroundColor: l.fg,
      bottomNavigationBar: const ProtoNav(),
      body: SafeArea(
        bottom: false,
        child: ListView(padding: EdgeInsets.zero, children: [
          SizedBox(
            height: 250,
            child: Stack(clipBehavior: Clip.hardEdge, children: [
              dot(150, Colors.white.withValues(alpha: .12), right: -40, top: -50),
              dot(60, T.yellow.withValues(alpha: .9), right: 90, top: 30),
              dot(22, T.coral, right: 40, top: 120),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), tooltip: 'Back'),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(l.icon, color: Colors.white, size: 44),
                      const SizedBox(height: 10),
                      Text(l.word, style: tt.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                      if (s.offline) Text('Checked on your phone', style: tt.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: .85))),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
          Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: l.tint, borderRadius: BorderRadius.circular(20)),
                child: Text(l.action, style: tt.titleMedium?.copyWith(color: T.ink, fontWeight: FontWeight.w600, height: 1.35)),
              ),
              const SizedBox(height: 22),
              Text('Why', style: tt.titleLarge?.copyWith(color: T.ink, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final r in s.reasons)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(margin: const EdgeInsets.only(top: 7), width: 10, height: 10, decoration: BoxDecoration(color: l.fg, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(r, style: tt.bodyLarge?.copyWith(color: T.ink))),
                  ]),
                ),
              if (s.realDestination != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: T.bg, borderRadius: BorderRadius.circular(18)),
                  child: Text('Really goes to ${s.realDestination}', style: tt.bodyLarge?.copyWith(color: l.fg, fontWeight: FontWeight.w700)),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(onPressed: () {}, style: FilledButton.styleFrom(backgroundColor: T.primary, minimumSize: const Size.fromHeight(56), shape: const StadiumBorder()), child: const Text('Send to family', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: T.ink, minimumSize: const Size.fromHeight(56), shape: const StadiumBorder(), side: const BorderSide(color: Color(0xFFD5D6F2), width: 1.5)), child: const Text('Read aloud', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
              const SizedBox(height: 24),
              Text('You checked', style: tt.titleSmall?.copyWith(color: T.muted)),
              const SizedBox(height: 4),
              Text('${s.sender}: "${s.message}"', style: tt.bodyMedium?.copyWith(color: T.muted)),
            ]),
          ),
        ]),
      ),
    );
  }
}
