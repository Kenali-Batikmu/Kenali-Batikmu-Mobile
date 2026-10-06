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
      'title': 'Kenali Warisan\nLeluhur Nusantara',
      'subtitle':
          'Jelajahi filosofi mendalam dan nilai historis di balik setiap guratan motif batik klasik dari keraton hingga pesisiran.',
      'tag': 'EDUKASI BUDAYA',
      'icon': '🏛️',
    },
    {
      'title': 'Belajar Anatomi\n& Teknik Canting',
      'subtitle':
          'Pahami struktur ragam hias, kemiringan sudut 45 derajat lereng, ornamen mlinjon, hingga cecek dengan modul terstruktur.',
      'tag': 'MODUL PRAKTIK',
      'icon': '✍️',
    },
    {
      'title': 'Deteksi & Uji\nHasil Gambar Mandiri',
      'subtitle':
          'Gunakan kamera pintar untuk mengenali kain batik nusantara serta menguji kecocokan hasil latihan gambarmu secara instan.',
      'tag': 'TEKNOLOGI AI ON-DEVICE',
      'icon': '🔍',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_stories, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'KENALI BATIKMU',
                        style: AppTheme.satoshi(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: () => _navigateToLogin(),
                      child: Text(
                        'Lewati',
                        style: AppTheme.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration Container
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.border, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              item['icon']!,
                              style: const TextStyle(fontSize: 68),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Badge Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item['tag']!,
                            style: AppTheme.satoshi(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Title
                        Text(
                          item['title']!,
                          textAlign: TextAlign.center,
                          style: AppTheme.satoshi(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Subtitle
                        Text(
                          item['subtitle']!,
                          textAlign: TextAlign.center,
                          style: AppTheme.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.45,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppTheme.primary : AppTheme.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Button Next / Start
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _navigateToLogin();
                      }
                    },
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Mulai Eksplorasi' : 'Lanjut',
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

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}
