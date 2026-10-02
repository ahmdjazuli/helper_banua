import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:helper_banua/screens/navigation/navigasi_utama.dart';
import 'package:helper_banua/screens/auth/register.dart';
import '../../widgets/auth_dialogs.dart';
import '../../widgets/custom_input_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Counter untuk melacak percobaan password salah
  int _wrongPasswordCount = 0;
  static const int _maxWrongAttempts = 3;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    String emailInput = _emailController.text.trim();
    String passwordInput = _passwordController.text.trim();

    if (emailInput.isEmpty || passwordInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password wajib diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailInput,
        password: passwordInput,
      );

      User? user = userCredential.user;

      // Jika berhasil login, reset counter percobaan salah
      _wrongPasswordCount = 0;

      if (user != null && !user.emailVerified) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange[800],
            duration: const Duration(seconds: 6),
            content: const Text(
              'Email Anda belum diverifikasi! Silakan cek Inbox/Spam email Anda.',
            ),
            action: SnackBarAction(
              label: 'Kirim Ulang',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  await user.sendEmailVerification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text('Link verifikasi berhasil dikirim ulang!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal mengirim ulang: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );

        await FirebaseAuth.instance.signOut();
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Akun tidak ditemukan! Mohon periksa kembali email Anda.'),
            ),
          );
        }
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        // Increment counter password salah
        _wrongPasswordCount++;

        if (_wrongPasswordCount >= _maxWrongAttempts) {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            AuthDialogs.showTooManyWrongPasswordDialog(
              context: context,
              wrongPasswordCount: _wrongPasswordCount,
              emailText: emailInput,
              onResetSuccess: () {
                setState(() {
                  _wrongPasswordCount = 0;
                });
              },
            );
          }
        } else {
          int remaining = _maxWrongAttempts - _wrongPasswordCount;
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red,
                content: Text(
                  'Password salah atau email tidak sesuai! Sisa percobaan: $remaining.',
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } else if (e.code == 'invalid-email') {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Format email tidak valid!'),
            ),
          );
        }
      } else if (e.code == 'too-many-requests') {
        if (mounted) {
          AuthDialogs.showTooManyWrongPasswordDialog(
            context: context,
            wrongPasswordCount: _wrongPasswordCount,
            emailText: emailInput,
            onResetSuccess: () {
              setState(() {
                _wrongPasswordCount = 0;
              });
            },
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text('Login gagal: ${e.message ?? e.code}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.standard(
        scopes: ['email', 'profile'],
      );

      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      User? user = userCredential.user;

      if (user != null) {
        DocumentReference userDocRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);

        DocumentSnapshot userSnapshot = await userDocRef.get();

        if (!userSnapshot.exists) {
          await userDocRef.set({
            'uid': user.uid,
            'nama': user.displayName ?? '',
            'email': user.email ?? '',
            'phone': user.phoneNumber ?? '',
            'photoUrl': user.photoURL ?? '',
            'roles': ['user'],
            'isMitraActive': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          await userDocRef.set({
            'nama': user.displayName ?? '',
            'email': user.email ?? '',
            'photoUrl': user.photoURL ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
        ),
      );
    } catch (e) {
      debugPrint('Error Google Sign-In: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal Login Google: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFFFD600),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: DomeShadowPainter(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Pencarian\nMudah & Aman',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Temukan jasa pertukangan, kebersihan dll\ndengan mudah dan aman langsung dari aplikasi.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: 110,
                      height: 110,
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
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/img/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.shape_line_rounded,
                                size: 54,
                                color: Color(0xFFFFD600),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'HELPER',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: 1.0,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'BANUA',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFD600),
                        letterSpacing: 1.0,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Input Field Email
                    CustomInputField(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      hintText: 'Masukkan email Anda',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    // Input Field Password
                    CustomInputField(
                      icon: Icons.lock_outline,
                      label: 'Password',
                      hintText: 'Masukkan password Anda',
                      controller: _passwordController,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.black54,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          AuthDialogs.showResetPasswordDialog(
                            context: context,
                            initialEmail: _emailController.text.trim(),
                            onSuccess: () {
                              setState(() {
                                _wrongPasswordCount = 0;
                              });
                            },
                          );
                        },
                        child: const Text(
                          'Lupa Password ?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tombol Login Email
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _loginWithEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD600),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      'Atau',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tombol Login dengan Google
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                              height: 20,
                              width: 20,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.g_mobiledata,
                                size: 28,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Login dengan Google',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Belum punya akun ? ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Daftar disini',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFD600),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
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
    double curveHeight = size.height * 0.44;

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