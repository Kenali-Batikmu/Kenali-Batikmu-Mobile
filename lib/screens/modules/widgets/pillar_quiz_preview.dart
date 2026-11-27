import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/app_models.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/leaf_decor.dart';
import '../theory_quiz_screen.dart';
import '../practice_quiz_screen.dart';

/// Halaman Pilar 4: Kartu Kuis Teori & Kuis Praktikum AI On-Device
class PillarQuizPreview extends StatefulWidget {
  final ModuleModel module;
  final bool isDark;

  const PillarQuizPreview({
    super.key,
    required this.module,
    required this.isDark,
  });

  @override
  State<PillarQuizPreview> createState() => _PillarQuizPreviewState();
}

class _PillarQuizPreviewState extends State<PillarQuizPreview>
    with WidgetsBindingObserver {
  final AudioPlayer _clickPlayer = AudioPlayer();
  Future<void> _clickOperations = Future<void>.value();
  final AudioPlayer _returnEffectPlayer = AudioPlayer();
  Future<void> _returnEffectOperations = Future<void>.value();
  Future<void> _returnEffectSetup = Future<void>.value();
  final AudioPlayer _navigationEffectPlayer = AudioPlayer();
  Future<void> _navigationEffectOperations = Future<void>.value();
  Future<void> _navigationEffectSetup = Future<void>.value();
  Future<void> _lifecycleOperations = Future<void>.value();
  Completer<void>? _activeClickPlayback;
  bool _isDisposed = false;
  bool _isOpeningPracticeQuiz = false;
  bool _isAppActive = true;
  bool _clickPausedForLifecycle = false;
  bool _returnEffectPausedForLifecycle = false;
  bool _navigationEffectPausedForLifecycle = false;

  ModuleModel get module => widget.module;
  bool get isDark => widget.isDark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clickOperations = _clickPlayer
        .setAudioContext(
          AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
              .build(),
        )
        .then((_) => _clickPlayer.setReleaseMode(ReleaseMode.stop))
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Gagal menyiapkan efek klik kuis: $error');
        });
    _returnEffectSetup = _returnEffectPlayer
        .setAudioContext(
          AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
              .build(),
        )
        .then((_) => _returnEffectPlayer.setReleaseMode(ReleaseMode.stop))
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Gagal menyiapkan efek kembali kuis: $error');
        });
    _returnEffectOperations = _returnEffectSetup;
    _navigationEffectSetup = _navigationEffectPlayer
        .setAudioContext(
          AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
              .build(),
        )
        .then((_) => _navigationEffectPlayer.setReleaseMode(ReleaseMode.stop))
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Gagal menyiapkan efek navigasi kuis: $error');
        });
    _navigationEffectOperations = _navigationEffectSetup;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppActive = state == AppLifecycleState.resumed;
    _lifecycleOperations = _lifecycleOperations
        .then((_) async {
          if (_isDisposed) return;
          await _returnEffectSetup;
          if (!_isAppActive && _clickPlayer.state == PlayerState.playing) {
            await _clickPlayer.pause();
            _clickPausedForLifecycle = true;
          } else if (_isAppActive && _clickPausedForLifecycle) {
            await _clickPlayer.resume();
            _clickPausedForLifecycle = false;
          }
          if (!_isAppActive &&
              _returnEffectPlayer.state == PlayerState.playing) {
            await _returnEffectPlayer.pause();
            _returnEffectPausedForLifecycle = true;
          } else if (_isAppActive && _returnEffectPausedForLifecycle) {
            await _returnEffectPlayer.resume();
            _returnEffectPausedForLifecycle = false;
          }
          await _navigationEffectSetup;
          if (!_isAppActive &&
              _navigationEffectPlayer.state == PlayerState.playing) {
            await _navigationEffectPlayer.pause();
            _navigationEffectPausedForLifecycle = true;
          } else if (_isAppActive && _navigationEffectPausedForLifecycle) {
            await _navigationEffectPlayer.resume();
            _navigationEffectPausedForLifecycle = false;
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Gagal mengelola lifecycle efek klik kuis: $error');
        });
  }

  Future<void> _playClickSound() {
    _clickOperations = _clickOperations
        .then((_) async {
          if (!_isAppActive) return;
          if (_clickPlayer.state != PlayerState.stopped) {
            await _clickPlayer.stop();
          }
          if (!_isAppActive) return;

          final completed = Completer<void>();
          _activeClickPlayback = completed;
          final completionSubscription = _clickPlayer.onPlayerComplete.listen(
            (_) {
              if (!completed.isCompleted) completed.complete();
            },
            onError: (Object error) {
              if (!completed.isCompleted) completed.completeError(error);
            },
          );
          try {
            await _clickPlayer.play(AssetSource('audio/click.mp3'));
            if (!_isAppActive && _clickPlayer.state == PlayerState.playing) {
              await _clickPlayer.pause();
              _clickPausedForLifecycle = true;
            }
            await completed.future.timeout(const Duration(seconds: 5));
          } finally {
            await completionSubscription.cancel();
            if (identical(_activeClickPlayback, completed)) {
              _activeClickPlayback = null;
            }
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Gagal memutar efek klik kuis: $error');
        });
    return _clickOperations;
  }

  void _playReturnSounds() {
    unawaited(_playClickSound());
    _playNavigationEffectSound();
  }

  void _playEffectSound() {
    _returnEffectOperations = _returnEffectOperations
        .then((_) async {
          if (!_isAppActive) return;
          if (_returnEffectPlayer.state != PlayerState.stopped) {
            await _returnEffectPlayer.stop();
          }
          if (!_isAppActive) return;

          final completed = Completer<void>();
          final completionSubscription = _returnEffectPlayer.onPlayerComplete
              .listen(
                (_) {
                  if (!completed.isCompleted) completed.complete();
                },
                onError: (Object error) {
                  if (!completed.isCompleted) completed.completeError(error);
                },
              );
          try {
            await _returnEffectPlayer.play(AssetSource('audio/effect.mp3'));
            if (!_isAppActive &&
                _returnEffectPlayer.state == PlayerState.playing) {
              await _returnEffectPlayer.pause();
              _returnEffectPausedForLifecycle = true;
            }
            await completed.future.timeout(const Duration(seconds: 15));
          } on TimeoutException {
            await _returnEffectPlayer.stop();
            rethrow;
          } finally {
            await completionSubscription.cancel();
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Gagal memutar efek kembali kuis: $error');
        });
  }

  void _playNavigationEffectSound() {
    _navigationEffectOperations = _navigationEffectOperations
        .then((_) async {
          if (!_isAppActive) return;
          if (_navigationEffectPlayer.state != PlayerState.stopped) {
            await _navigationEffectPlayer.stop();
          }
          if (!_isAppActive) return;

          final completed = Completer<void>();
          final completionSubscription = _navigationEffectPlayer
              .onPlayerComplete
              .listen(
                (_) {
                  if (!completed.isCompleted) completed.complete();
                },
                onError: (Object error) {
                  if (!completed.isCompleted) completed.completeError(error);
                },
              );
          try {
            await _navigationEffectPlayer.play(AssetSource('audio/effect.mp3'));
            if (!_isAppActive &&
                _navigationEffectPlayer.state == PlayerState.playing) {
              await _navigationEffectPlayer.pause();
              _navigationEffectPausedForLifecycle = true;
            }
            await completed.future.timeout(const Duration(seconds: 15));
          } on TimeoutException {
            await _navigationEffectPlayer.stop();
            rethrow;
          } finally {
            await completionSubscription.cancel();
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Gagal memutar efek navigasi kuis: $error');
        });
  }

  void _playPracticeClickSound() {
    unawaited(_playClickSound());
  }

  Future<void> _openPracticeQuiz({
    bool initialShowResult = false,
    ScanHistoryModel? historyData,
  }) async {
    if (_isOpeningPracticeQuiz || !mounted) return;
    _isOpeningPracticeQuiz = true;

    try {
      unawaited(_playClickSound());
      if (!mounted) return;

      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PracticeQuizScreen(
            module: module,
            initialShowResult: initialShowResult,
            historyData: historyData,
            onClickSound: _playPracticeClickSound,
            onResultEffect: _playEffectSound,
            onNavigationEffect: _playNavigationEffectSound,
          ),
        ),
      );
    } finally {
      _isOpeningPracticeQuiz = false;
    }
  }

  void _playBackClickSound() {
    unawaited(_playClickSound());
  }

  Future<void> _disposeAudioPlayer(AudioPlayer player, String label) async {
    try {
      if (player.state != PlayerState.stopped) {
        await player.stop();
      }
    } catch (error, stackTrace) {
      debugPrint('Gagal menghentikan $label: $error\n$stackTrace');
    }

    try {
      await player.dispose();
    } catch (error, stackTrace) {
      debugPrint('Gagal membersihkan $label: $error\n$stackTrace');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    final disposal =
        Future.wait<void>([
              _clickOperations,
              _returnEffectOperations,
              _navigationEffectOperations,
              _lifecycleOperations,
            ])
            .then((_) async {
              await Future.wait<void>([
                _disposeAudioPlayer(_clickPlayer, 'efek klik kuis'),
                _disposeAudioPlayer(_returnEffectPlayer, 'efek kembali kuis'),
                _disposeAudioPlayer(
                  _navigationEffectPlayer,
                  'efek navigasi kuis',
                ),
              ]);
            })
            .catchError((Object error, StackTrace stackTrace) {
              debugPrint('Gagal membersihkan efek klik kuis: $error');
            });
    unawaited(disposal);
    super.dispose();
  }

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
          Builder(
            builder: (context) {
              final bool hasQuizAttempt =
                  module.quizScore != null || module.quizDone;
              final int quizScore = module.quizScore ?? 0;
              // Nilai <= passingScore (70) adalah Belum Lulus. Wajib > passingScore untuk Lulus.
              final bool isQuizPassed =
                  (module.quizScore != null &&
                      module.quizScore! > module.passingScore) ||
                  (module.quizScore == null && module.quizDone);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: hasQuizAttempt
                            ? (isQuizPassed
                                  ? const Color(0xFF2E7D32)
                                        .withValues(alpha: 0.4)
                                  : const Color(0xFFF57C00)
                                        .withValues(alpha: 0.4))
                            : (isDark
                                  ? AppTheme.darkBorder
                                  : const Color(0xFFF0EAE1)),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: hasQuizAttempt
                              ? (isQuizPassed
                                    ? const Color(0xFF2E7D32)
                                          .withValues(alpha: 0.05)
                                    : const Color(0xFFF57C00)
                                          .withValues(alpha: 0.05))
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
                                  color: hasQuizAttempt
                                      ? (isQuizPassed
                                            ? const Color(0xFF2E7D32)
                                                  .withValues(alpha: 0.12)
                                            : const Color(0xFFF57C00)
                                                  .withValues(alpha: 0.12))
                                      : (isDark
                                            ? AppTheme.primary.withValues(
                                                alpha: 0.3,
                                              )
                                            : AppTheme.accentGold.withValues(
                                                alpha: 0.2,
                                              )),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.school_rounded,
                                  size: 24,
                                  color: hasQuizAttempt
                                      ? (isQuizPassed
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFFF57C00))
                                      : AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Kuis Teori',
                                        style: AppTheme.satoshi(
                                          fontSize: 17.5,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF2C1810),
                                        ),
                                        maxLines: 2,
                                      ),
                                    ),
                                    if (hasQuizAttempt) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isQuizPassed
                                              ? const Color(0xFF2E7D32)
                                                    .withValues(alpha: 0.12)
                                              : const Color(0xFFF57C00)
                                                    .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isQuizPassed
                                                ? const Color(0xFF2E7D32)
                                                      .withValues(alpha: 0.35)
                                                : const Color(0xFFF57C00)
                                                      .withValues(alpha: 0.35),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isQuizPassed
                                                  ? Icons.check_circle_rounded
                                                  : Icons.info_outline_rounded,
                                              size: 13,
                                              color: isQuizPassed
                                                  ? const Color(0xFF2E7D32)
                                                  : const Color(0xFFF57C00),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Nilai: $quizScore% (${isQuizPassed ? "Lulus" : "Belum Lulus"})',
                                              style: AppTheme.satoshi(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isQuizPassed
                                                    ? (isDark
                                                          ? const Color(
                                                              0xFF81C784,
                                                            )
                                                          : const Color(
                                                              0xFF1B5E20,
                                                            ))
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
                              color: isDark
                                  ? Colors.white70
                                  : AppTheme.textSecondary,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: () async {
                              await _playClickSound();
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TheoryQuizScreen(
                                    module: module,
                                    onBackToModuleMenu: _playBackClickSound,
                                    onReturnToModuleMenu: _playReturnSounds,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasQuizAttempt
                                  ? Colors.transparent
                                  : AppTheme.primary,
                              foregroundColor: hasQuizAttempt
                                  ? AppTheme.primary
                                  : Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: hasQuizAttempt
                                      ? AppTheme.primary
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  hasQuizAttempt
                                      ? Icons.refresh_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 18,
                                  color: hasQuizAttempt
                                      ? (isDark
                                            ? AppTheme.secondaryLight
                                            : AppTheme.primary)
                                      : Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  hasQuizAttempt
                                      ? 'Kerjakan Ulang'
                                      : 'Mulai Kuis',
                                  style: AppTheme.satoshi(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                    color: hasQuizAttempt
                                        ? (isDark
                                              ? AppTheme.secondaryLight
                                              : AppTheme.primary)
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
              );
            },
          ),
          const SizedBox(height: 28),

          // Card 2: Kuis Praktik
          Builder(
            builder: (context) {
              final provider = context.watch<AppProvider>();
              final latestAttempt = provider.scanHistories
                  .where(
                    (s) => s.moduleId == module.id && s.scanType == 'kuismu',
                  )
                  .firstOrNull;
              final bool hasAttempted =
                  module.practiceDone ||
                  module.practiceScore != null ||
                  latestAttempt != null;
              final int? practiceScore =
                  module.practiceScore ??
                  (latestAttempt != null
                      ? (latestAttempt.score * 100).round()
                      : null);
              // Nilai <= passingScore (70) adalah Belum Lulus. Wajib > passingScore untuk Lulus.
              final bool isPassed =
                  (practiceScore != null &&
                      practiceScore > module.passingScore) ||
                  (practiceScore == null &&
                      ((latestAttempt?.passed ?? false) ||
                          module.practiceDone));

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
                                  ? const Color(0xFF2E7D32)
                                        .withValues(alpha: 0.4)
                                  : const Color(0xFFF57C00)
                                        .withValues(alpha: 0.4))
                            : (isDark
                                  ? AppTheme.darkBorder
                                  : const Color(0xFFF0EAE1)),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: hasAttempted
                              ? (isPassed
                                    ? const Color(0xFF2E7D32)
                                          .withValues(alpha: 0.05)
                                    : const Color(0xFFF57C00)
                                          .withValues(alpha: 0.05))
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
                                            ? const Color(0xFF2E7D32)
                                                  .withValues(alpha: 0.12)
                                            : const Color(0xFFF57C00)
                                                  .withValues(alpha: 0.12))
                                      : (isDark
                                            ? AppTheme.primary.withValues(
                                                alpha: 0.3,
                                              )
                                            : AppTheme.accentGold.withValues(
                                                alpha: 0.2,
                                              )),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Kuis Praktik',
                                        style: AppTheme.satoshi(
                                          fontSize: 17.5,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF2C1810),
                                        ),
                                        maxLines: 2,
                                      ),
                                    ),
                                    if (hasAttempted) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isPassed
                                              ? const Color(0xFF2E7D32)
                                                    .withValues(alpha: 0.12)
                                              : const Color(0xFFF57C00)
                                                    .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isPassed
                                                ? const Color(0xFF2E7D32)
                                                      .withValues(alpha: 0.35)
                                                : const Color(0xFFF57C00)
                                                      .withValues(alpha: 0.35),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isPassed
                                                  ? Icons.check_circle_outline
                                                  : Icons.auto_awesome,
                                              size: 13,
                                              color: isPassed
                                                  ? const Color(0xFF2E7D32)
                                                  : const Color(0xFFF57C00),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Nilai: ${practiceScore ?? 100}%',
                                              style: AppTheme.satoshi(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isPassed
                                                    ? const Color(0xFF2E7D32)
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
                            'Gambarlah motif batik ini, lalu pindai hasil karyamu untuk melihat seberapa mirip dengan aslinya.',
                            style: AppTheme.inter(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white70
                                  : AppTheme.textSecondary,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (hasAttempted) ...[
                            ElevatedButton(
                              onPressed: () => _openPracticeQuiz(
                                initialShowResult: true,
                                historyData: latestAttempt,
                              ),
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
                                  const Icon(
                                    Icons.history_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
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
                              onPressed: _openPracticeQuiz,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                side: const BorderSide(
                                  color: Color(0xFFD4A373),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.replay_rounded,
                                    size: 16,
                                    color: isDark
                                        ? const Color(0xFFD4A373)
                                        : const Color(0xFF5A3416),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Coba Praktik Lagi',
                                    style: AppTheme.satoshi(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                      color: isDark
                                          ? const Color(0xFFD4A373)
                                          : const Color(0xFF5A3416),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            ElevatedButton(
                              onPressed: _openPracticeQuiz,
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
                                  const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 18,
                                    color: Colors.white,
                                  ),
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
