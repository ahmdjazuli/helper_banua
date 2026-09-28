// lib/widgets/app_background.dart
import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final double opacity; // Atur transparansi agar teks di atasnya tetap terbaca

  const AppBackground({
    super.key,
    required this.child,
    this.opacity = 0.4, // Opacity kecil cocok untuk pattern doodle hitam putih
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Gambar Background Terpusat
        Positioned.fill(
          child: Opacity(
            opacity: opacity,
            child: Image.asset(
              'assets/img/wallpaper.png', // Path gambar doodle kamu
              fit: BoxFit.cover,
              repeat: ImageRepeat.repeat, // Jika gambar berbentuk pattern berulang
            ),
          ),
        ),
        // 2. Konten Halaman Utama
        Positioned.fill(child: child),
      ],
    );
  }
}