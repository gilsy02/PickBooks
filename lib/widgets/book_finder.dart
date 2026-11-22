import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../screens/yes24_settings_screen.dart';
import '../services/yes24.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';

const kYes24Credit = '도서 정보 제공: 예스24';

/// 키가 없을 때 보여 주는 안내
class NeedKeyCard extends StatelessWidget {
  const NeedKeyCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: PB.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: PB.line)),
        child: Column(children: [
          const Icon(Icons.key_rounded, size: 40, color: PB.primary),
          const SizedBox(height: 10),
          const Text('YES24 키를 넣으면 검색할 수 있어요', style: TextStyle(fontFamily: PB.serif, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('YES24 개발자센터에서 무료로 바로 발급받을 수 있어요.', textAlign: TextAlign.center, style: TextStyle(color: PB.muted)),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Yes24SettingsScreen())),
            child: const Text('키 넣으러 가기'),
          ),
        ]),
      );
}

/// 제목·지은이로 YES24 검색
class BookSearchView extends StatefulWidget {
  final ValueChanged<Yes24Book> onPick;
  final bool Function(Yes24Book)? isAdded;
  const BookSearchView({super.key, required this.onPick, this.isAdded});
  @override
  State<BookSearchView> createState() => _BookSearchViewState();
}

class _BookSearchViewState extends State<BookSearchView> {
  final ctrl = TextEditingController();
  List<Yes24Book>? results;
  String? error;
  bool loading = false;

  Future<void> _run() async {
    final q = ctrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final r = await Yes24Api(store.yes24Key).search(q);
      setState(() => results = r);
    } catch (e) {
      setState(() => error = kIsWeb ? '웹 미리보기에서는 YES24 검색이 막혀 있어요. 휴대폰 앱에서 사용해 주세요.' : e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (!Yes24Api.available(store.yes24Key)) return const NeedKeyCard();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: ctrl,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _run(),
            decoration: InputDecoration(
              hintText: '책 제목이나 지은이',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward_rounded, color: PB.primary), onPressed: _run),
            ),
          ),
          const SizedBox(height: 12),
          if (loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: PB.primary))),
          if (error != null) Padding(padding: const EdgeInsets.all(16), child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: PB.primary))),
          if (!loading && results != null && results!.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Text('찾는 책이 없어요. 다른 낱말로 찾아보거나 직접 입력해 주세요.', textAlign: TextAlign.center, style: TextStyle(color: PB.muted))),
          if (!loading && results != null)
            for (final b in results!) _ResultTile(book: b, added: widget.isAdded?.call(b) ?? false, onTap: () => widget.onPick(b)),
          if (results != null && results!.isNotEmpty)
            const Padding(padding: EdgeInsets.all(12), child: Text(kYes24Credit, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: PB.muted))),
        ]);
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Yes24Book book;
  final bool added;
  final VoidCallback onTap;
  const _ResultTile({required this.book, required this.added, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: added ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            BookCover(title: book.title, url: book.cover, seed: book.title.hashCode, width: 52, height: 74),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text([book.author, book.publisher].where((e) => e.isNotEmpty).join(' · '),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: PB.muted)),
                if (book.pages > 0 || (book.publishDate ?? '').isNotEmpty)
                  Text([if (book.pages > 0) '${book.pages}쪽', if ((book.publishDate ?? '').isNotEmpty) book.publishDate!].join(' · '),
                      style: const TextStyle(fontSize: 12, color: PB.muted)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: added
                  ? const Text('담김', style: TextStyle(color: PB.muted, fontSize: 12))
                  : const Icon(Icons.add_circle_outline_rounded, color: PB.primary),
            ),
          ]),
        ),
      );
}

/// 책 뒷면 바코드(ISBN) 찍기
class BarcodeView extends StatefulWidget {
  final ValueChanged<Yes24Book> onPick;
  const BarcodeView({super.key, required this.onPick});
  @override
  State<BarcodeView> createState() => _BarcodeViewState();
}

class _BarcodeViewState extends State<BarcodeView> {
  final ctrl = MobileScannerController(formats: const [BarcodeFormat.ean13], detectionSpeed: DetectionSpeed.noDuplicates);
  bool busy = false;
  String? message;

  Future<void> _onDetect(BarcodeCapture cap) async {
    if (busy) return;
    final raw = cap.barcodes.map((b) => b.rawValue).whereType<String>().firstWhere(
          (v) => RegExp(r'^97[89]\d{10}$').hasMatch(v),
          orElse: () => '',
        );
    if (raw.isEmpty) return;
    setState(() {
      busy = true;
      message = 'ISBN $raw 을(를) 찾는 중…';
    });
    try {
      final b = await Yes24Api(store.yes24Key).byIsbn(raw);
      if (b == null) {
        setState(() => message = 'YES24에 없는 책이에요 (ISBN $raw). 직접 입력해 주세요.');
      } else {
        await ctrl.stop();
        widget.onPick(b);
        if (mounted) setState(() => message = null);
        await ctrl.start();
      }
    } catch (e) {
      setState(() => message = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Yes24Api.available(store.yes24Key)) return const NeedKeyCard();
    if (kIsWeb) {
      return const Padding(padding: EdgeInsets.all(24), child: Text('바코드는 휴대폰 앱에서 쓸 수 있어요.', textAlign: TextAlign.center));
    }
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 300,
          child: Stack(fit: StackFit.expand, children: [
            MobileScanner(
              controller: ctrl,
              onDetect: _onDetect,
              errorBuilder: (context, e) => Container(
                color: Colors.black,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(20),
                child: Text('카메라를 열 수 없어요.\n설정에서 카메라 권한을 허용해 주세요.\n(${e.errorCode.name})',
                    textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
              ),
            ),
            Center(
              child: Container(
                width: 250, height: 120,
                decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2.5), borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 14),
      Text(message ?? '책 뒷면의 바코드를 네모 안에 맞춰 주세요.', textAlign: TextAlign.center, style: const TextStyle(color: PB.muted)),
      const SizedBox(height: 6),
      const Text(kYes24Credit, style: TextStyle(fontSize: 11, color: PB.muted)),
    ]);
  }
}
