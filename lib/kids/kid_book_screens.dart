import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AreaChips extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  const AreaChips({super.key, required this.selected, required this.onToggle});
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final a in kMindAreas)
          FilterChip(
            label: Text(a),
            selected: selected.contains(a),
            selectedColor: PB.primarySoft,
            checkmarkColor: PB.primary,
            backgroundColor: PB.card,
            onSelected: (_) => onToggle(a),
          ),
      ]);
}

class KidBookEditScreen extends StatefulWidget {
  final bool toRead;
  const KidBookEditScreen({super.key, this.toRead = false});
  @override
  State<KidBookEditScreen> createState() => _KidBookEditScreenState();
}

class _KidBookEditScreenState extends State<KidBookEditScreen> {
  final title = TextEditingController();
  final author = TextEditingController();
  late bool toRead = widget.toRead;
  final areas = <String>{};
  String? coverPath;

  @override
  Widget build(BuildContext context) {
    final child = store.selectedChild;
    return Scaffold(
      appBar: AppBar(title: Text('${child?.name ?? ''} 책장에 담기')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () async {
              final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
              if (x != null) setState(() => coverPath = x.path);
            },
            child: coverPath != null
                ? BookCover(title: title.text, path: coverPath, url: coverPath, seed: 0, width: 96, height: 126)
                : Container(
                    width: 96, height: 126,
                    decoration: BoxDecoration(color: PB.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: PB.line)),
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
              TextField(controller: title, decoration: const InputDecoration(labelText: '제목 *')),
              const SizedBox(height: 10),
              TextField(controller: author, decoration: const InputDecoration(labelText: '지은이')),
            ]),
          ),
        ]),
        const SizedBox(height: 20),
        SegmentedButton<bool>(
          segments: const [ButtonSegment(value: false, label: Text('읽은 책')), ButtonSegment(value: true, label: Text('읽어 볼 책'))],
          selected: {toRead},
          onSelectionChanged: (s) => setState(() => toRead = s.first),
        ),
        const SizedBox(height: 20),
        const Text('이 책이 닿는 마음 (머릿속 영역)', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('고른 영역이 성장 탭의 머릿속 지도를 물들여요.', style: TextStyle(fontSize: 12, color: PB.muted)),
        const SizedBox(height: 10),
        AreaChips(selected: areas, onToggle: (a) => setState(() => areas.contains(a) ? areas.remove(a) : areas.add(a))),
        const SizedBox(height: 28),
        FilledButton(
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: () {
            if (title.text.trim().isEmpty) return;
            store.addKidBook(KidBook(
              id: newId(),
              childId: store.selectedChildId!,
              title: title.text.trim(),
              author: author.text.trim(),
              coverPath: coverPath,
              toRead: toRead,
              readDates: toRead ? [] : [DateTime.now()],
              areas: areas,
            ));
            Navigator.pop(context);
          },
          child: const Text('책장에 꽂기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class KidBookDetailScreen extends StatelessWidget {
  final String id;
  const KidBookDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.kidBooks.where((k) => k.id == id);
        if (list.isEmpty) return const Scaffold(body: SizedBox());
        final k = list.first;
        final dates = k.readDates.toList()..sort((a, b) => b.compareTo(a));
        return Scaffold(
          appBar: AppBar(actions: [
            IconButton(
              icon: Icon(k.liked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined, color: PB.primary),
              onPressed: () {
                k.liked = !k.liked;
                store.updateKidBook(k);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                Navigator.pop(context);
                store.deleteKidBook(k);
              },
            ),
          ]),
          body: ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 40), children: [
            Center(child: BookCover(title: k.title, author: k.author, url: k.coverUrl, path: k.coverPath, seed: k.colorSeed, width: 150, height: 196, radius: 8)),
            const SizedBox(height: 16),
            Text(k.title, textAlign: TextAlign.center, style: const TextStyle(fontFamily: PB.serif, fontSize: 22, fontWeight: FontWeight.w700)),
            Text(k.author, textAlign: TextAlign.center, style: const TextStyle(color: PB.muted)),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () {
                store.readAgain(k);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${k.readCount}번째로 읽었어요!')));
              },
              icon: const Icon(Icons.sync_rounded),
              label: Text(k.toRead ? '오늘 읽었어요' : '또 읽었어요  (지금 ${k.readCount}번)', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 24),
            const Text('이 책이 닿는 마음', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            AreaChips(
              selected: k.areas,
              onToggle: (a) {
                k.areas.contains(a) ? k.areas.remove(a) : k.areas.add(a);
                store.updateKidBook(k);
              },
            ),
            const SizedBox(height: 24),
            if (dates.isNotEmpty) ...[
              const Text('읽은 날', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final d in dates)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    const Icon(Icons.circle, size: 6, color: PB.primary),
                    const SizedBox(width: 10),
                    Text(fmtDate(d)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        k.readDates.remove(d);
                        store.updateKidBook(k);
                      },
                      child: const Icon(Icons.close, size: 16, color: PB.muted),
                    ),
                  ]),
                ),
            ],
          ]),
        );
      },
    );
  }
}
