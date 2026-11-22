import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'quote_edit_screen.dart';
import 'quote_viewer_screen.dart';

class BookDetailScreen extends StatelessWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final b = store.bookById(bookId);
        if (b == null) return const Scaffold(body: SizedBox());
        final qs = store.quotesOf(b.id);
        return Scaffold(
          appBar: AppBar(actions: [
            PopupMenuButton<String>(
              color: PB.card,
              onSelected: (v) async {
                if (v == 'edit') {
                  await _editInfo(context, b);
                } else if (v == 'delete') {
                  final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                            title: const Text('서재에서 뺄까요?'),
                            content: const Text('이 책에 담은 문장도 함께 지워져요.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('빼기')),
                            ],
                          ));
                  if (ok == true && context.mounted) {
                    Navigator.pop(context);
                    store.deleteBook(b);
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('정보 고치기')),
                PopupMenuItem(value: 'delete', child: Text('서재에서 빼기')),
              ],
            ),
          ]),
          body: ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 40), children: [
            Center(child: BookCover(title: b.title, author: b.author, url: b.coverUrl, path: b.coverPath, seed: b.colorSeed, width: 140, height: 200, radius: 4)),
            const SizedBox(height: 18),
            Text(b.title, textAlign: TextAlign.center, style: const TextStyle(fontFamily: PB.serif, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text([b.author, b.publisher].where((e) => e.isNotEmpty).join('  |  '),
                textAlign: TextAlign.center, style: const TextStyle(color: PB.muted)),
            if (b.isbn != null)
              const Padding(padding: EdgeInsets.only(top: 6), child: Text('도서 정보 제공: 예스24', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: PB.muted))),
            if (b.link != null && b.link!.startsWith('https://'))
              Center(
                child: TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(b.link!), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('예스24에서 보기'),
                ),
              ),
            const SizedBox(height: 20),
            Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
              for (final s in BookStatus.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: b.status == s,
                  selectedColor: PB.primary,
                  showCheckmark: false,
                  backgroundColor: PB.card,
                  labelStyle: TextStyle(color: b.status == s ? Colors.white : PB.ink, fontWeight: FontWeight.w600),
                  onSelected: (_) => store.moveBook(b, s),
                ),
            ]),
            const SizedBox(height: 20),
            if (b.status != BookStatus.want) _ProgressCard(book: b),
            if (b.status == BookStatus.done) ...[
              const SizedBox(height: 12),
              _card(Row(children: [
                const Text('내 별점', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                for (var i = 1; i <= 5; i++)
                  GestureDetector(
                    onTap: () {
                      b.rating = b.rating == i ? 0 : i;
                      store.updateBook(b);
                    },
                    child: Icon(i <= b.rating ? Icons.star_rounded : Icons.star_outline_rounded, color: PB.primary, size: 28),
                  ),
              ])),
            ],
            const SizedBox(height: 24),
            SectionTitle('담은 문장 ${qs.length}',
                trailing: TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuoteEditScreen(bookId: b.id))),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('문장 담기'),
                )),
            const SizedBox(height: 8),
            if (qs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('마음에 남은 문장을 담아 보세요.', textAlign: TextAlign.center, style: TextStyle(color: PB.muted)),
              ),
            for (var i = 0; i < qs.length; i++)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuoteViewerScreen(quotes: qs, initial: i))),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: PB.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: PB.line)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('“${qs[i].text}”', style: const TextStyle(fontFamily: PB.serif, height: 1.6)),
                    if (qs[i].thought.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(qs[i].thought, style: const TextStyle(fontFamily: PB.pen, fontSize: 19, color: Color(0xFF5A3A36))),
                    ],
                  ]),
                ),
              ),
          ]),
        );
      },
    );
  }

  static Widget _card(Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: PB.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: PB.line)),
        child: child,
      );

  Future<void> _editInfo(BuildContext context, Book b) async {
    final t = TextEditingController(text: b.title), a = TextEditingController(text: b.author);
    final p = TextEditingController(text: b.publisher), pg = TextEditingController(text: b.totalPages == 0 ? '' : '${b.totalPages}');
    final c = TextEditingController(text: b.category);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PB.card,
        title: const Text('정보 고치기'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: t, decoration: const InputDecoration(labelText: '제목')),
            const SizedBox(height: 8),
            TextField(controller: a, decoration: const InputDecoration(labelText: '지은이')),
            const SizedBox(height: 8),
            TextField(controller: p, decoration: const InputDecoration(labelText: '출판사')),
            const SizedBox(height: 8),
            TextField(controller: pg, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '전체 쪽수')),
            const SizedBox(height: 8),
            TextField(controller: c, decoration: const InputDecoration(labelText: '분류')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('저장')),
        ],
      ),
    );
    if (ok == true && t.text.trim().isNotEmpty) {
      b
        ..title = t.text.trim()
        ..author = a.text.trim()
        ..publisher = p.text.trim()
        ..totalPages = int.tryParse(pg.text.trim()) ?? 0
        ..category = c.text.trim();
      store.updateBook(b);
    }
  }
}

class _ProgressCard extends StatelessWidget {
  final Book book;
  const _ProgressCard({required this.book});
  @override
  Widget build(BuildContext context) {
    final b = book;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: PB.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: PB.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('읽은 쪽', style: TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(b.totalPages > 0 ? '${b.currentPage} / ${b.totalPages}쪽  ·  ${(b.progress * 100).round()}%' : '전체 쪽수를 입력하면 진행률이 보여요',
              style: const TextStyle(color: PB.muted, fontSize: 13)),
        ]),
        if (b.totalPages > 0)
          Slider(
            value: b.currentPage.toDouble().clamp(0, b.totalPages.toDouble()),
            max: b.totalPages.toDouble(),
            divisions: b.totalPages,
            activeColor: PB.primary,
            onChanged: (v) {
              b.currentPage = v.round();
              store.updateBook(b);
            },
            onChangeEnd: (v) {
              if (v.round() >= b.totalPages && b.status != BookStatus.done) {
                store.moveBook(b, BookStatus.done);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('완독을 축하해요! 완독한 책 칸으로 옮겼어요.')));
              }
            },
          ),
      ]),
    );
  }
}
