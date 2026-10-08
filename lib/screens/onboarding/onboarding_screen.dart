import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'tag': 'KENALI BUDAYA',
      'title': 'Kenali Warisan\nLeluhur Nusantara',
      'subtitle': 'Jelajahi filosofi mendalam dan nilai historis di balik setiap guratan motif batik klasik dari keraton hingga pesisiran.',
    },
    {
      'tag': 'BELAJAR & MENGGAMBAR',
      'title': 'Belajar Ragam &\nGoresan Canting',
      'subtitle': 'Pelajari pakem ragam hias motif nusantara dan asah kreativitasmu menggambar pola batik secara interaktif.',
    },
    {
      'tag': 'DETEKSI REALTIME',
      'title': 'Pindai Cerdas \n Deteksi Realtime',
      'subtitle': 'Arahkan kamera ke kain batikmu dan kenali jenis motif, asal daerah, serta maknanya secara instan dengan kecerdasan buatan.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F4EB),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full Screen Background Motif & Texture (Memenuhi 100% Layar Tanpa Celah)
            Positioned.fill(
              child: Image.asset(
                'assets/images/onboarding_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            // 2. Main Content
            SafeArea(
              child: Column(
                children: [
                  // Top Bar: Logo & Lewati Button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Lewati Button (Hanya tampil di slide awal)
                        if (_currentPage < _pages.length-1)
                          GestureDetector(
                            onTap: _navigateToLogin,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text(
                                'Lewati',
                                style: AppTheme.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6E5D50),
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // Center Slides: Hero Illustration + Tag + Title + Subtitle
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        final item = _pages[index];
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final availableHeight = constraints.maxHeight;
                            final isTallScreen = availableHeight > 560;

                            // Spacing dinamis proporsional mengikuti rasio layar (20:9 vs 18:9 vs 16:9)
                            final heroBottomSpacing = isTallScreen
                                ? (availableHeight * 0.035).clamp(16.0, 30.0)
                                : 12.0;
                            final tagBottomSpacing = isTallScreen
                                ? (availableHeight * 0.022).clamp(12.0, 18.0)
                                : 10.0;
                            final titleBottomSpacing = isTallScreen
                                ? (availableHeight * 0.018).clamp(10.0, 16.0)
                                : 8.0;

                            return SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: availableHeight,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 6),

                                    // Hero Composite Illustration (dengan FittedBox agar tidak overflow di layar kecil)
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: _buildHeroIllustration(index),
                                    ),

                                    SizedBox(height: heroBottomSpacing),

                                    // Category Tag Pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1E4D3),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFDFCFBE),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome,
                                            size: 11,
                                            color: Color(0xFF8B5326),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            item['tag']!,
                                            style: AppTheme.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.8,
                                              color: const Color(0xFF8B5326),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.auto_awesome,
                                            size: 11,
                                            color: Color(0xFF8B5326),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: tagBottomSpacing),

                                    // Main Title
                                    Text(
                                      item['title']!,
                                      textAlign: TextAlign.center,
                                      style: AppTheme.notoSerif(
                                        fontSize: isTallScreen ? 27 : 24,
                                        fontWeight: FontWeight.bold,
                                        height: 1.25,
                                        color: const Color(0xFF2C1810),
                                      ),
                                    ),

                                    SizedBox(height: titleBottomSpacing),

                                    // Subtitle
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        item['subtitle']!,
                                        textAlign: TextAlign.center,
                                        style: AppTheme.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w400,
                                          height: 1.55,
                                          color: const Color(0xFF6B584C),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Bottom Navigation: Indicator Dots & Action Button
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      6,
                      24,
                      bottomInset > 0 ? bottomInset + 8 : 26,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dots Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 3.5,
                              ),
                              width: _currentPage == index ? 26 : 6,
                              height: 5.5,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? const Color(0xFF5E3418)
                                    : const Color(0xFFDCCFBE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Pill Action Button
                        GestureDetector(
                          onTap: () {
                            if (_currentPage < _pages.length-1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeInOutCubic,
                              );
                            } else {
                              _navigateToLogin();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6E3C1B), Color(0xFF5A2E12)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF633719)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentPage == _pages.length - 1
                                      ? 'Mulai Sekarang'
                                      : 'Lanjut',
                                  style: AppTheme.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Composite Hero Artwork dengan desain dalam & luar lingkaran yang rapi dan terukur
  Widget _buildHeroIllustration(int index) {
    switch (index) {
      case 0:
        return _buildHeroSlide1();
      case 1:
        return _buildHeroSlide2();
      case 2:
      default:
        return _buildHeroSlide3();
    }
  }

  /// Slide 1: Kenali Budaya
  Widget _buildHeroSlide1() {
    return SizedBox(
      width: 330,
      height: 285,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // === [1] DI DALAM LINGKARAN (Sun Disc & Motif Utama) ===
          _buildSunDisc(
            innerChild: Stack(
              alignment: Alignment.center,
              children: [
                // Gambar utama slide 1
                Center(
                  child: Image.asset(
                    'assets/images/onboarding_slide_1.png',
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),

          // Ranting Amber meluas ke kanan atas luar lingkaran
          Positioned(
            top: 75,
            right: 12,
            child: Transform.rotate(
              angle: 1.30,
              child: Image.asset(
                'assets/images/leaf/onboarding_leaf_01_ranting_amber.png',
                width: 74,
                height: 94,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Ranting Hijau meluas ke kanan luar lingkaran
          Positioned(
            top: 5,
            right: 22,
            child: Transform.flip(
              flipX: true,
              child: Transform.rotate(
                angle: 25,
                child: Image.asset(
                  'assets/images/leaf/onboarding_leaf_02_ranting_hijau.png',
                  width: 70,
                  height: 90,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Bunga Roset Kecil mengambang di luar kiri lingkaran
          Positioned(
            top: 118,
            left: 18,
            child: Image.asset(
              'assets/images/leaf/onboarding_leaf_03_bunga_roset.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
          ),

          // Kelopak & Dedaunan Melayang di Luar Lingkaran
          // Kiri atas
          Positioned(
            top: 45,
            left: 80,
            child: Transform.rotate(
              angle: -0.45,
              child: Image.asset(
                'assets/images/leafe_1.png',
                width: 18,
                height: 18,
              ),
            ),
          ),
          // Jauh kiri
          Positioned(
            top: 135,
            left: 12,
            child: Transform.rotate(
              angle: -0.85,
              child: Image.asset(
                'assets/images/leafe_2.png',
                width: 20,
                height: 20,
              ),
            ),
          ),
          // Kiri bawah
          Positioned(
            bottom: 24,
            left: 45,
            child: Transform.rotate(
              angle: 0.6,
              child: Image.asset(
                'assets/images/leafe_1.png',
                width: 18,
                height: 18,
              ),
            ),
          ),
          // Kanan atas
          Positioned(
            top: 55,
            right: 2,
            child: Transform.rotate(
              angle: 0.4,
              child: Image.asset(
                'assets/images/leafe_1.png',
                width: 17,
                height: 17,
              ),
            ),
          ),
          // Kanan bawah
          Positioned(
            bottom: 28,
            right: 68,
            child: Transform.rotate(
              angle: -0.5,
              child: Image.asset(
                'assets/images/leafe_2.png',
                width: 18,
                height: 18,
              ),
            ),
          ),

          // Sparkle Bintang Emas Berkilau di Tepi Luar Lingkaran
          const Positioned(
            top: 25,
            right: 90,
            child: Icon(Icons.auto_awesome, size: 14, color: Color(0xFFD49B45)),
          ),
          const Positioned(
            top: 105,
            left: 55,
            child: Icon(Icons.auto_awesome, size: 10, color: Color(0xFFE4BA73)),
          ),
        ],
      ),
    );
  }

  /// Slide 2: Belajar & Menggambar
  Widget _buildHeroSlide2() {
    return SizedBox(
      width: 330,
      height: 285,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // === [1] DI DALAM LINGKARAN ===
          _buildSunDisc(
            innerChild: Stack(
              alignment: Alignment.center,
              children: [
                // Gambar Utama Slide 2
                Positioned(
                  top: 8,
                  left: 1,
                  child: Transform.rotate(
                    angle: 0.2,
                    child: Image.asset(
                      'assets/images/onboarding_slide_2.png',
                      width: 190,
                      height: 190,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ornamen Sulur Daun Kiri menjalar ke luar lingkaran
          Positioned(
            top: 30,
            left: 18,
            child: Transform.rotate(
              angle: -0.38,
              child: Image.asset(
                'assets/images/leaf/onboarding_leaf_04_sulur_kiri.png',
                width: 70,
                height: 82,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Ranting Daun Kanan tegak di luar lingkaran
          Positioned(
            top: 48,
            right: 18,
            child: Transform.rotate(
              angle: 0.45,
              child: Image.asset(
                'assets/images/leaf/onboarding_utama_3.png',
                width: 72,
                height: 88,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Daun Melayang
          Positioned(
            top: 45,
            right: 12,
            child: Transform.rotate(
              angle: 0.5,
              child: Image.asset(
                'assets/images/leafe_1.png',
                width: 18,
                height: 18,
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 45,
            child: Transform.rotate(
              angle: -0.4,
              child: Image.asset(
                'assets/images/leafe_2.png',
                width: 18,
                height: 18,
              ),
            ),
          ),
          Positioned(
            top: 130,
            left: 15,
            child: Transform.rotate(
              angle: 0.7,
              child: Image.asset(
                'assets/images/leafe_1.png',
                width: 16,
                height: 16,
              ),
            ),
          ),

          // Sparkle Emas
          const Positioned(
            top: 25,
            left: 90,
            child: Icon(Icons.auto_awesome, size: 13, color: Color(0xFFD49B45)),
          ),
          const Positioned(
            bottom: 50,
            left: 30,
            child: Icon(Icons.auto_awesome, size: 10, color: Color(0xFFE4BA73)),
          ),
        ],
      ),
    );
  }

  /// Slide 3: Deteksi Realtime
  Widget _buildHeroSlide3() {
    return SizedBox(
      width: 330,
      height: 285,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // === [1] DI DALAM LINGKARAN ===
          _buildSunDisc(
            innerChild: Stack(
              alignment: Alignment.center,
              children: [
                // Bunga Teratai Mekar Penuh di tengah lingkaran
                Center(
                  child: Image.asset(
                    'assets/images/onboarding_slide_3.png',
                    width: 175,
                    height: 175,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),

          // Ornamen Daun Batik meluas ke kanan atas luar lingkaran
          Positioned(
            top: 20,
            right: 18,
            child: Transform.rotate(
              angle: 0.35,
              child: Image.asset(
                'assets/images/bunga_1.png',
                width: 72,
                height: 90,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // // Ranting Hijau di kanan luar lingkaran
          Positioned(
            top: 75,
            right: 10,
            child: Transform.rotate(
              angle: 0.6,
              child: Image.asset(
                'assets/images/leaf/onboarding_leaf_09.png',
                width: 68,
                height: 88,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // // Ornamen Floral Nusantara mengambang di luar kiri lingkaran
          Positioned(
            top: 110,
            left: 16,
            child: Image.asset(
              'assets/images/leaf/onboarding_leaf_07_floral_nusantara.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
          ),

          // Daun Melayang
          Positioned(
            top: 45,
            left: 75,
            child: Transform.rotate(
              angle: -0.5,
              child: Image.asset(
                'assets/images/leafe_1.png',
                width: 19,
                height: 19,
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 40,
            child: Transform.rotate(
              angle: 0.6,
              child: Image.asset(
                'assets/images/leafe_2.png',
                width: 18,
                height: 18,
              ),
            ),
          ),
          Positioned(
            top: 65,
            right: 2,
            child: Transform.rotate(
              angle: 0.35,
              child: Image.asset(
                'assets/images/leafe_1.png',
                width: 17,
                height: 17,
              ),
            ),
          ),

          // Sparkle Emas
          const Positioned(
            top: 25,
            right: 90,
            child: Icon(Icons.auto_awesome, size: 14, color: Color(0xFFD49B45)),
          ),
          const Positioned(
            top: 95,
            left: 55,
            child: Icon(Icons.auto_awesome, size: 11, color: Color(0xFFE4BA73)),
          ),
        ],
      ),
    );
  }

  /// Lingkaran Sun Halo Disc dengan Garis Konsentris Emas & Konten Internal (Di Dalam Lingkaran)
  Widget _buildSunDisc({Widget? innerChild}) {
    return Container(
      width: 236,
      height: 236,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFFFF9ED),
            const Color(0xFFF9E9D3).withValues(alpha: 0.9),
            const Color(0xFFF3DDBB).withValues(alpha: 0.25),
          ],
          stops: const [0.35, 0.75, 1.0],
        ),
        border: Border.all(
          color: const Color(0xFFDFCFBE).withValues(alpha: 0.85),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD49B45).withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 186,
          height: 186,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFDFCFBE).withValues(alpha: 0.45),
              width: 0.9,
            ),
          ),
          child: innerChild,
        ),
      ),
    );
  }
}
