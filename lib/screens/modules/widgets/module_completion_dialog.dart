import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/app_models.dart';

/// Menampilkan dialog perayaan tuntas modul beserta rekap nilai teori & praktikum
void showModuleCompletionDialog(BuildContext context, ModuleModel module) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE4BA73), Color(0xFFD49B45)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 38,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Selamat! Modul Tuntas',
                textAlign: TextAlign.center,
                style: AppTheme.satoshi(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF2C1810),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kamu telah berhasil mempelajari dan menyelesaikan seluruh evaluasi pada ${module.title}.',
                textAlign: TextAlign.center,
                style: AppTheme.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBackground : const Color(0xFFF9F6F0),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : const Color(0xFFEFE7DA),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Kuis Teori
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.school_rounded, size: 13, color: AppTheme.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Kuis Teori',
                                      style: AppTheme.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${module.quizScore ?? 100}',
                                  style: AppTheme.satoshi(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Garis Pemisah 1
                      Container(
                        width: 1.5,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF4A3C2F) : const Color(0xFFC7B8A5),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),

                      // Kuis Praktik
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.brush_rounded, size: 13, color: Color(0xFFE65100)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Kuis Praktik',
                                      style: AppTheme.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${module.practiceScore ?? 100}%',
                                  style: AppTheme.satoshi(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFE65100),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Garis Pemisah 2
                      Container(
                        width: 1.5,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF4A3C2F) : const Color(0xFFC7B8A5),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),

                      // Progres
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_rounded, size: 13, color: Color(0xFF5A3416)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Progres',
                                      style: AppTheme.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '100%',
                                  style: AppTheme.satoshi(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF5A3416),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A3416),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Selesai & Kembali ke Modul',
                        style: AppTheme.satoshi(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
