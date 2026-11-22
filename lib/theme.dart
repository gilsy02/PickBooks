import 'package:flutter/material.dart';

class PB {
  static const bg = Color(0xFFF6EFE6);
  static const card = Color(0xFFFFFBF6);
  static const primary = Color(0xFF8E1B2C);
  static const primarySoft = Color(0xFFF3E3E1);
  static const ink = Color(0xFF2B2420);
  static const muted = Color(0xFF8A7F76);
  static const line = Color(0xFFE6DCCF);
  static const woodFrame = Color(0xFFC79566);
  static const woodBack = Color(0xFFE9CFA9);
  static const woodPlank = Color(0xFFD6AE80);
  static const kidsNav = Color(0xFFF1DCDA);

  static const serif = 'Gowun';
  static const pen = 'Pen';
  static const brush = 'Brush';

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, surface: bg),
      scaffoldBackgroundColor: bg,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        centerTitle: true,
        titleTextStyle: TextStyle(fontFamily: serif, fontSize: 19, fontWeight: FontWeight.w700, color: ink),
      ),
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary)),
      ),
    );
  }
}
