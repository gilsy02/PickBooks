import 'package:flutter/material.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'quote_edit_screen.dart';
import 'quote_viewer_screen.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final qs = store.quotesSorted();
          return ListView(padding: const EdgeInsets.only(bottom: 110), children: [
            const PickHeader(),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 4),
              child: Text('기록', style: TextStyle(fontFamily: PB.serif, fontSize: 26, fontWeight: FontWeight.w700)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text('마음에 담은 문장과 그때의 내 생각', style: TextStyle(color: PB.muted)),
            ),
            if (qs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), foregroundColor: PB.primary),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuoteViewerScreen(quotes: qs))),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('노트로 넘겨 보기'),
                ),
              ),
            const SizedBox(height: 12),
            if (qs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Text('아직 담은 문장이 없어요.\n책 상세에서 문장을 담아 보세요.', textAlign: TextAlign.center, style: TextStyle(color: PB.muted, height: 1.6)),
              ),
            for (var i = 0; i < qs.length; i++)
              Builder(builder: (context) {
                final q = qs[i];
                final b = store.bookById(q.bookId);
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuoteViewerScreen(quotes: qs, initial: i))),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: PB.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: PB.line)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (b != null) BookCover(title: b.title, url: b.coverUrl, path: b.coverPath, seed: b.colorSeed, width: 40, height: 56),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${b?.title ?? ''}  ·  ${fmtDate(q.createdAt)}', style: const TextStyle(fontSize: 12, color: PB.muted)),
                          const SizedBox(height: 6),
                          Text('“${q.text}”', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: PB.serif, height: 1.6)),
                          if (q.thought.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(q.thought, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontFamily: PB.pen, fontSize: 18, color: Color(0xFF5A3A36))),
                          ],
                        ]),
                      ),
                    ]),
                  ),
                );
              }),
          ]);
        },
      ),
      Positioned(
        right: 18,
        bottom: 18,
        child: PrimaryPill(
          label: '문장 담기',
          icon: Icons.format_quote_rounded,
          onTap: () {
            if (store.books.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('먼저 서재에 책을 담아 주세요.')));
              return;
            }
            Navigator.push(context, MaterialPageRoute(builder: (_) => const QuoteEditScreen()));
          },
        ),
      ),
    ]);
  }
}
