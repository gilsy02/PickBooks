import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../insights.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'book_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ctrl = PageController(viewportFraction: 0.86);
  int page = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final picks = weeklyPicks(store);
        final reading = store.books.where((b) => b.status == BookStatus.reading).toList();
        return ListView(padding: const EdgeInsets.only(bottom: 30), children: [
          PickHeader(actions: [IconButton(onPressed: () => _search(context), icon: const Icon(Icons.search_rounded, size: 28))]),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('안녕하세요,', style: TextStyle(fontSize: 18, color: PB.ink)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.transparent, Color(0xFFE3D3C2), Color(0xFFE3D3C2)], stops: [0, 0.55, 0.55, 1]),
                  ),
                  child: Text('${store.nickname}님', style: const TextStyle(fontFamily: PB.brush, fontSize: 34, height: 1.1)),
                ),
              ]),
              const Spacer(),
              const Padding(padding: EdgeInsets.only(top: 22), child: Motto()),
            ]),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SectionTitle('${store.nickname}님께 권하는 책',
                trailing: const Text('이번 주 추천', style: TextStyle(color: PB.muted, fontSize: 13))),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(52, 6, 24, 16),
            child: Text('담아 둔 책 중에서 매주 다섯 권을 골라 드려요.', style: TextStyle(fontSize: 13, color: PB.muted)),
          ),
          if (picks.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: PB.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: PB.line)),
              child: const Text('읽고 싶은 책을 서재에 담으면\n이번 주에 펼쳐 볼 책을 골라 드릴게요.',
                  textAlign: TextAlign.center, style: TextStyle(color: PB.muted, height: 1.6)),
            )
          else ...[
            SizedBox(
              height: 560,
              child: PageView.builder(
                controller: ctrl,
                padEnds: false,
                itemCount: picks.length,
                onPageChanged: (i) => setState(() => page = i),
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 20 : 6, right: 6),
                  child: _PickCard(index: i, pick: picks[i]),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < picks.length; i++)
                Container(
                  width: 7, height: 7, margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: i == page ? PB.primary : PB.line),
                ),
            ]),
          ],
          if (reading.isNotEmpty) ...[
            const SizedBox(height: 30),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: SectionTitle('이어 읽기')),
            const SizedBox(height: 12),
            for (final b in reading)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: b.id))),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: PB.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: PB.line)),
                  child: Row(children: [
                    BookCover(title: b.title, url: b.coverUrl, path: b.coverPath, seed: b.colorSeed, width: 44, height: 62),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b.title, style: const TextStyle(fontFamily: PB.serif, fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(value: b.progress, minHeight: 5, color: PB.primary, backgroundColor: PB.primarySoft),
                        ),
                        const SizedBox(height: 6),
                        Text(b.totalPages > 0 ? '${b.currentPage}/${b.totalPages}쪽 · ${(b.progress * 100).round()}%' : '쪽수를 입력해 보세요',
                            style: const TextStyle(fontSize: 12, color: PB.muted)),
                      ]),
                    ),
                  ]),
                ),
              ),
          ],
        ]);
      },
    );
  }

  void _search(BuildContext context) {
    showSearch(context: context, delegate: _ShelfSearch());
  }
}

class _PickCard extends StatelessWidget {
  final int index;
  final Pick pick;
  const _PickCard({required this.index, required this.pick});
  @override
  Widget build(BuildContext context) {
    final b = pick.book;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: b.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: PB.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Stack(children: [
          Positioned(
            left: 22, top: 0,
            child: CustomPaint(
              size: const Size(44, 54),
              painter: _Flag(),
              child: SizedBox(
                width: 44, height: 44,
                child: Center(child: Text('0${index + 1}', style: const TextStyle(fontFamily: PB.serif, color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17))),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            child: Column(children: [
              SizedBox(
                height: 250,
                child: Stack(alignment: Alignment.center, children: [
                  Transform.rotate(
                    angle: 6 * math.pi / 180,
                    child: Container(
                      width: 170, height: 220, margin: const EdgeInsets.only(left: 60),
                      color: const Color(0xFFEDE3D6),
                      alignment: const Alignment(0.9, -0.2),
                      child: const Text('Pick ', style: TextStyle(fontFamily: PB.brush, fontSize: 26, color: Color(0xFFB98F92))),
                    ),
                  ),
                  Transform.rotate(angle: -3 * math.pi / 180, child: Container(width: 160, height: 220, margin: const EdgeInsets.only(right: 40), color: const Color(0xFFE6DACB))),
                  BookCover(title: b.title, author: b.author, url: b.coverUrl, path: b.coverPath, seed: b.colorSeed, width: 156, height: 224),
                ]),
              ),
              const SizedBox(height: 18),
              Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: PB.serif, fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text([b.author, b.publisher].where((e) => e.isNotEmpty).join('  |  '), style: const TextStyle(color: PB.muted)),
              const SizedBox(height: 12),
              Container(width: 36, height: 2, color: PB.primary.withValues(alpha: 0.4)),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: const Color(0xFFF7ECEA), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Expanded(child: Text(pick.reason, style: const TextStyle(color: PB.primary, height: 1.6, fontWeight: FontWeight.w600))),
                  const Icon(Icons.chevron_right, color: PB.primary),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Flag extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Path()
      ..lineTo(s.width, 0)
      ..lineTo(s.width, s.height)
      ..lineTo(s.width / 2, s.height * 0.8)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(p, Paint()..color = PB.primary);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ShelfSearch extends SearchDelegate<void> {
  @override
  String get searchFieldLabel => '내 서재에서 찾기';
  @override
  List<Widget> buildActions(BuildContext context) => [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];
  @override
  Widget buildLeading(BuildContext context) => IconButton(onPressed: () => close(context, null), icon: const Icon(Icons.arrow_back));
  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);
  @override
  Widget buildSuggestions(BuildContext context) {
    final q = query.trim();
    final list = store.books.where((b) => q.isEmpty || b.title.contains(q) || b.author.contains(q)).toList();
    return ListView(children: [
      for (final b in list)
        ListTile(
          leading: BookCover(title: b.title, url: b.coverUrl, path: b.coverPath, seed: b.colorSeed, width: 34, height: 48),
          title: Text(b.title),
          subtitle: Text('${b.author} · ${b.status.label}'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: b.id))),
        ),
    ]);
  }
}
