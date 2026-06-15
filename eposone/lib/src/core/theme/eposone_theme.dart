import 'package:flutter/material.dart';

/// Colores oficiales EPOSOne / EasyTech Services.
abstract final class EposBrand {
  static const Color orange = Color(0xFFF58220);
  static const Color orangeDark = Color(0xFFE06A10);
  static const Color navy = Color(0xFF1A3A5C);
  static const Color navyDark = Color(0xFF0F2744);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2B3C);
  static const Color textSecondary = Color(0xFF6B7C8F);
  static const Color divider = Color(0xFFE2E8F0);

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.light(
      primary: orange,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFE8D4),
      onPrimaryContainer: navyDark,
      secondary: navy,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFDCE6F2),
      onSecondaryContainer: navyDark,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: background,
      outline: divider,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: navy,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: surface,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: orange.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: const BorderSide(color: navy),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: orange),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: orange, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      chipTheme: ChipThemeData(
        selectedColor: orange.withValues(alpha: 0.15),
        labelStyle: const TextStyle(color: textPrimary),
        side: const BorderSide(color: divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: orange),
      dividerTheme: const DividerThemeData(color: divider),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
      ),
    );
  }
}

/// Logo EPOSOne: "EPOS" navy + "One" naranja.
class EposOneLogo extends StatelessWidget {
  final double fontSize;
  final FontWeight fontWeight;

  const EposOneLogo({
    super.key,
    this.fontSize = 32,
    this.fontWeight = FontWeight.w800,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, letterSpacing: -0.5),
        children: const [
          TextSpan(text: 'EPOS', style: TextStyle(color: EposBrand.navy)),
          TextSpan(text: 'One', style: TextStyle(color: EposBrand.orange)),
        ],
      ),
    );
  }
}

/// Ícono de marca — logo oficial (monitor + carrito).
class EposBrandIcon extends StatelessWidget {
  final double size;

  const EposBrandIcon({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/app_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _fallback(size),
    );
  }

  Widget _fallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: EposBrand.navy,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(Icons.shopping_cart_outlined, color: EposBrand.orange, size: size * 0.45),
    );
  }
}

/// AppBar secundaria (pantallas internas POS con fondo claro).
class EposLightAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;

  const EposLightAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 72 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: EposBrand.navy,
      foregroundColor: Colors.white,
      leading: leading,
      actions: actions,
      title: subtitle != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
              ],
            )
          : Text(title),
    );
  }
}

/// Botón principal naranja estilo "Cobrar" / "Pagar".
class EposPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? minWidth;

  const EposPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    final child = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label),
            ],
          )
        : Text(label);

    return SizedBox(
      width: minWidth,
      height: 48,
      child: FilledButton(onPressed: onPressed, child: child),
    );
  }
}
