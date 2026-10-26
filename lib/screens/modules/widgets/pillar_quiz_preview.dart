import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/app_models.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/leaf_decor.dart';
import '../theory_quiz_screen.dart';
import '../practice_quiz_screen.dart';

/// Halaman Pilar 4: Kartu Kuis Teori & Kuis Praktikum AI On-Device
class PillarQuizPreview extends StatelessWidget {
  final ModuleModel module;
  final bool isDark;

  const PillarQuizPreview({
    super.key,
    required this.module,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kuis Modul',
            style: AppTheme.satoshi(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),

          // Hero Banner: Selamat mengerjakan!
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B341B), Color(0xFF7E4A25)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat\nmengerjakan!',
                        style: AppTheme.satoshi(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Uji pemahaman dan hasil karyamu di sini untuk menyelesaikan modul dan melihat sejauh mana kamu mengenali motif batik ini.',
                        style: AppTheme.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                top: -22,
                right: -22,
                child: LeafDecor(
                  asset: 'assets/images/leaf/onboarding_utama_3.png',
                  size: 90,
                  angle: -0.15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Card 1: Kuis Teori
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: module.quizDone
                        ? AppTheme.primary.withValues(alpha: 0.4)
                        : (isDark ? AppTheme.darkBorder : const Color(0xFFF0EAE1)),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: module.quizDone
                          ? AppTheme.primary.withValues(alpha: 0.05)
                          : AppTheme.primary.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: module.quizDone
                                  ? AppTheme.primary.withValues(alpha: 0.12)
                                  : (isDark ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.accentGold.withValues(alpha: 0.2)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              size: 24,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Kuis Teori',
                                    style: AppTheme.satoshi(
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF2C1810),
                                    ),
                                    maxLines: 2,
                                  ),
                                ),
                                if (module.quizDone || module.quizScore != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                    decoration: BoxDecoration(
                                      color: module.quizDone
                                          ? AppTheme.primary.withValues(alpha: 0.12)
                                          : const Color(0xFFF57C00).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: module.quizDone
                                            ? AppTheme.primary.withValues(alpha: 0.35)
                                            : const Color(0xFFF57C00).withValues(alpha: 0.35),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          module.quizDone ? Icons.check_circle_rounded : Icons.auto_awesome,
                                          size: 13,
                                          color: module.quizDone ? AppTheme.primary : const Color(0xFFF57C00),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Nilai: ${module.quizScore ?? 100}',
                                          style: AppTheme.satoshi(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: module.quizDone
                                                ? (isDark ? AppTheme.secondaryLight : AppTheme.primaryDark)
                                                : const Color(0xFFE65100),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Uji wawasan mendalam mengenai pakem, sejarah, dan makna ornamen.',
                        style: AppTheme.inter(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : AppTheme.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TheoryQuizScreen(module: module)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: module.quizDone ? Colors.transparent : AppTheme.primary,
                          foregroundColor: module.quizDone ? AppTheme.primary : Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: module.quizDone ? AppTheme.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              module.quizDone ? Icons.refresh_rounded : Icons.play_arrow_rounded,
                              size: 18,
                              color: module.quizDone
                                  ? (isDark ? AppTheme.secondaryLight : AppTheme.primary)
                                  : Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              module.quizDone ? 'Kerjakan Ulang' : 'Mulai Kuis',
                              style: AppTheme.satoshi(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                                color: module.quizDone
                                    ? (isDark ? AppTheme.secondaryLight : AppTheme.primary)
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                bottom: -26,
                right: -22,
                child: LeafDecor(
                  asset: 'assets/images/leaf/onboarding_leaf_04_sulur_kiri.png',
                  size: 72,
                  angle: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Card 2: Kuis Praktik
          Builder(
            builder: (context) {
              final provider = context.watch<AppProvider>();
              final latestAttempt = provider.scanHistories
                  .where((s) => s.moduleId == module.id && s.scanType == 'kuismu')
                  .firstOrNull;
              final bool hasAttempted = module.practiceDone ||
                  module.practiceScore != null ||
                  latestAttempt != null;
              final int? practiceScore = module.practiceScore ??
                  (latestAttempt != null
                      ? (latestAttempt.score * 100).round()
                      : null);
              final bool isPassed =
                  module.practiceDone || (latestAttempt?.passed ?? false) || (practiceScore != null && practiceScore >= module.passingScore);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: hasAttempted
                            ? (isPassed
                                ? const Color(0xFF2E7D32).withValues(alpha: 0.4)
                                : const Color(0xFFF57C00).withValues(alpha: 0.4))
                            : (isDark ? AppTheme.darkBorder : const Color(0xFFF0EAE1)),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: hasAttempted
                              ? (isPassed
                                  ? const Color(0xFF2E7D32).withValues(alpha: 0.05)
                                  : const Color(0xFFF57C00).withValues(alpha: 0.05))
                              : AppTheme.primary.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: hasAttempted
                                      ? (isPassed
                                          ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                                          : const Color(0xFFF57C00).withValues(alpha: 0.12))
                                      : (isDark
                                          ? AppTheme.primary.withValues(alpha: 0.3)
                                          : AppTheme.accentGold.withValues(alpha: 0.2)),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.brush_rounded,
                                  size: 24,
                                  color: hasAttempted
                                      ? (isPassed
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFFF57C00))
                                      : AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Kuis Praktik',
                                        style: AppTheme.satoshi(
                                          fontSize: 17.5,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.white : const Color(0xFF2C1810),
                                        ),
                                        maxLines: 2,
                                      ),
                                    ),
                                    if (hasAttempted) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                        decoration: BoxDecoration(
                                          color: isPassed
                                              ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                                              : const Color(0xFFF57C00).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isPassed
                                                ? const Color(0xFF2E7D32).withValues(alpha: 0.35)
                                                : const Color(0xFFF57C00).withValues(alpha: 0.35),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isPassed ? Icons.check_circle_outline : Icons.auto_awesome,
                                              size: 13,
                                              color: isPassed ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Nilai: ${practiceScore ?? 100}%',
                                              style: AppTheme.satoshi(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isPassed ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Gambarlah motif batik ini, lalu pindai hasil karyamu untuk melihat seberapa mirip dengan aslinya.',
                            style: AppTheme.inter(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : AppTheme.textSecondary,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (hasAttempted) ...[
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PracticeQuizScreen(
                                      module: module,
                                      initialShowResult: true,
                                      historyData: latestAttempt,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5A3416),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.history_rounded, size: 18, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Riwayat Praktikum',
                                    style: AppTheme.satoshi(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PracticeQuizScreen(
                                      module: module,
                                      initialShowResult: false,
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                side: const BorderSide(color: Color(0xFFD4A373), width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.replay_rounded, size: 16, color: isDark ? const Color(0xFFD4A373) : const Color(0xFF5A3416)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Coba Praktik Lagi',
                                    style: AppTheme.satoshi(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                      color: isDark ? const Color(0xFFD4A373) : const Color(0xFF5A3416),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
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
                                minimumSize: const Size.fromHeight(50),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mulai Praktik',
                                    style: AppTheme.satoshi(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: -26,
                    right: -22,
                    child: LeafDecor(
                      asset: 'assets/images/leaf/onboarding_leaf_04_sulur_kiri.png',
                      size: 72,
                      angle: 0.4,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
