import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 아이 방 책장 배너. 외부 그림 대신 코드로 직접 그린다(저작권 문제 없음).
class KidsRoomBanner extends StatelessWidget {
  const KidsRoomBanner({super.key});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _RoomPainter(), size: Size.infinite);
}

class _RoomPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // 벽
    c.drawRect(Offset.zero & s,
        Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFBEBD6), Color(0xFFF2D3AE)]).createShader(Offset.zero & s));
    // 창문 빛
    final light = Paint()..color = const Color(0x33FFFFFF);
    for (var i = 0; i < 3; i++) {
      final p = Path()
        ..moveTo(w * (0.30 + i * 0.12), 0)
        ..lineTo(w * (0.38 + i * 0.12), 0)
        ..lineTo(w * (0.62 + i * 0.12), h)
        ..lineTo(w * (0.54 + i * 0.12), h)
        ..close();
      c.drawPath(p, light);
    }
    // 책장 몸통
    final shelfL = w * 0.28, shelfR = w * 0.86, top = h * 0.12, bottom = h * 0.95;
    final wood = Paint()..color = const Color(0xFFD9A86C);
    final woodDark = Paint()..color = const Color(0xFFB98547);
    c.drawRRect(RRect.fromLTRBR(shelfL, top, shelfR, bottom, const Radius.circular(4)), woodDark);
    c.drawRect(Rect.fromLTRB(shelfL + 8, top + 8, shelfR - 8, bottom), Paint()..color = const Color(0xFFE8C08F));
    final midY = top + (bottom - top) * 0.48;
    for (final y in [midY, bottom - 6]) {
      c.drawRect(Rect.fromLTRB(shelfL + 4, y - 7, shelfR - 4, y + 3), wood);
    }
    // 책들
    const cols = [Color(0xFFE59A8C), Color(0xFF9FC3A6), Color(0xFFF2CF7A), Color(0xFF8FB2D9), Color(0xFFC9A0D6), Color(0xFFF4F1EA)];
    final rnd = math.Random(7);
    var x = shelfR - 16;
    for (var i = 0; i < 7; i++) {
      final bw = 9.0 + rnd.nextInt(6), bh = (midY - top) * (0.55 + rnd.nextDouble() * 0.3);
      c.drawRRect(RRect.fromLTRBR(x - bw, midY - 7 - bh, x, midY - 7, const Radius.circular(2)), Paint()..color = cols[i % cols.length]);
      x -= bw + 2;
    }
    x = shelfL + 16;
    for (var i = 0; i < 4; i++) {
      final bw = 10.0 + rnd.nextInt(5), bh = (bottom - midY) * (0.5 + rnd.nextDouble() * 0.3);
      c.drawRRect(RRect.fromLTRBR(x, bottom - 13 - bh, x + bw, bottom - 13, const Radius.circular(2)), Paint()..color = cols[(i + 2) % cols.length]);
      x += bw + 2;
    }
    // 토끼 인형 (위칸 왼쪽)
    final bunny = Paint()..color = const Color(0xFFFFFBF6);
    final bx = shelfL + 34, by = midY - 7;
    c.drawOval(Rect.fromCenter(center: Offset(bx, by - 12), width: 22, height: 24), bunny);
    c.drawOval(Rect.fromCenter(center: Offset(bx, by - 30), width: 16, height: 16), bunny);
    c.drawOval(Rect.fromCenter(center: Offset(bx - 4, by - 44), width: 5, height: 16), bunny);
    c.drawOval(Rect.fromCenter(center: Offset(bx + 4, by - 44), width: 5, height: 16), bunny);
    // 화분과 덩굴 (왼쪽)
    final leaf = Paint()..color = const Color(0xFF8DB27A);
    c.drawRRect(RRect.fromLTRBR(w * 0.06, h * 0.70, w * 0.16, h * 0.95, const Radius.circular(4)), Paint()..color = const Color(0xFFD98F6B));
    for (var i = 0; i < 9; i++) {
      final cx = w * 0.11 + math.sin(i * 1.3) * w * 0.05, cy = h * 0.68 - i * h * 0.07;
      c.save();
      c.translate(cx, cy);
      c.rotate(i.isEven ? 0.6 : -0.6);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: 14, height: 8), leaf);
      c.restore();
    }
    // 곰 인형 (오른쪽 바닥)
    final bear = Paint()..color = const Color(0xFFB07A4F);
    final ex = w * 0.93, ey = h * 0.88;
    c.drawCircle(Offset(ex, ey), 14, bear);
    c.drawCircle(Offset(ex, ey - 20), 10, bear);
    c.drawCircle(Offset(ex - 8, ey - 28), 4, bear);
    c.drawCircle(Offset(ex + 8, ey - 28), 4, bear);
  }

  @override
  bool shouldRepaint(_) => false;
}
