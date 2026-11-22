import 'package:flutter/material.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'kid_book_screens.dart';

class KidsGrowthScreen extends StatelessWidget {
  const KidsGrowthScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final cid = store.selectedChildId;
        final name = store.selectedChild?.name ?? '아이';
        final months = store.monthlyCounts(cid);
        final streak = store.streakWeeks(cid);
        return ListView(padding: const EdgeInsets.only(bottom: 40), children: [
          const PickHeader(),
          const SizedBox(height: 16),
          _Card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('달마다 읽은 책', style: TextStyle(fontFamily: PB.serif, fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('지난 열두 달 동안 서재에 담은 책이에요.', style: TextStyle(fontSize: 13, color: PB.muted)),
              const SizedBox(height: 16),
              SizedBox(height: 150, child: _MonthlyChart(months: months)),
              const Divider(color: PB.line, height: 24),
              Row(children: [
                const Icon(Icons.local_fire_department_outlined, color: PB.primary, size: 20),
                const SizedBox(width: 8),
                Text(streak > 0 ? '$streak주째 이어 읽고 있어요' : '이번 주에 한 권 읽으면 연속 기록이 시작돼요', style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          _Card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$name의 머릿속', style: const TextStyle(fontFamily: PB.serif, fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('책으로 만난 마음이 쌓일수록 머릿속 그 자리가 선명해져요.\n영역을 누르면 안에 담긴 마음을 얼마나 채웠는지 볼 수 있어요.',
                  style: TextStyle(fontSize: 13, color: PB.muted, height: 1.6)),
              const SizedBox(height: 12),
              _MindMap(childId: cid),
              const Align(
                alignment: Alignment.centerRight,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.touch_app_outlined, size: 16, color: PB.primary),
                  SizedBox(width: 4),
                  Text('영역을 눌러 보세요', style: TextStyle(fontSize: 12, color: PB.primary, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
        ]);
      },
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(28, 8, 28, 16),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: PB.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: child,
      );
}

class _MonthlyChart extends StatelessWidget {
  final List<(DateTime, int)> months;
  const _MonthlyChart({required this.months});
  @override
  Widget build(BuildContext context) {
    final maxV = months.map((e) => e.$2).fold<int>(1, (a, b) => b > a ? b : a);
    final nonZero = months.where((e) => e.$2 > 0).toList();
    final avg = nonZero.isEmpty ? 0.0 : nonZero.map((e) => e.$2).reduce((a, b) => a + b) / nonZero.length;
    return LayoutBuilder(builder: (context, c) {
      const labelH = 22.0, topPad = 18.0;
      final barArea = c.maxHeight - labelH - topPad;
      final avgY = topPad + barArea * (1 - avg / maxV);
      return Stack(children: [
        if (avg > 0) ...[
          Positioned(left: 0, right: 0, top: avgY, child: CustomPaint(size: const Size(double.infinity, 1), painter: _Dash())),
          Positioned(left: 0, top: avgY - 18, child: Text('평균 ${avg.toStringAsFixed(1)}권', style: const TextStyle(fontSize: 11, color: PB.primary, fontWeight: FontWeight.w700))),
        ],
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < months.length; i++)
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (months[i].$2 > 0) Text('${months[i].$2}', style: const TextStyle(fontSize: 11, color: PB.muted)),
                const SizedBox(height: 3),
                Container(
                  width: 16,
                  height: months[i].$2 == 0 ? 2 : barArea * months[i].$2 / maxV - 14,
                  decoration: BoxDecoration(
                    color: months[i].$2 == 0 ? PB.line : (i == months.length - 1 ? PB.primary : const Color(0xFFD9A7AC)),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                ),
                SizedBox(
                  height: labelH,
                  child: Center(
                    child: Text('${months[i].$1.month}월',
                        style: TextStyle(fontSize: 10, color: i == months.length - 1 ? PB.primary : PB.muted, fontWeight: i == months.length - 1 ? FontWeight.w800 : FontWeight.w400)),
                  ),
                ),
              ]),
            ),
        ]),
      ]);
    });
  }
}

class _Dash extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = PB.primary.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, 0), Offset(x + 3, 0), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ---------- 머릿속 지도 ----------
class _Region {
  final String name;
  final Color color;
  final List<Rect> ovals; // 320 x 240 좌표계
  final Offset label;
  const _Region(this.name, this.color, this.ovals, this.label);

  Path path(double s) {
    Path? p;
    for (final o in ovals) {
      final r = Path()..addOval(Rect.fromLTRB(o.left * s, o.top * s, o.right * s, o.bottom * s));
      p = p == null ? r : Path.combine(PathOperation.union, p, r);
    }
    return p!;
  }
}

Rect _o(double cx, double cy, double rx, double ry) => Rect.fromLTRB(cx - rx, cy - ry, cx + rx, cy + ry);

final _regions = [
  _Region('생각과 세상', const Color(0xFFF4BE8C), [_o(82, 128, 56, 66), _o(70, 100, 40, 40), _o(105, 165, 40, 35)], const Offset(62, 112)),
  _Region('감정', const Color(0xFFB9C2EA), [_o(252, 120, 50, 62), _o(240, 90, 36, 36)], const Offset(258, 118)),
  _Region('나', const Color(0xFFCADDB0), [_o(165, 52, 66, 34), _o(125, 62, 38, 28), _o(205, 62, 38, 28)], const Offset(165, 46)),
  _Region('관계', const Color(0xFFF5D894), [_o(180, 194, 78, 32), _o(140, 198, 40, 24)], const Offset(185, 200)),
  _Region('자라는 마음', const Color(0xFFF1AFB6), [_o(165, 132, 60, 46), _o(185, 150, 40, 30)], const Offset(165, 132)),
];

class _MindMap extends StatelessWidget {
  final String? childId;
  const _MindMap({required this.childId});
  @override
  Widget build(BuildContext context) {
    final counts = store.areaCounts(childId);
    final maxC = counts.values.fold<int>(1, (a, b) => b > a ? b : a);
    return LayoutBuilder(builder: (context, c) {
      final s = c.maxWidth / 320;
      return GestureDetector(
        onTapUp: (d) {
          for (final r in _regions.reversed) {
            if (r.path(s).contains(d.localPosition)) {
              _showArea(context, r.name, counts[r.name] ?? 0);
              return;
            }
          }
        },
        child: CustomPaint(size: Size(c.maxWidth, 240 * s), painter: _MindPainter(s, counts, maxC)),
      );
    });
  }

  void _showArea(BuildContext context, String area, int count) {
    final books = store.kidBooks.where((k) => k.childId == childId && !k.toRead && k.areas.contains(area)).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: PB.card,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(area, style: const TextStyle(fontFamily: PB.serif, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('책 ${books.length}권, 모두 $count번 만났어요.', style: const TextStyle(color: PB.muted)),
            const SizedBox(height: 14),
            if (books.isEmpty) const Text('이 마음을 다룬 책을 아직 읽지 않았어요.', style: TextStyle(color: PB.muted)),
            SizedBox(
              height: books.isEmpty ? 0 : 120,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final k in books)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => KidBookDetailScreen(id: k.id)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: BookCover(title: k.title, url: k.coverUrl, path: k.coverPath, seed: k.colorSeed, width: 80, height: 110, radius: 6),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MindPainter extends CustomPainter {
  final double s;
  final Map<String, int> counts;
  final int maxC;
  _MindPainter(this.s, this.counts, this.maxC);

  @override
  void paint(Canvas canvas, Size size) {
    // 배경 번짐
    canvas.drawOval(
      Rect.fromCenter(center: Offset(160 * s, 125 * s), width: 330 * s, height: 250 * s),
      Paint()
        ..color = const Color(0xFFF1E7DC)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    for (final r in _regions) {
      final v = (counts[r.name] ?? 0) / maxC;
      final path = r.path(s);
      canvas.drawPath(path, Paint()..color = Color.lerp(const Color(0xFFF4EFEA), r.color, 0.25 + 0.75 * v)!);
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = Color.lerp(r.color, Colors.black, 0.18)!.withValues(alpha: 0.7));
    }
    for (final r in _regions) {
      final tp = TextPainter(
        text: TextSpan(text: r.name, style: TextStyle(fontSize: 12.5 * s.clamp(0.8, 1.3), color: PB.ink, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(r.label.dx * s - tp.width / 2, r.label.dy * s - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _MindPainter old) => true;
}
