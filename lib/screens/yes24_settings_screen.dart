import 'package:flutter/material.dart';
import '../services/yes24.dart';
import '../store.dart';
import '../theme.dart';

class Yes24SettingsScreen extends StatefulWidget {
  const Yes24SettingsScreen({super.key});
  @override
  State<Yes24SettingsScreen> createState() => _Yes24SettingsScreenState();
}

class _Yes24SettingsScreenState extends State<Yes24SettingsScreen> {
  late final ctrl = TextEditingController(text: store.yes24Key);
  bool hide = true;
  String? result;
  bool testing = false;

  Future<void> _test() async {
    setState(() {
      testing = true;
      result = null;
    });
    try {
      final r = await Yes24Api(ctrl.text).search('데미안');
      setState(() => result = r.isEmpty ? '연결은 됐지만 결과가 비어 있어요.' : '연결됐어요! 「${r.first.title}」 등 ${r.length}권을 찾았어요.');
    } catch (e) {
      setState(() => result = e.toString());
    } finally {
      setState(() => testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('도서 검색 설정')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('YES24 Open API 키', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text(
          '1. developers.yes24.com 에 YES24 계정으로 로그인\n2. API Key 발급 메뉴에서 약관 동의 후 즉시 발급\n3. 받은 키를 아래에 붙여 넣기',
          style: TextStyle(color: PB.muted, height: 1.6),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: ctrl,
          obscureText: hide,
          decoration: InputDecoration(
            labelText: 'API 키',
            suffixIcon: IconButton(icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => hide = !hide)),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton(onPressed: testing ? null : _test, child: Text(testing ? '확인 중…' : '연결 확인')),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: () {
                store.setYes24Key(ctrl.text);
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ),
        ]),
        if (result != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(result!, style: const TextStyle(color: PB.primary))),
        const SizedBox(height: 24),
        const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.lock_outline, size: 16, color: PB.muted),
          SizedBox(width: 6),
          Expanded(
            child: Text('키는 이 휴대폰에만 저장되고 내보내기 파일에도 들어가지 않아요. 하루 2만 회까지 무료예요.',
                style: TextStyle(fontSize: 12, color: PB.muted, height: 1.5)),
          ),
        ]),
      ]),
    );
  }
}
