import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'kid_book_screens.dart';

class KidsShelfScreen extends StatefulWidget {
  const KidsShelfScreen({super.key});
  @override
  State<KidsShelfScreen> createState() => _KidsShelfScreenState();
}

enum KidSort { recent, count, liked }

class _KidsShelfScreenState extends State<KidsShelfScreen> {
  int tab = 0;
  String query = '';
  KidSort sort = KidSort.recent;
  bool likedOnly = false;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final cid = store.selectedChildId;
          final read = store.kidBooksOf(cid, toRead: false);
          final toRead = store.kidBooksOf(cid, toRead: true);
          var list = (tab == 0 ? read : toRead).where((k) => query.isEmpty || k.title.contains(query) || k.author.contains(query)).toList();
          if (likedOnly) list = list.where((k) => k.liked).toList();
          if (sort == KidSort.count) list.sort((a, b) => b.readCount.compareTo(a.readCount));
          if (sort == KidSort.liked) list.sort((a, b) => (b.liked ? 1 : 0).compareTo(a.liked ? 1 : 0));
          return ListView(padding: const EdgeInsets.only(bottom: 110), children: [
            const PickHeader(),
            const SizedBox(height: 10),
            _ChildPicker(),
            const SizedBox(height: 12),
            if (cid == null)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Text('오른쪽 위 + 를 눌러 아이 서재를 만들어 보세요.', textAlign: TextAlign.center, style: TextStyle(color: PB.muted)),
              )
            else ...[
              SizedBox(
                height: 200,
                child: Stack(children: [
                  Positioned.fill(
                    bottom: 30,
                    child: ShaderMask(
                      shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black, Colors.black, Colors.transparent], stops: [0, 0.7, 1]).createShader(r),
                      blendMode: BlendMode.dstIn,
                      child: Image.asset('assets/images/kids_room.jpg', fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    left: 20, right: 20, bottom: 4,
                    child: Segmented(
                      items: [(Icons.chrome_reader_mode_outlined, '읽은 책  ${read.length}권'), (Icons.bookmark_border, '읽어 볼 책  ${toRead.length}권')],
                      index: tab,
                      onChanged: (i) => setState(() => tab = i),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => query = v.trim()),
                      decoration: InputDecoration(
                        hintText: '책 제목이나 지은이로 찾기',
                        hintStyle: const TextStyle(color: PB.muted),
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: PB.line)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: PB.line)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: PB.card,
                    shape: const CircleBorder(side: BorderSide(color: PB.line)),
                    child: IconButton(onPressed: _filter, icon: const Icon(Icons.tune_rounded)),
                  ),
                ]),
              ),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Text(tab == 0 ? '아이와 함께 읽은 책을 담아 보세요.' : '다음에 읽어 줄 책을 담아 두세요.',
                      textAlign: TextAlign.center, style: const TextStyle(color: PB.muted)),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(builder: (context, c) {
                    final w = (c.maxWidth - 2 * 12) / 3;
                    return Wrap(spacing: 12, runSpacing: 14, children: [for (final k in list) _KidCard(book: k, width: w)]);
                  }),
                ),
            ],
          ]);
        },
      ),
      Positioned(
        right: 18,
        bottom: 18,
        child: PrimaryPill(
          label: '책 담기',
          onTap: () {
            if (store.selectedChildId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('먼저 아이 서재를 만들어 주세요.')));
              return;
            }
            Navigator.push(context, MaterialPageRoute(builder: (_) => KidBookEditScreen(toRead: tab == 1)));
          },
        ),
      ),
    ]);
  }

  void _filter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PB.card,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('정렬과 필터', style: TextStyle(fontFamily: PB.serif, fontSize: 18, fontWeight: FontWeight.w700))),
            for (final (s, l) in [(KidSort.recent, '최근 읽은 순'), (KidSort.count, '많이 읽은 순'), (KidSort.liked, '좋아요 먼저')])
              ListTile(
                title: Text(l),
                trailing: sort == s ? const Icon(Icons.check, color: PB.primary) : null,
                onTap: () {
                  setState(() => sort = s);
                  setS(() {});
                },
              ),
            SwitchListTile(
              title: const Text('좋아요 한 책만'),
              value: likedOnly,
              activeTrackColor: PB.primary,
              onChanged: (v) {
                setState(() => likedOnly = v);
                setS(() {});
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class _ChildPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 24), children: [
        for (final c in store.children)
          _avatar(context, c.name.isEmpty ? '?' : c.name[0], c.name, c.id == store.selectedChildId,
              onTap: () => store.selectChild(c.id), onEdit: () => _edit(context, c)),
        _avatar(context, '+', '서재 더하기', false, onTap: () async {
          final v = await askText(context, '아이 이름', hint: '예: 하루');
          if (v != null && v.isNotEmpty) store.addChild(v);
        }),
      ]),
    );
  }

  Widget _avatar(BuildContext context, String ch, String label, bool active, {required VoidCallback onTap, VoidCallback? onEdit}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 96,
        child: Column(children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 58, height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? const Color(0xFFFFF8F4) : const Color(0xFFEDE3DA),
                border: Border.all(color: active ? PB.primary : Colors.transparent, width: 2),
              ),
              child: Text(ch, style: TextStyle(fontSize: ch == '+' ? 28 : 20, color: active ? PB.primary : PB.ink, fontWeight: FontWeight.w600)),
            ),
            if (onEdit != null)
              Positioned(
                right: -4, bottom: -2,
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: PB.primary, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.edit, size: 12, color: Colors.white),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: active ? PB.primary : PB.ink, fontSize: 14)),
        ]),
      ),
    );
  }

  Future<void> _edit(BuildContext context, Child c) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: PB.card,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('이름 바꾸기'), onTap: () => Navigator.pop(ctx, 'rename')),
          ListTile(leading: const Icon(Icons.delete_outline), title: const Text('서재 지우기'), onTap: () => Navigator.pop(ctx, 'delete')),
        ]),
      ),
    );
    if (!context.mounted) return;
    if (action == 'rename') {
      final v = await askText(context, '아이 이름', initial: c.name);
      if (v != null && v.isNotEmpty) store.renameChild(c, v);
    } else if (action == 'delete') {
      store.deleteChild(c);
    }
  }
}

class _KidCard extends StatelessWidget {
  final KidBook book;
  final double width;
  const _KidCard({required this.book, required this.width});
  @override
  Widget build(BuildContext context) {
    final k = book;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => KidBookDetailScreen(id: k.id))),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: PB.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            BookCover(title: k.title, author: k.author, url: k.coverUrl, path: k.coverPath, seed: k.colorSeed, width: width, height: width * 1.32, radius: 0),
            Positioned(
              right: 6, top: 6,
              child: GestureDetector(
                onTap: () {
                  k.liked = !k.liked;
                  store.updateKidBook(k);
                },
                child: Container(
                  width: 30, height: 30,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  child: Icon(k.liked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined, size: 17, color: PB.primary),
                ),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(k.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text(k.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: PB.muted)),
              if (k.lastRead != null)
                Text('${k.lastRead!.year}. ${k.lastRead!.month}. ${k.lastRead!.day}.', style: const TextStyle(fontSize: 12, color: PB.ink)),
              if (!k.toRead)
                Row(children: [
                  const Icon(Icons.sync_rounded, size: 15, color: PB.primary),
                  const SizedBox(width: 3),
                  Text('${k.readCount}', style: const TextStyle(fontWeight: FontWeight.w800, color: PB.primary)),
                ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
