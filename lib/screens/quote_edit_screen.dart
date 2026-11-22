import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';

class QuoteEditScreen extends StatefulWidget {
  final String? bookId;
  final Quote? quote;
  const QuoteEditScreen({super.key, this.bookId, this.quote});
  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  late final text = TextEditingController(text: widget.quote?.text ?? '');
  late final thought = TextEditingController(text: widget.quote?.thought ?? '');
  late final page = TextEditingController(text: widget.quote?.page?.toString() ?? '');
  late String? bookId = widget.quote?.bookId ?? widget.bookId;

  void _save() {
    if (text.text.trim().isEmpty || bookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('책과 문장을 입력해 주세요.')));
      return;
    }
    final q = widget.quote;
    if (q == null) {
      store.addQuote(Quote(id: newId(), bookId: bookId!, text: text.text.trim(), thought: thought.text.trim(), page: int.tryParse(page.text)));
    } else {
      q
        ..bookId = bookId!
        ..text = text.text.trim()
        ..thought = thought.text.trim()
        ..page = int.tryParse(page.text);
      store.updateQuote(q);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final books = store.books;
    return Scaffold(
      appBar: AppBar(title: Text(widget.quote == null ? '문장 담기' : '문장 고치기')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
        DropdownButtonFormField<String>(
          initialValue: bookId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '책'),
          dropdownColor: PB.card,
          items: [for (final b in books) DropdownMenuItem(value: b.id, child: Text(b.title, overflow: TextOverflow.ellipsis))],
          onChanged: (v) => setState(() => bookId = v),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('사진에서 글자를 읽어 오는 기능은 다음 업데이트에서 열려요.'))),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('사진으로 문장 담기 (준비 중)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: text,
          maxLines: 6,
          minLines: 4,
          style: const TextStyle(fontFamily: PB.serif, height: 1.6),
          decoration: const InputDecoration(labelText: '마음에 담은 문장', alignLabelWithHint: true),
        ),
        const SizedBox(height: 12),
        TextField(controller: page, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '쪽 (선택)')),
        const SizedBox(height: 12),
        TextField(
          controller: thought,
          maxLines: 4,
          minLines: 2,
          style: const TextStyle(fontFamily: PB.pen, fontSize: 21),
          decoration: const InputDecoration(labelText: '그때의 내 생각', alignLabelWithHint: true),
        ),
        const SizedBox(height: 8),
        const Row(children: [
          Icon(Icons.lock_outline, size: 15, color: PB.muted),
          SizedBox(width: 6),
          Text('담은 문장과 생각은 이 휴대폰에만 저장되고 나에게만 보여요.', style: TextStyle(fontSize: 12, color: PB.muted)),
        ]),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: _save,
          child: const Text('담기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
