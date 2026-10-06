import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import 'theory_quiz_screen.dart';
import 'practice_quiz_screen.dart';

class QuizChoiceScreen extends StatelessWidget {
  final ModuleModel module;

  const QuizChoiceScreen({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          color: isDark ? Colors.white : AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'KENALI BATIKMU',
              style: AppTheme.satoshi(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.primary),
            ),
            Text(
              'Detail Modul',
              style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kuis Modul',
              style: AppTheme.satoshi(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            // Hero Banner Sesuai PDF Page 7
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4A2F1B),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat\nmengerjakan!',
                    style: AppTheme.satoshi(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Selesaikan materi hari ini untuk meningkatkan keahlian canting dan membuka lencana baru.',
                    style: AppTheme.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 1: Teori Sesuai PDF Page 7
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Icon Box
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF7F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Center(
                          child: Icon(Icons.menu_book, color: Color(0xFF5A3416), size: 26),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.schedule, size: 12, color: AppTheme.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    '45 Menit',
                                    style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Teori',
                              style: AppTheme.satoshi(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.borderLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Nilai Teori: 100%',
                          style: AppTheme.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TheoryQuizScreen(module: module)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A3416),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          minimumSize: const Size(130, 42),
                        ),
                        child: const Row(
                          children: [
                            Text('Mulai Kuis Teori'),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 2: Praktik Sesuai PDF Page 7
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Icon Box
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF7F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Center(
                          child: Icon(Icons.draw, color: Color(0xFF5A3416), size: 26),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Praktik',
                        style: AppTheme.satoshi(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.borderLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.accentGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Belum Dilakukan',
                              style: AppTheme.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PracticeQuizScreen(module: module)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A3416),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          minimumSize: const Size(130, 42),
                        ),
                        child: const Row(
                          children: [
                            Text('Mulai Kuis Praktik'),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Bottom Navigation Stepper Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Row(
                  children: List.generate(4, (index) {
                    final isActive = index == 3;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.accentGold : (isDark ? AppTheme.darkBorder : AppTheme.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 50),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
