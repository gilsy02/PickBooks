import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'add_book_screen.dart';
import 'book_detail_screen.dart';

class ShelfScreen extends StatefulWidget {
  const ShelfScreen({super.key});
  @override
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen> {
  int mode = 0; // 0 전면, 1 일반

  void _share() {
    final buf = StringBuffer('📚 ${store.nickname}의 서재\n');
    for (final s in BookStatus.values) {
      final list = store.booksBy(s);
      buf.writeln('\n[${s.label} ${list.length}권]');
      for (final b in list) {
        buf.writeln('· ${b.title}${b.author.isEmpty ? '' : ' / ${b.author}'}');
      }
    }
    SharePlus.instance.share(ShareParams(text: buf.toString()));
  }

  void _sort() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PB.card,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('정렬', style: TextStyle(fontFamily: PB.serif, fontSize: 18, fontWeight: FontWeight.w700))),
          for (final (s, l) in [(ShelfSort.manual, '내가 놓은 순서'), (ShelfSort.recent, '최근 담은 순'), (ShelfSort.title, '제목 순')])
            ListTile(
              title: Text(l),
              trailing: store.sort == s ? const Icon(Icons.check, color: PB.primary) : null,
              onTap: () {
                store.setSort(s);
                Navigator.pop(ctx);
              },
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ListenableBuilder(
        listenable: store,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            PickHeader(actions: [
              IconButton(onPressed: _share, icon: const Icon(Icons.ios_share_rounded, color: PB.primary)),
              IconButton(onPressed: _sort, icon: const Icon(Icons.swap_vert_rounded, color: PB.ink)),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 14),
                  const Text('내 서재', style: TextStyle(fontFamily: PB.serif, fontSize: 26, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Container(width: 74, height: 2, color: PB.primary.withValues(alpha: 0.35)),
                ]),
                const Spacer(),
                const Motto(),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Segmented(
                items: const [(Icons.view_week_rounded, '전면 책장'), (Icons.view_column_rounded, '일반 책장')],
                index: mode,
                onChanged: (i) => setState(() => mode = i),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 14),
              child: Text('읽고 있는 책과 완독한 책을 서재에 채워보세요.  책을 꾹 눌러 다른 칸으로 옮길 수 있어요.',
                  style: TextStyle(fontSize: 13, color: PB.muted)),
            ),
            _Bookcase(spine: mode == 1),
          ],
        ),
      ),
      Positioned(
        right: 18,
        bottom: 18,
        child: PrimaryPill(
          label: '책 담기',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBookScreen())),
        ),
      ),
    ]);
  }
}

class _Bookcase extends StatelessWidget {
  final bool spine;
  const _Bookcase({required this.spine});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(colors: [Color(0xFFBF8B5B), Color(0xFFD3A576), Color(0xFFBF8B5B)]),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFDDBB91), Color(0xFFEBD3B0), Color(0xFFE2C49C)]),
        ),
        child: Column(children: [for (final s in BookStatus.values) _ShelfSection(status: s, spine: spine)]),
      ),
    );
  }
}

class _ShelfSection extends StatelessWidget {
  final BookStatus status;
  final bool spine;
  const _ShelfSection({required this.status, required this.spine});

  @override
  Widget build(BuildContext context) {
    final books = store.booksBy(status);
    return DragTarget<Book>(
      onWillAcceptWithDetails: (d) => true,
      onAcceptWithDetails: (d) => store.moveBook(d.data, status),
      builder: (context, cand, _) {
        final hovering = cand.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: hovering ? PB.primary.withValues(alpha: 0.08) : Colors.transparent,
          child: LayoutBuilder(builder: (context, c) {
            final inner = c.maxWidth - 24;
            final perRow = spine ? (inner / 34).floor() : 4;
            final rows = <List<Book>>[];
            for (var i = 0; i < books.length; i += perRow) {
              rows.add(books.sublist(i, (i + perRow).clamp(0, books.length)));
            }
            if (rows.isEmpty) rows.add([]);
            final coverW = (inner - 3 * 12) / 4;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 0, 6),
                child: _Label('${status.label} ${books.length}권'),
              ),
              for (final row in rows) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    height: spine ? 150 : coverW * 1.45,
                    child: row.isEmpty
                        ? Center(
                            child: Text(hovering ? '여기에 놓기' : '책을 끌어다 놓아 보세요',
                                style: const TextStyle(color: Color(0x99654A30), fontSize: 13)))
                        : Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            for (final b in row)
                              Padding(
                                padding: EdgeInsets.only(right: spine ? 3 : 12),
                                child: _DraggableBook(book: b, width: coverW, spine: spine),
                              ),
                          ]),
                  ),
                ),
                const _Plank(),
              ],
            ]);
          }),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
            color: const Color(0xFFF7EEE3),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 3, offset: Offset(0, 2))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 16, height: 2.5, color: PB.primary),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _Plank extends StatelessWidget {
  const _Plank();
  @override
  Widget build(BuildContext context) => Container(
        height: 12,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD9AF7F), Color(0xFFB7854F)]),
          boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 3))],
        ),
      );
}

class _DraggableBook extends StatelessWidget {
  final Book book;
  final double width;
  final bool spine;
  const _DraggableBook({required this.book, required this.width, required this.spine});

  @override
  Widget build(BuildContext context) {
    final child = spine ? _Spine(book: book) : _FrontBook(book: book, width: width);
    return DragTarget<Book>(
      onWillAcceptWithDetails: (d) => d.data != book,
      onAcceptWithDetails: (d) => store.moveBook(d.data, book.status, before: book),
      builder: (context, cand, _) => Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (cand.isNotEmpty) Container(width: 3, height: spine ? 120 : width * 1.3, color: PB.primary, margin: const EdgeInsets.only(right: 4)),
        LongPressDraggable<Book>(
          data: book,
          feedback: Material(color: Colors.transparent, child: Opacity(opacity: 0.9, child: Transform.scale(scale: 1.08, child: child))),
          childWhenDragging: Opacity(opacity: 0.25, child: child),
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id))),
            child: child,
          ),
        ),
      ]),
    );
  }
}

class _FrontBook extends StatelessWidget {
  final Book book;
  final double width;
  const _FrontBook({required this.book, required this.width});
  @override
  Widget build(BuildContext context) {
    final h = width * 1.42;
    return SizedBox(
      width: width,
      height: h,
      child: Stack(children: [
        BookCover(title: book.title, author: book.author, url: book.coverUrl, path: book.coverPath, seed: book.colorSeed, width: width, height: h),
        if (book.status == BookStatus.reading && book.totalPages > 0)
          Positioned(left: 6, right: 6, bottom: 6, child: ProgressBadge(progress: book.progress)),
      ]),
    );
  }
}

class ProgressBadge extends StatelessWidget {
  final double progress;
  const ProgressBadge({super.key, required this.progress});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: progress, minHeight: 3, color: PB.primary, backgroundColor: const Color(0xFFE8DCD6)),
            ),
          ),
          const SizedBox(width: 5),
          Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: PB.ink)),
        ]),
      );
}

class _Spine extends StatelessWidget {
  final Book book;
  const _Spine({required this.book});
  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF6B2D3A), Color(0xFF2F4858), Color(0xFF3C5A3A), Color(0xFFE8DCC8), Color(0xFF1F2A44),
      Color(0xFFD9822B), Color(0xFFF4F1EA), Color(0xFF7A9CB8), Color(0xFFB85C5C), Color(0xFF4A3F6B),
    ];
    final c = colors[book.colorSeed.abs() % colors.length];
    final dark = c.computeLuminance() < 0.4;
    final h = 112.0 + (book.colorSeed.abs() % 34);
    final w = 26.0 + (book.colorSeed.abs() % 7);
    if (book.spineUrl != null) {
      return Container(
        width: w,
        height: 140,
        decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(1, 2))]),
        child: Image.network(book.spineUrl!, fit: BoxFit.fill, errorBuilder: (_, _, _) => Container(color: c)),
      );
    }
    return Container(
      width: w,
      height: h,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(colors: [c.withValues(alpha: 0.85), c, c.withValues(alpha: 0.8)]),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(1, 2))],
      ),
      child: Column(children: [
        Container(height: 1.5, width: w * 0.6, color: (dark ? Colors.white : PB.ink).withValues(alpha: 0.5)),
        const SizedBox(height: 6),
        Expanded(
          child: Text(
            book.title.split('').join('\n'),
            textAlign: TextAlign.center,
            overflow: TextOverflow.fade,
            style: TextStyle(fontFamily: PB.serif, fontSize: 11, height: 1.05, fontWeight: FontWeight.w700, color: dark ? Colors.white : PB.ink),
          ),
        ),
        if (book.status == BookStatus.reading && book.totalPages > 0)
          Text('${(book.progress * 100).round()}', style: TextStyle(fontSize: 8, color: dark ? Colors.white70 : PB.muted)),
      ]),
    );
  }
}
