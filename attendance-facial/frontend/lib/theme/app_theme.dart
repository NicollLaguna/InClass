import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Paleta ─────────────────────────────────────────────
  static const Color background    = Color(0xFF0A0A0A);
  static const Color surface       = Color(0xFF161B22);
  static const Color surfaceLight  = Color(0xFF1E2530);
  static const Color primary       = Color(0xFF1E90FF);
  static const Color secondary     = Color(0xFF00D4FF);
  static const Color success       = Color(0xFF00E676);
  static const Color warning       = Color(0xFFFFB300);
  static const Color error         = Color(0xFFFF5252);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B7C3);
  static const Color border        = Color(0xFF2D3748);

  // ── Gradientes ─────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E90FF), Color(0xFF00D4FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF161B22), Color(0xFF1A2030)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF0A0A0A), Color(0xFF0D1117), Color(0xFF0A0F1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Glow ───────────────────────────────────────────────
  static List<BoxShadow> glowBlue = [
    BoxShadow(color: primary.withValues(alpha:0.35), blurRadius: 20, spreadRadius: 0),
    BoxShadow(color: primary.withValues(alpha:0.15), blurRadius: 40, spreadRadius: 5),
  ];

  static List<BoxShadow> glowCyan = [
    BoxShadow(color: secondary.withValues(alpha:0.3), blurRadius: 20, spreadRadius: 0),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha:0.4), blurRadius: 16, offset: const Offset(0, 4)),
  ];

  // ── Decoraciones ───────────────────────────────────────
  static BoxDecoration cardDecoration({Color? borderColor}) => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: borderColor ?? border, width: 1),
    boxShadow: cardShadow,
  );

  static BoxDecoration glowCardDecoration = BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: primary.withValues(alpha:0.4), width: 1),
    boxShadow: glowBlue,
  );

  // ── Theme ──────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return const Color(0xFF2D3748);
          return primary;
        }),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevation: WidgetStateProperty.all(0),
        overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha:0.1)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      hintStyle: GoogleFonts.poppins(color: textSecondary, fontSize: 14),
      labelStyle: GoogleFonts.poppins(color: textSecondary, fontSize: 14),
      prefixIconColor: textSecondary,
      suffixIconColor: textSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surface,
      contentTextStyle: GoogleFonts.poppins(color: textPrimary, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      iconColor: primary,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceLight,
      labelStyle: GoogleFonts.poppins(color: textPrimary, fontSize: 12),
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
    iconTheme: const IconThemeData(color: primary),
  );
}

// ── Botón con gradiente ─────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final IconData? icon;
  final String? loadingText;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 52,
    this.icon,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: disabled
                ? const LinearGradient(colors: [Color(0xFF2D3748), Color(0xFF2D3748)])
                : AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: disabled ? [] : AppTheme.glowBlue,
          ),
          child: InkWell(
            onTap: (isLoading || disabled) ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withValues(alpha: 0.15),
            child: Container(
              constraints: BoxConstraints(minHeight: height),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: isLoading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        if (loadingText != null && loadingText!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            loadingText!,
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Text(label,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            )),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
