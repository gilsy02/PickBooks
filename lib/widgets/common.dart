import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../store.dart';
import '../theme.dart';

/// 픽북스 로고: 책갈피 모양의 P
class PickLogo extends StatelessWidget {
  final double size;
  const PickLogo({super.key, this.size = 34});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size * 0.86, size), painter: _LogoPainter());
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = PB.primary;
    final w = s.width, h = s.height;
    // 기둥(책갈피)
    final stem = Path()
      ..moveTo(0, h * 0.08)
      ..lineTo(w * 0.36, 0)
      ..lineTo(w * 0.36, h)
      ..lineTo(w * 0.18, h * 0.86)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(stem, p);
    // 볼
    final bowl = Path()
      ..moveTo(w * 0.42, h * 0.02)
      ..lineTo(w * 0.62, h * 0.02)
      ..quadraticBezierTo(w * 1.0, h * 0.04, w * 1.0, h * 0.30)
      ..quadraticBezierTo(w * 1.0, h * 0.58, w * 0.62, h * 0.60)
      ..lineTo(w * 0.42, h * 0.60)
      ..lineTo(w * 0.42, h * 0.46)
      ..lineTo(w * 0.58, h * 0.46)
      ..quadraticBezierTo(w * 0.78, h * 0.44, w * 0.78, h * 0.30)
      ..quadraticBezierTo(w * 0.78, h * 0.16, w * 0.58, h * 0.15)
      ..lineTo(w * 0.42, h * 0.15)
      ..close();
    canvas.drawPath(bowl, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// 상단: 로고 + 픽북스/키즈 전환 + 오른쪽 버튼들
class PickHeader extends StatelessWidget {
  final List<Widget> actions;
  const PickHeader({super.key, this.actions = const []});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
      child: SizedBox(
        height: 48,
        child: Stack(alignment: Alignment.center, children: [
          const Align(alignment: Alignment.centerLeft, child: PickLogo()),
          const ModeToggle(),
          Align(alignment: Alignment.centerRight, child: Row(mainAxisSize: MainAxisSize.min, children: actions)),
        ]),
      ),
    );
  }
}

class ModeToggle extends StatelessWidget {
  const ModeToggle({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        Widget seg(String label, bool active, VoidCallback onTap, {bool kids = false}) => GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: kids ? 5 : 8),
                decoration: BoxDecoration(color: active ? PB.primary : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                child: Text(label,
                    style: TextStyle(
                        fontFamily: kids ? PB.brush : null,
                        fontSize: kids ? 23 : 14,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : PB.ink)),
              ),
            );
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              color: PB.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: PB.line),
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            seg('픽북스', !store.kidsMode, () => store.setKidsMode(false)),
            seg('키즈', store.kidsMode, () => store.setKidsMode(true), kids: true),
          ]),
        );
      },
    );
  }
}

class Motto extends StatelessWidget {
  const Motto({super.key});
  @override
  Widget build(BuildContext context) => const Text('“독서의 힘은,\n재미에서 시작됩니다.”',
      style: TextStyle(fontFamily: PB.serif, fontSize: 13.5, height: 1.6, color: PB.muted));
}

/// "— 제목" 형태 섹션 제목
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 18, height: 2.5, color: PB.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontFamily: PB.serif, fontSize: 18, fontWeight: FontWeight.w700))),
        if (trailing != null) trailing!,
      ]);
}

/// 표지. 이미지가 없으면 제목으로 표지를 그린다.
class BookCover extends StatelessWidget {
  final String title;
  final String author;
  final String? url;
  final String? path;
  final int seed;
  final double width;
  final double height;
  final double radius;
  const BookCover(
      {super.key,
      required this.title,
      this.author = '',
      this.url,
      this.path,
      required this.seed,
      required this.width,
      required this.height,
      this.radius = 3});

  static const _palettes = [
    [Color(0xFF2F4858), Color(0xFFF2E8CF)],
    [Color(0xFF6B2D3A), Color(0xFFF6E7D8)],
    [Color(0xFF3C5A3A), Color(0xFFEFE9D9)],
    [Color(0xFFE8DCC8), Color(0xFF3B3028)],
    [Color(0xFF1F2A44), Color(0xFFE7C873)],
    [Color(0xFFD9822B), Color(0xFF2B2420)],
    [Color(0xFFF4F1EA), Color(0xFF8E1B2C)],
    [Color(0xFF7A9CB8), Color(0xFFFFFFFF)],
    [Color(0xFFB85C5C), Color(0xFFFFF4E8)],
    [Color(0xFF4A3F6B), Color(0xFFF1E6FF)],
  ];

  @override
  Widget build(BuildContext context) {
    Widget? img;
    if (path != null && !kIsWeb) {
      img = Image.file(File(path!), fit: BoxFit.cover, width: width, height: height, errorBuilder: (_, __, ___) => _fallback());
    } else if (url != null && url!.isNotEmpty) {
      img = Image.network(url!, fit: BoxFit.cover, width: width, height: height, errorBuilder: (_, __, ___) => _fallback());
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), boxShadow: const [
        BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(2, 3)),
      ]),
      clipBehavior: Clip.antiAlias,
      child: img ?? _fallback(),
    );
  }

  Widget _fallback() {
    final pal = _palettes[seed.abs() % _palettes.length];
    final small = width < 70;
    return Container(
      color: pal[0],
      foregroundDecoration: const BoxDecoration(),
      padding: EdgeInsets.all(small ? 5 : 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 2, width: width * 0.3, color: pal[1].withValues(alpha: 0.7)),
        SizedBox(height: small ? 6 : 10),
        Text(title,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: PB.serif, fontWeight: FontWeight.w700, fontSize: small ? 10 : (width / 8).clamp(11, 20), color: pal[1], height: 1.25, decoration: TextDecoration.none)),
        const Spacer(),
        if (author.isNotEmpty)
          Text(author, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: small ? 7 : 10, color: pal[1].withValues(alpha: 0.8))),
      ]),
    );
  }
}

class PrimaryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const PrimaryPill({super.key, required this.label, this.icon = Icons.add, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
                color: const Color(0xFF3A1F22),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 4))]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                  color: PB.primary, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFB84A58), width: 1)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ]),
            ),
          ),
        ),
      );
}

/// 두 칸 세그먼트(전면 책장/일반 책장 등)
class Segmented extends StatelessWidget {
  final List<(IconData, String)> items;
  final int index;
  final ValueChanged<int> onChanged;
  const Segmented({super.key, required this.items, required this.index, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: PB.card,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: PB.line),
            boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 6, offset: Offset(0, 2))]),
        child: Row(children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(color: i == index ? PB.primary : Colors.transparent, borderRadius: BorderRadius.circular(22)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(items[i].$1, size: 17, color: i == index ? Colors.white : PB.ink),
                    const SizedBox(width: 8),
                    Text(items[i].$2, style: TextStyle(fontWeight: FontWeight.w700, color: i == index ? Colors.white : PB.ink)),
                  ]),
                ),
              ),
            ),
        ]),
      );
}

String fmtDate(DateTime d) => '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

Future<String?> askText(BuildContext context, String title, {String initial = '', String hint = ''}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: PB.card,
      title: Text(title, style: const TextStyle(fontFamily: PB.serif, fontWeight: FontWeight.w700)),
      content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: hint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('확인')),
      ],
    ),
  );
}
