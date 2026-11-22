import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'quote_edit_screen.dart';

/// 노트를 펼친 모양으로 담은 문장을 한 장씩 넘겨 본다.
class QuoteViewerScreen extends StatefulWidget {
  final List<Quote> quotes;
  final int initial;
  const QuoteViewerScreen({super.key, required this.quotes, this.initial = 0});
  @override
  State<QuoteViewerScreen> createState() => _QuoteViewerScreenState();
}

class _QuoteViewerScreenState extends State<QuoteViewerScreen> {
  late final ctrl = PageController(initialPage: widget.initial);
  late int page = widget.initial;

  @override
  Widget build(BuildContext context) {
    final qs = widget.quotes.where(store.quotes.contains).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('담은 문장'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(30),
          child: Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('마음에 담아둔 문장들을 천천히 넘겨보세요.', style: TextStyle(fontFamily: PB.serif, fontSize: 13, color: PB.muted)),
          ),
        ),
      ),
      body: qs.isEmpty
          ? const Center(child: Text('담은 문장이 없어요.'))
          : Column(children: [
              Expanded(
                child: PageView.builder(
                  controller: ctrl,
                  itemCount: qs.length,
                  onPageChanged: (i) => setState(() => page = i),
                  itemBuilder: (_, i) => _NotePage(quote: qs[i]),
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < qs.length && i < 12; i++)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: i == page ? PB.primary : PB.line),
                  ),
              ]),
              const SizedBox(height: 8),
              Text('${page + 1} / ${qs.length}', style: const TextStyle(fontFamily: PB.serif, color: PB.muted)),
              const SizedBox(height: 6),
              const Text('좌우로 스와이프하여 다른 문장을 둘러보세요.', style: TextStyle(fontFamily: PB.serif, fontSize: 12, color: PB.muted)),
              const SizedBox(height: 24),
            ]),
    );
  }
}

class _NotePage extends StatelessWidget {
  final Quote quote;
  const _NotePage({required this.quote});
  @override
  Widget build(BuildContext context) {
    final b = store.bookById(quote.bookId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 20, 12),
      child: Stack(children: [
        // 왼쪽 페이지 가장자리
        Positioned(
          left: 0, top: 10, bottom: 20, width: 40,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFF3ECE1), Color(0xFFE2D7C6)]),
              boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 6)],
            ),
          ),
        ),
        // 표지(빨간 띠)
        Positioned(left: 20, right: 0, bottom: 10, height: 16, child: Container(color: const Color(0xFF7A1E2A))),
        Positioned(
          right: 60, bottom: -2, width: 18, height: 40,
          child: CustomPaint(painter: _RibbonPainter()),
        ),
        // 오른쪽 페이지
        Positioned(
          left: 36, right: 4, top: 0, bottom: 18,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF6EE),
              borderRadius: const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
              boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 10, offset: Offset(2, 4))],
              gradient: LinearGradient(colors: [const Color(0xFFEFE6D8), const Color(0xFFFBF6EE), const Color(0xFFFBF6EE).withValues(alpha: 1)], stops: const [0, 0.08, 1]),
            ),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Expanded(child: Divider(color: Color(0xFFCDB9A0))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.spa_outlined, size: 20, color: Colors.brown.shade300)),
                  const Expanded(child: Divider(color: Color(0xFFCDB9A0))),
                ]),
                const SizedBox(height: 10),
                Center(child: Text(fmtDate(quote.createdAt), style: const TextStyle(fontFamily: PB.serif, color: PB.muted, fontSize: 15))),
                const SizedBox(height: 18),
                if (b != null)
                  Row(children: [
                    BookCover(title: b.title, url: b.coverUrl, path: b.coverPath, seed: b.colorSeed, width: 44, height: 62),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b.title, style: const TextStyle(fontFamily: PB.serif, fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text([b.author, b.publisher].where((e) => e.isNotEmpty).join(' · '),
                            style: const TextStyle(fontFamily: PB.serif, color: PB.muted, fontSize: 13)),
                      ]),
                    ),
                  ]),
                const SizedBox(height: 14),
                const Divider(color: Color(0xFFDCCDBA)),
                const Text('“', style: TextStyle(fontSize: 34, color: Color(0xFFCDB9A0), height: 1)),
                Text(quote.text, style: const TextStyle(fontFamily: PB.serif, fontSize: 16, height: 1.8)),
                const Align(alignment: Alignment.centerRight, child: Text('”', style: TextStyle(fontSize: 34, color: Color(0xFFCDB9A0), height: 1))),
                if (quote.page != null) Text('${quote.page}쪽', style: const TextStyle(color: PB.muted, fontSize: 12)),
                const SizedBox(height: 18),
                Row(children: [
                  const Text('내 생각', style: TextStyle(fontFamily: PB.pen, fontSize: 21, color: PB.primary)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit_outlined, size: 18, color: PB.primary),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuoteEditScreen(quote: quote))),
                  ),
                ]),
                const Divider(color: Color(0xFFDCCDBA), height: 8),
                const SizedBox(height: 8),
                if (quote.thought.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFF1DCD3).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(2)),
                    child: Text(quote.thought, style: const TextStyle(fontFamily: PB.pen, fontSize: 21, height: 1.5, color: Color(0xFF3A2A28))),
                  )
                else
                  const Text('아직 남긴 생각이 없어요.', style: TextStyle(fontFamily: PB.pen, fontSize: 19, color: PB.muted)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width, s.height)
      ..lineTo(s.width / 2, s.height * 0.78)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(p, Paint()..color = PB.primary);
  }

  @override
  bool shouldRepaint(_) => false;
}
