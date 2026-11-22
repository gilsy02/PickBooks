import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'kids/kids_shell.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/records_screen.dart';
import 'screens/shelf_screen.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.load();
  runApp(const PickBooksApp());
}

class PickBooksApp extends StatelessWidget {
  const PickBooksApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '픽북스',
        debugShowCheckedModeBanner: false,
        theme: PB.theme(),
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ListenableBuilder(
          listenable: store,
          builder: (_, __) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: store.kidsMode ? const KidsShell(key: ValueKey('kids')) : const PickShell(key: ValueKey('pick')),
          ),
        ),
      );
}

class PickShell extends StatefulWidget {
  const PickShell({super.key});
  @override
  State<PickShell> createState() => _PickShellState();
}

class _PickShellState extends State<PickShell> {
  int tab = 1;
  @override
  Widget build(BuildContext context) {
    final pages = [const HomeScreen(), const ShelfScreen(), const RecordsScreen(), const ProfileScreen()];
    return Scaffold(
      body: SafeArea(bottom: false, child: IndexedStack(index: tab, children: pages)),
      bottomNavigationBar: PickNavBar(
        index: tab,
        onTap: (i) => setState(() => tab = i),
        items: const [
          (Icons.home_outlined, Icons.home_rounded, '홈'),
          (Icons.class_outlined, Icons.class_rounded, '내 서재'),
          (Icons.bookmark_border_rounded, Icons.bookmark_rounded, '기록'),
          (Icons.person_outline_rounded, Icons.person_rounded, '프로필'),
        ],
      ),
    );
  }
}

class PickNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<(IconData, IconData, String)> items;
  final Color background;
  const PickNavBar({super.key, required this.index, required this.onTap, required this.items, this.background = const Color(0xFFF2E9DE)});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: background, border: const Border(top: BorderSide(color: PB.line))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(i == index ? items[i].$2 : items[i].$1, color: i == index ? PB.primary : PB.muted, size: 27),
                    const SizedBox(height: 3),
                    Text(items[i].$3,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: i == index ? PB.primary : PB.muted)),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
