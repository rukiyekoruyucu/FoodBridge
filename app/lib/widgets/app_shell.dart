import 'dart:ui';
import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  final bool withBackground;
  final bool safeArea;

  const AppShell({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.withBackground = true,
    this.safeArea = true,
  });

  // Marka yeşili (bar, CTA, seçili icon)
  static const Color kGreen = Color(0xFF16A34A);

  // Light mod yazı rengi: siyah değil, koyu yeşil (premium kontrast)
  static const Color kInk = Color(0xFF0B3D1F);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: safeArea ? SafeArea(child: body) : body,
    );

    if (!withBackground) return scaffold;

    // ✅ Light: temiz beyaz + varsayılan metin/ikon koyu yeşil
    if (!isDark) {
      return Container(
        color: Colors.white,
        child: DefaultTextStyle(
          style: const TextStyle(color: kInk),
          child: IconTheme(
            data: const IconThemeData(color: kInk),
            child: scaffold,
          ),
        ),
      );
    }

    // ✅ Dark: aurora background
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
          colors: [Color(0xFF060A12), Color(0xFF0B1D2A), Color(0xFF061A14)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: -120,
            top: -160,
            child: _GlowBlob(size: 320, color: Color(0xFF2C7CFF)),
          ),
          const Positioned(
            right: -120,
            top: -120,
            child: _GlowBlob(size: 300, color: Color(0xFF00D3A7)),
          ),
          const Positioned(
            left: -80,
            bottom: -160,
            child: _GlowBlob(size: 340, color: Color(0xFF8A5CFF)),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.25,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ),
          scaffold,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class GlassBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final double radius;

  const GlassBar({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(14, 0, 14, 14),
    this.radius = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: GlassBox(
        radius: radius,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: child,
      ),
    );
  }
}

class GlassBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const GlassBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dark: glass
    // Light: düz beyaz yüzey (temiz/pro)
    final bg = isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white;

    final border = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.06);

    final blur = isDark ? 18.0 : 0.0;

    final fg = isDark ? Colors.white : AppShell.kInk;
    final icon = isDark ? Colors.white : AppShell.kInk;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: DefaultTextStyle(
            style: TextStyle(color: fg),
            child: IconTheme(
              data: IconThemeData(color: icon),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

PreferredSizeWidget buildGlassAppBar({
  required BuildContext context,
  required String title,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // Light: yeşil bar + beyaz yazı
  // Dark: transparan + blur + beyaz yazı
  final bg = isDark ? Colors.transparent : AppShell.kGreen;
  const fg = Colors.white;

  return AppBar(
    backgroundColor: bg,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    title: const SizedBox.shrink(), // titleSpacing’i korumak için
    flexibleSpace: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    ),
    iconTheme: const IconThemeData(color: fg),
    actionsIconTheme: const IconThemeData(color: fg),
    actions: actions,
    bottom: bottom,
  );
}
