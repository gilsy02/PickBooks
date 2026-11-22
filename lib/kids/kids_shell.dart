import 'package:flutter/material.dart';
import '../main.dart';
import 'kids_growth_screen.dart';
import 'kids_recommend_screen.dart';
import 'kids_shelf_screen.dart';

class KidsShell extends StatefulWidget {
  const KidsShell({super.key});
  @override
  State<KidsShell> createState() => _KidsShellState();
}

class _KidsShellState extends State<KidsShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: tab, children: const [KidsShelfScreen(), KidsRecommendScreen(), KidsGrowthScreen()]),
      ),
      bottomNavigationBar: PickNavBar(
        index: tab,
        background: const Color(0xFFF1DCDA),
        onTap: (i) => setState(() => tab = i),
        items: const [
          (Icons.auto_stories_outlined, Icons.auto_stories_rounded, '책장'),
          (Icons.explore_outlined, Icons.explore_rounded, '추천'),
          (Icons.eco_outlined, Icons.eco_rounded, '성장'),
        ],
      ),
    );
  }
}
