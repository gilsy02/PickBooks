import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../insights.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../services/yes24.dart';
import 'yes24_settings_screen.dart';

const kAppVersion = '0.3.0';
const kPrivacyPolicyUrl = 'https://github.com/gilsy02/PickBooks/blob/HEAD/docs/privacy-policy.md';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final done = store.books.where((b) => b.status == BookStatus.done).toList();
        final thisYear = done.where((b) => b.finishedAt?.year == DateTime.now().year).length;
        Widget stat(String n, String l) => Expanded(
              child: Column(children: [
                Text(n, style: const TextStyle(fontFamily: PB.serif, fontSize: 24, fontWeight: FontWeight.w700, color: PB.primary)),
                const SizedBox(height: 4),
                Text(l, style: const TextStyle(fontSize: 12, color: PB.muted)),
              ]),
            );
        return ListView(padding: const EdgeInsets.only(bottom: 40), children: [
          const PickHeader(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              CircleAvatar(radius: 30, backgroundColor: PB.primarySoft, child: Text(store.nickname.isEmpty ? '?' : store.nickname[0], style: const TextStyle(fontFamily: PB.serif, fontSize: 24, color: PB.primary, fontWeight: FontWeight.w700))),
              const SizedBox(width: 16),
              Expanded(child: Text('${store.nickname}님', style: const TextStyle(fontFamily: PB.brush, fontSize: 32))),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final v = await askText(context, '이름 바꾸기', initial: store.nickname);
                  if (v != null && v.isNotEmpty) store.setNickname(v);
                },
              ),
            ]),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(color: PB.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: PB.line)),
            child: Row(children: [
              stat('${done.length}', '완독'),
              stat('$thisYear', '올해 완독'),
              stat('${store.books.where((b) => b.status == BookStatus.reading).length}', '읽는 중'),
              stat('${store.quotes.length}', '담은 문장'),
            ]),
          ),
          const SizedBox(height: 12),
          _tile(context, Icons.auto_stories_outlined, '픽북스가 본 나', '어떤 책을, 어떻게 읽는 독자인지',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReaderProfileScreen()))),
          _tile(context, Icons.key_rounded, '도서 검색 설정', hasYes24Proxy ? '기본 검색 서버 연결됨' : (store.yes24Key.isEmpty ? 'YES24 키를 넣으면 검색·바코드로 책을 담을 수 있어요' : 'YES24 키 연결됨'),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Yes24SettingsScreen()))),
          _tile(context, Icons.ios_share_rounded, '내 기록 내보내기', '모든 기록을 파일(JSON)로 공유해 백업해요',
              () => SharePlus.instance.share(ShareParams(text: store.exportJson(), subject: '픽북스 백업'))),
          _tile(context, Icons.restart_alt_rounded, '샘플 데이터로 되돌리기', '처음 보던 예시 서재로 바꿔요', () async {
            if (await _confirm(context, '지금 기록이 모두 지워지고 예시 서재로 바뀌어요.')) store.resetAll(withSample: true);
          }),
          _tile(context, Icons.delete_outline_rounded, '모든 기록 지우기', '샘플을 지우고 내 서재를 새로 시작해요', () async {
            if (await _confirm(context, '서재, 문장, 아이 책장이 모두 지워져요. 되돌릴 수 없어요.')) store.resetAll();
          }),
          _tile(context, Icons.privacy_tip_outlined, '개인정보처리방침', '어떤 정보를 어디에 저장하는지',
              () => launchUrl(Uri.parse(kPrivacyPolicyUrl), mode: LaunchMode.externalApplication)),
          _tile(context, Icons.article_outlined, '오픈소스 라이선스', '앱에 쓰인 글꼴과 소프트웨어',
              () => showLicensePage(context: context, applicationName: '픽북스', applicationVersion: kAppVersion)),
          const SizedBox(height: 24),
          const Center(child: Text('픽북스 $kAppVersion · 기록은 이 휴대폰에만 저장돼요', style: TextStyle(fontSize: 12, color: PB.muted))),
        ]);
      },
    );
  }

  Widget _tile(BuildContext context, IconData icon, String t, String s, VoidCallback onTap) => Container(
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        decoration: BoxDecoration(color: PB.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: PB.line)),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: PB.primarySoft, child: Icon(icon, color: PB.primary, size: 20)),
          title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(s, style: const TextStyle(fontSize: 12, color: PB.muted)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );

  Future<bool> _confirm(BuildContext context, String msg) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(msg),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('확인')),
          ],
        ),
      ) ??
      false;
}

class ReaderProfileScreen extends StatelessWidget {
  const ReaderProfileScreen({super.key});
  static const _icons = [Icons.library_books_outlined, Icons.menu_book_rounded, Icons.spa_outlined, Icons.local_cafe_outlined, Icons.edit_note];
  @override
  Widget build(BuildContext context) {
    final p = buildProfile(store);
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('픽북스가 본 나')),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 40), children: [
        Text('${now.year}년 ${now.month}월에 정리했어요', style: const TextStyle(fontSize: 13, color: PB.muted)),
        const SizedBox(height: 10),
        Text(p.headline, style: const TextStyle(fontFamily: PB.serif, fontSize: 26, height: 1.45, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(p.summary, style: const TextStyle(fontFamily: PB.serif, color: PB.muted, height: 1.7)),
        const SizedBox(height: 26),
        for (var i = 0; i < p.items.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.fromLTRB(16, 20, 18, 20),
            decoration: BoxDecoration(
              color: PB.card,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: IntrinsicHeight(
              child: Row(children: [
                CircleAvatar(radius: 24, backgroundColor: PB.primarySoft, child: Icon(_icons[i % _icons.length], color: PB.primary)),
                const SizedBox(width: 14),
                const VerticalDivider(color: PB.line, width: 1),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.items[i].title, style: const TextStyle(fontFamily: PB.serif, fontSize: 18, fontWeight: FontWeight.w700, color: PB.primary)),
                    const SizedBox(height: 8),
                    Text(p.items[i].body, style: const TextStyle(height: 1.65)),
                  ]),
                ),
              ]),
            ),
          ),
        const SizedBox(height: 10),
        const Text('지금은 서재와 기록의 숫자만으로 정리해요. 더 깊은 분석은 이후 업데이트에서 더해질 예정이에요.',
            style: TextStyle(fontSize: 12, color: PB.muted, height: 1.6)),
      ]),
    );
  }
}
