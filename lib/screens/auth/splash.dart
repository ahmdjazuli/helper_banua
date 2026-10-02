import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import '../navigation/navigasi_utama.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      // Cek apakah pengguna sudah login di Firebase Auth
      User? currentUser = FirebaseAuth.instance.currentUser;

      Widget targetScreen = (currentUser != null && currentUser.emailVerified)
          ? const MainNavigationScreen()
          : const LoginScreen();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND KUNING
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFFFD600),
          ),

          // 2. LAYER KUBAH HITAM
          CustomPaint(
            size: Size.infinite,
            painter: DomeShadowPainter(),
          ),

          // 3. KONTEN
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 200),

                  // Logo Box
                  Container(
                    width: 140,
                    height: 140,
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/img/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.shape_line_rounded,
                              size: 64,
                              color: Color(0xFFFFD600),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Teks "HELPER"
                  const Text(
                    'HELPER',
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 1.0,
                      height: 1.0,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Teks "BANUA"
                  const Text(
                    'BANUA',
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFD600),
                      letterSpacing: 1.0,
                      height: 1.0,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Tagline
                  const Text(
                    'MITRA ANDALAN MASALAH ANDA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DomeShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double curveHeight = size.height * 0.48;

    Path getDomePath(double offsetTop) {
      Path path = Path();
      path.moveTo(0, curveHeight + 35 + offsetTop);
      path.quadraticBezierTo(
        size.width / 2,
        curveHeight - 45 + offsetTop,
        size.width,
        curveHeight + 35 + offsetTop,
      );
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      return path;
    }

    Paint baseBlackPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawPath(getDomePath(35), baseBlackPaint);

    List<double> blurOffsets = [35, 15, 65, -5, -5];
    List<double> blurOpacities = [0.90, 0.55, 0.30, 0.10, 0.12];
    List<double> blurRadii = [6.0, 12.0, 18.0, 26.0, 36.0];

    for (int i = 0; i < blurOffsets.length; i++) {
      Paint softEdgePaint = Paint()
        ..color = Colors.black.withValues(alpha: blurOpacities[i])
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadii[i]);

      canvas.drawPath(getDomePath(blurOffsets[i]), softEdgePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}