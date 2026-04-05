import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Paleta CaféTrace ─────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2D5016);
  static const Color primaryLight = Color(0xFF4A7C2A);
  static const Color primaryDark = Color(0xFF1A3A0A);
  static const Color accent = Color(0xFFC8A84B);
  static const Color accentLight = Color(0xFFF0E4B8);
  static const Color admin = Color(0xFF1A3A5C);
  static const Color surface = Color(0xFFFFFCF7);
  static const Color background = Color(0xFFF5F0E8);
  static const Color border = Color(0xFFD8D0BC);
  static const Color textMuted = Color(0xFF6B6B5A);

  // ── Estado de lotes ──────────────────────────────────────────────────────
  static const Color estadoActivo = Color(0xFF2E7D32);
  static const Color estadoPendiente = Color(0xFFE65100);
  static const Color estadoCompletado = Color(0xFF1A3A5C);
  static const Color estadoInactivo = Color(0xFF9E9E9E);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: accent,
      surface: surface,
      background: background,
      onPrimary: Colors.white,
      onSecondary: primaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: background,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(color: textMuted, fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFFB0A898), fontSize: 13),
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 0,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: accentLight,
        labelStyle: const TextStyle(fontSize: 12, color: primaryDark),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }

  // ── Color helpers ────────────────────────────────────────────────────────
  static Color estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
      case 'en proceso':
        return estadoActivo;
      case 'pendiente':
      case 'fermentación':
      case 'secado':
        return estadoPendiente;
      case 'completado':
      case 'almacenamiento':
        return estadoCompletado;
      default:
        return estadoInactivo;
    }
  }

  static Color estadoBg(String estado) {
    return estadoColor(estado).withOpacity(0.1);
  }
}
