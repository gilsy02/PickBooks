import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'kid_book_screens.dart';

class KidsRecommendScreen extends StatelessWidget {
  const KidsRecommendScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final cid = store.selectedChildId;
        final name = store.selectedChild?.name ?? '아이';
        final read = store.kidBooksOf(cid, toRead: false);
        final toRead = store.kidBooksOf(cid, toRead: true);
        final monthAgo = DateTime.now().subtract(const Duration(days: 21));
        final again = read.where((k) => k.liked && (k.lastRead?.isBefore(monthAgo) ?? false)).toList();
        final areas = store.areaCounts(cid);
        final weakest = areas.entries.reduce((a, b) => a.value <= b.value ? a : b);
        Widget row(KidBook k, String sub) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: BookCover(title: k.title, url: k.coverUrl, path: k.coverPath, seed: k.colorSeed, width: 44, height: 58),
              title: Text(k.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(sub),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => KidBookDetailScreen(id: k.id))),
            );
        return ListView(padding: const EdgeInsets.only(bottom: 40), children: [
          const PickHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Text('$name에게 권하는 책', style: const TextStyle(fontFamily: PB.serif, fontSize: 24, fontWeight: FontWeight.w700)),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFFF7ECEA), borderRadius: BorderRadius.circular(16)),
            child: Text('$name의 머릿속에서 아직 연한 곳은 「${weakest.key}」이에요.\n다음 책은 ${weakest.key}을(를) 다루는 이야기로 골라 보세요.',
                style: const TextStyle(color: PB.primary, height: 1.6, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 24),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: SectionTitle('다시 읽어 주면 좋아할 책')),
          if (again.isEmpty)
            const Padding(padding: EdgeInsets.fromLTRB(52, 12, 24, 0), child: Text('좋아요 한 책 중 3주 넘게 안 읽은 책이 여기에 모여요.', style: TextStyle(color: PB.muted, fontSize: 13))),
          for (final k in again) row(k, '마지막으로 읽은 지 ${DateTime.now().difference(k.lastRead!).inDays}일'),
          const SizedBox(height: 24),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: SectionTitle('읽어 볼 책')),
          if (toRead.isEmpty)
            const Padding(padding: EdgeInsets.fromLTRB(52, 12, 24, 0), child: Text('책장 탭의 「읽어 볼 책」에 담은 책이 여기에 보여요.', style: TextStyle(color: PB.muted, fontSize: 13))),
          for (final k in toRead) row(k, k.author),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('새 책을 골라 주는 추천은 이후 업데이트에서 더해질 예정이에요.', style: TextStyle(fontSize: 12, color: PB.muted)),
          ),
        ]);
      },
    );
  }
}
