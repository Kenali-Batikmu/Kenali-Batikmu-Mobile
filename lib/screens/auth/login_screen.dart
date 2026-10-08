import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../dashboard/main_navigation_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'sekar@batikmu.id');
  final _passwordController = TextEditingController(text: 'Batikmu123#');
  bool _obscurePassword = true;
  bool _rememberMe = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final success = await provider.login(
      _emailController.text,
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Email atau kata sandi salah',
            style: AppTheme.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFBF8F3),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Image Ilustrasi Studio Batik (Penuh 100% Layar Tanpa Terpotong)
            Positioned.fill(
              child: Image.asset(
                'assets/images/login_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            // 2. Ambient Warm Light Gradient Overlay untuk Kontras & Kelembutan
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      const Color(0xFFFBF8F3).withValues(alpha: 0.15),
                      const Color(0xFFFBF8F3).withValues(alpha: 0.40),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Konten Utama Layar Login (Full Height & Scrollable)
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      22,
                      14,
                      22,
                      viewInsetsBottom > 0
                          ? viewInsetsBottom + 20
                          : (bottomPadding > 0 ? bottomPadding + 12 : 24),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 28,
                      ),
                      child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Icon App Header (Rounded Box Cokelat dengan Motif Canting & Star Sparkle)
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Motif Daun/Canting Cantik
                          Image.asset(
                            'assets/images/logo_1.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                          // Sparkle Bintang 4 Titik di Pojok Kanan Atas
                          const Positioned(
                            top: 6,
                            right: 10,
                            child: Icon(
                              Icons.auto_awesome,
                              size: 20,
                              color: Color.fromARGB(255, 243, 162, 0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divider Header "BATIK LEARN"
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFF7D6C5D)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'K E N A L I   B A T I K M U',
                            style: AppTheme.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.8,
                              color: const Color(0xFF4A3828),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFF7D6C5D)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Judul Utama dengan Hiasan Daun Emas Kiri & Kanan
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Daun Hiasan Kiri
                        Positioned(
                          left: 5,
                          top: 18,
                          child: Transform.rotate(
                            angle: -0.6, // Putar kemiringannya (bisa ganti angka sesuai selera)
                            child: Transform.flip(
                              flipX: true, // Balik arah horizontal (kiri <-> kanan)
                              child: Image.asset(
                                'assets/images/leafe_1.png',
                                width: 50,
                                height: 50,
                              ),
                            ),
                          ),
                        ),
                        // Daun Hiasan Kanan
                        Positioned(
                          right: 5,
                          top: 18,
                          child: Transform.rotate(
                            angle: 0.6,
                            child: Image.asset(
                              'assets/images/leafe_1.png',
                              width: 50,
                              height: 50,
                            ),
                          ),
                        ),

                        // Teks Judul Besar (Noto Serif)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'J',
                                  style: AppTheme.notoSerif(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFC07F35),
                                    height: 1.15,
                                  ),
                                ),
                                TextSpan(
                                  text: 'elajahi\n',
                                  style: AppTheme.notoSerif(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2C1B10),
                                    height: 1.15,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Keindahan\n',
                                  style: AppTheme.notoSerif(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2C1B10),
                                    height: 1.15,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Batik Nusantara',
                                  style: AppTheme.notoSerif(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2C1B10),
                                    height: 1.15,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Subtitle Penjelasan
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Belajar, menggambar, dan kenali motif batik dengan teknologi deteksi realtime di genggamanmu.',
                        textAlign: TextAlign.center,
                        style: AppTheme.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF55473C),
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Glassmorphism Card Form Login
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 26,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFDF8)
                                .withValues(alpha: 0.93),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.95),
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4A2E1B)
                                    .withValues(alpha: 0.08),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.7),
                                blurRadius: 8,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Label Email
                              Text(
                                'Email',
                                style: AppTheme.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2C221A),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Form Field Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: AppTheme.plusJakartaSans(
                                  fontSize: 14,
                                  color: const Color(0xFF2C221A),
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF7F3EA),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 15,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.mail_outline_rounded,
                                    color: Color(0xFF8A7D70),
                                    size: 21,
                                  ),
                                  hintText: 'nama@email.com',
                                  hintStyle: AppTheme.plusJakartaSans(
                                    color: const Color(0xFFA09486),
                                    fontSize: 13.5,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE8DFC8),
                                      width: 1.2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE8DFC8),
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primary,
                                      width: 1.6,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email tidak boleh kosong';
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                      .hasMatch(value)) {
                                    return 'Format email tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Label Kata Sandi + Lupa Kata Sandi
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Kata Sandi',
                                    style: AppTheme.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2C221A),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Tautan pemulihan kata sandi dikirim jika email terdaftar.',
                                            style: AppTheme.plusJakartaSans(),
                                          ),
                                          backgroundColor: AppTheme.primary,
                                        ),
                                      );
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Lupa Kata Sandi?',
                                          style: AppTheme.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF7A4B29),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 14,
                                          color: Color(0xFF7A4B29),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Form Field Kata Sandi
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: AppTheme.plusJakartaSans(
                                  fontSize: 14,
                                  color: const Color(0xFF2C221A),
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF7F3EA),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 15,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Color(0xFF8A7D70),
                                    size: 21,
                                  ),
                                  hintText: 'Masukkan kata sandi',
                                  hintStyle: AppTheme.plusJakartaSans(
                                    color: const Color(0xFFA09486),
                                    fontSize: 13.5,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF8A7D70),
                                      size: 21,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      );
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE8DFC8),
                                      width: 1.2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE8DFC8),
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primary,
                                      width: 1.6,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Kata sandi tidak boleh kosong';
                                  }
                                  if (value.length < 8) {
                                    return 'Kata sandi minimal 8 karakter';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Checkbox "Ingat saya di perangkat ini"
                              GestureDetector(
                                onTap: () {
                                  setState(() => _rememberMe = !_rememberMe);
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: _rememberMe
                                            ? AppTheme.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _rememberMe
                                              ? AppTheme.primary
                                              : const Color(0xFFB5A99B),
                                          width: 1.6,
                                        ),
                                      ),
                                      child: _rememberMe
                                          ? const Icon(
                                              Icons.check,
                                              size: 15,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Ingat saya di perangkat ini',
                                      style: AppTheme.plusJakartaSans(
                                        fontSize: 13.5,
                                        color: const Color(0xFF4A3E34),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Tombol Masuk dengan Gradasi Batik & Watermark Ornamen
                              Container(
                                width: double.infinity,
                                height: 54,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF552A10),
                                      Color(0xFF7A431E),
                                      Color(0xFF8F5327),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF552A10)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(28),
                                    onTap: provider.isLoading
                                        ? null
                                        : _handleLogin,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(28),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Watermark Ornamen Batik di sisi kanan tombol
                                          Positioned(
                                            right: -10,
                                            top: -10,
                                            bottom: -10,
                                            child: Opacity(
                                              opacity: 0.16,
                                              child: Image.asset(
                                                'assets/images/bunga_1.png',
                                                width: 90,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const SizedBox.shrink(),
                                              ),
                                            ),
                                          ),

                                          // Konten Tombol
                                          provider.isLoading
                                              ? const SizedBox(
                                                  height: 22,
                                                  width: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.2,
                                                      ),
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.login_rounded,
                                                      size: 20,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Masuk',
                                                      style:
                                                          AppTheme.plusJakartaSans(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                            letterSpacing: 0.3,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                    const SizedBox(height: 24),

                    // Tautan Daftar Akun Baru
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Belum punya akun? ',
                          style: AppTheme.plusJakartaSans(
                            fontSize: 13.5,
                            color: const Color(0xFF5C4E42),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Daftar',
                                style: AppTheme.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF7A4B29),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Color(0xFF7A4B29),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Divider Ornamen Batik Bunga Cantik
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFF9E8E7E)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Image.asset(
                            'assets/images/bunga_2.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFF9E8E7E)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tagline Platform Footer
                    Center(
                      child: Text(
                        'PLATFORM EDUKASI BATIK NUSANTARA',
                        style: AppTheme.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                          color: const Color(0xFF7A6A5C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  ],
),
),
);
  }
}
