import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../services/yes24.dart';
import '../widgets/book_finder.dart';
import '../widgets/common.dart';

/// 책 담기: 검색 / 바코드 / 직접 입력
class AddBookScreen extends StatefulWidget {
  final BookStatus initialStatus;
  const AddBookScreen({super.key, this.initialStatus = BookStatus.want});
  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  late int tab = store.yes24Key.isEmpty ? 2 : 0;
  final title = TextEditingController();
  final author = TextEditingController();
  final publisher = TextEditingController();
  final pages = TextEditingController();
  final category = TextEditingController();
  late BookStatus status = widget.initialStatus;
  String? coverPath;

  Future<void> _pickCover() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (x != null) setState(() => coverPath = x.path);
  }

  Future<void> _pickedFromApi(Yes24Book y) async {
    if (store.hasIsbn(y.isbn13)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('「${y.title}」은(는) 이미 서재에 있어요.')));
      return;
    }
    final chosen = await showModalBottomSheet<BookStatus>(
      context: context,
      backgroundColor: PB.card,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              BookCover(title: y.title, url: y.cover, seed: y.title.hashCode, width: 70, height: 100),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(y.title, style: const TextStyle(fontFamily: PB.serif, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text([y.author, y.publisher].where((e) => e.isNotEmpty).join(' · '), style: const TextStyle(color: PB.muted)),
                  if (y.pages > 0) Text('${y.pages}쪽', style: const TextStyle(color: PB.muted)),
                ]),
              ),
            ]),
            const SizedBox(height: 18),
            const Align(alignment: Alignment.centerLeft, child: Text('어느 칸에 꽂을까요?', style: TextStyle(fontWeight: FontWeight.w700))),
            const SizedBox(height: 10),
            Row(children: [
              for (final s in BookStatus.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilledButton.tonal(onPressed: () => Navigator.pop(ctx, s), child: Text(s.label, style: const TextStyle(fontSize: 13))),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    store.addBook(Book(
      id: newId(),
      title: y.title,
      author: y.author,
      publisher: y.publisher,
      coverUrl: y.cover,
      spineUrl: y.sideCover,
      link: y.link,
      isbn: y.isbn13,
      category: y.category,
      totalPages: y.pages,
      currentPage: chosen == BookStatus.done ? y.pages : 0,
      status: chosen,
      finishedAt: chosen == BookStatus.done ? DateTime.now() : null,
    ));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('「${y.title}」을(를) ${chosen.label} 칸에 꽂았어요.')));
  }

  void _save() {
    if (title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력해 주세요.')));
      return;
    }
    final total = int.tryParse(pages.text.trim()) ?? 0;
    store.addBook(Book(
      id: newId(),
      title: title.text.trim(),
      author: author.text.trim(),
      publisher: publisher.text.trim(),
      category: category.text.trim(),
      totalPages: total,
      currentPage: status == BookStatus.done ? total : 0,
      status: status,
      coverPath: coverPath,
      finishedAt: status == BookStatus.done ? DateTime.now() : null,
    ));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('「${title.text.trim()}」을(를) ${status.label} 칸에 꽂았어요.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('책 담기')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
        Segmented(
          items: const [(Icons.search, '검색'), (Icons.qr_code_scanner, '바코드'), (Icons.edit_outlined, '직접 입력')],
          index: tab,
          onChanged: (i) => setState(() => tab = i),
        ),
        const SizedBox(height: 20),
        if (tab == 0)
          BookSearchView(onPick: _pickedFromApi, isAdded: (b) => store.hasIsbn(b.isbn13))
        else if (tab == 1)
          BarcodeView(onPick: _pickedFromApi)
        else
          ..._manual(),
      ]),
    );
  }

  List<Widget> _manual() => [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: _pickCover,
            child: coverPath != null
                ? BookCover(title: title.text, path: coverPath, url: coverPath, seed: 0, width: 96, height: 136)
                : Container(
                    width: 96,
                    height: 136,
                    decoration: BoxDecoration(color: PB.card, borderRadius: BorderRadius.circular(6), border: Border.all(color: PB.line)),
                    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_photo_alternate_outlined, color: PB.muted),
                      SizedBox(height: 6),
                      Text('표지 사진', style: TextStyle(fontSize: 12, color: PB.muted)),
                    ]),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: '제목 *'), onChanged: (_) => setState(() {})),
              const SizedBox(height: 10),
              TextField(controller: author, decoration: const InputDecoration(labelText: '지은이')),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        TextField(controller: publisher, decoration: const InputDecoration(labelText: '출판사')),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: pages, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '전체 쪽수'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: category, decoration: const InputDecoration(labelText: '분류 (소설, 에세이…)'))),
        ]),
        const SizedBox(height: 20),
        const Text('어느 칸에 꽂을까요?', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [
          for (final s in BookStatus.values)
            ChoiceChip(
              label: Text(s.label),
              selected: status == s,
              selectedColor: PB.primary,
              labelStyle: TextStyle(color: status == s ? Colors.white : PB.ink, fontWeight: FontWeight.w600),
              backgroundColor: PB.card,
              showCheckmark: false,
              onSelected: (_) => setState(() => status = s),
            ),
        ]),
        const SizedBox(height: 28),
        FilledButton(
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: _save,
          child: const Text('서재에 꽂기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ];
}
