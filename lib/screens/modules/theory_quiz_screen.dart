import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../providers/app_provider.dart';

class TheoryQuizScreen extends StatefulWidget {
  final ModuleModel module;
  final VoidCallback? onBackToModuleMenu;
  final VoidCallback? onReturnToModuleMenu;

  const TheoryQuizScreen({
    super.key,
    required this.module,
    this.onBackToModuleMenu,
    this.onReturnToModuleMenu,
  });

  @override
  State<TheoryQuizScreen> createState() => _TheoryQuizScreenState();
}

class _TheoryQuizScreenState extends State<TheoryQuizScreen>
    with WidgetsBindingObserver {
  final Map<int, String> _userAnswers = {};
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _musicPlayer = AudioPlayer();
  Future<void> _audioOperations = Future<void>.value();
  final AudioPlayer _clickEffectPlayer = AudioPlayer();
  Future<void> _clickEffectOperations = Future<void>.value();
  Completer<void>? _activeClickPlayback;
  int _clickRequestVersion = 0;
  final AudioPlayer _resultEffectPlayer = AudioPlayer();
  Future<void> _resultEffectOperations = Future<void>.value();
  Completer<void>? _activeResultPlayback;
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  bool _isRestarting = false;
  bool _isNavigatingBack = false;
  bool _isLoading = true;
  bool _isMuted = false;
  bool _isAppActive = true;
  bool _musicStarted = false;
  bool _resultEffectPlayed = false;
  bool _clickEffectReady = false;
  bool _resultEffectReady = false;
  bool _isDisposed = false;
  List<QuizQuestionModel> _questions = [];
  int _finalScore = 0;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clickEffectOperations = _configureEffectPlayer(_clickEffectPlayer)
        .then(
          (_) => _clickEffectPlayer.setSource(AssetSource('audio/click.mp3')),
        )
        .then((_) {
          _clickEffectReady = true;
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Gagal memuat efek klik kuis teori: $error');
        });
    _resultEffectOperations = _configureEffectPlayer(_resultEffectPlayer)
        .then((_) {
          _resultEffectReady = true;
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Gagal menyiapkan efek hasil kuis teori: $error');
        });
    _loadQuestions();
  }

  Future<void> _configureEffectPlayer(AudioPlayer player) async {
    await player.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
    );
    await player.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    final activeClickPlayback = _activeClickPlayback;
    if (activeClickPlayback != null && !activeClickPlayback.isCompleted) {
      activeClickPlayback.complete();
    }
    final activeResultPlayback = _activeResultPlayback;
    if (activeResultPlayback != null && !activeResultPlayback.isCompleted) {
      activeResultPlayback.complete();
    }
    final disposal = _audioOperations
        .then((_) async {
          try {
            if (_musicStarted) await _musicPlayer.stop();
          } finally {
            await _musicPlayer.dispose();
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Gagal membersihkan backsound kuis teori: $error');
        });
    unawaited(disposal);
    final clickEffectDisposal = _clickEffectOperations
        .then((_) async {
          try {
            if (_clickEffectPlayer.state != PlayerState.stopped) {
              await _clickEffectPlayer.stop();
            }
          } finally {
            await _clickEffectPlayer.dispose();
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Gagal membersihkan efek klik kuis teori: $error');
        });
    unawaited(clickEffectDisposal);
    final resultEffectDisposal = _resultEffectOperations
        .then((_) async {
          try {
            if (_resultEffectPlayer.state != PlayerState.stopped) {
              await _resultEffectPlayer.stop();
            }
          } finally {
            await _resultEffectPlayer.dispose();
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Gagal membersihkan efek hasil kuis teori: $error');
        });
    unawaited(resultEffectDisposal);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppActive = state == AppLifecycleState.resumed;
    _syncBackgroundMusic();
  }

  Future<void> _playClickSound({bool waitForCompletion = false}) {
    if (_isDisposed) return Future<void>.value();

    final requestVersion = ++_clickRequestVersion;
    _clickEffectOperations = _clickEffectOperations
        .then((_) async {
          if (_isDisposed ||
              !_clickEffectReady ||
              (!waitForCompletion && requestVersion != _clickRequestVersion)) {
            return;
          }

          Completer<void>? completed;
          StreamSubscription<void>? completionSubscription;
          try {
            final playerState = _clickEffectPlayer.state;
            if (playerState == PlayerState.disposed) return;
            if (playerState == PlayerState.playing ||
                playerState == PlayerState.paused) {
              await _clickEffectPlayer.seek(Duration.zero);
            }
            if (_isDisposed ||
                (!waitForCompletion &&
                    requestVersion != _clickRequestVersion)) {
              return;
            }

            if (waitForCompletion) {
              final playbackCompletion = Completer<void>();
              completed = playbackCompletion;
              _activeClickPlayback = playbackCompletion;
              completionSubscription = _clickEffectPlayer.onPlayerComplete
                  .listen(
                    (_) {
                      if (!playbackCompletion.isCompleted) {
                        playbackCompletion.complete();
                      }
                    },
                    onError: (Object error) {
                      if (!playbackCompletion.isCompleted) {
                        playbackCompletion.completeError(error);
                      }
                    },
                  );
            }

            if (_clickEffectPlayer.state != PlayerState.playing) {
              await _clickEffectPlayer.resume();
            }
            if (completed != null) {
              try {
                await completed.future.timeout(const Duration(seconds: 5));
              } on TimeoutException {
                await _clickEffectPlayer.stop();
                rethrow;
              }
            }
          } finally {
            await completionSubscription?.cancel();
            if (completed != null &&
                identical(_activeClickPlayback, completed)) {
              _activeClickPlayback = null;
            }
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Gagal memutar efek klik kuis teori: $error');
        });
    return _clickEffectOperations;
  }

  void _queueResultEffect() {
    _resultEffectOperations = _resultEffectOperations
        .then((_) async {
          if (_isDisposed || !_resultEffectReady) return;

          final completed = Completer<void>();
          _activeResultPlayback = completed;
          final completionSubscription = _resultEffectPlayer.onPlayerComplete
              .listen(
                (_) {
                  if (!completed.isCompleted) completed.complete();
                },
                onError: (Object error) {
                  if (!completed.isCompleted) completed.completeError(error);
                },
              );
          try {
            await _resultEffectPlayer.play(AssetSource('audio/effect.mp3'));
            await completed.future;
          } finally {
            await completionSubscription.cancel();
            if (identical(_activeResultPlayback, completed)) {
              _activeResultPlayback = null;
            }
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Gagal memutar efek hasil kuis teori: $error');
        });
  }

  Future<void> _syncBackgroundMusic() {
    _audioOperations = _audioOperations
        .then((_) async {
          if (_isDisposed) return;

          if (_isSubmitted || _questions.isEmpty) {
            if (_musicStarted) {
              await _musicPlayer.stop();
              _musicStarted = false;
            }
            return;
          }

          if (_isMuted || !_isAppActive) {
            if (_musicStarted) await _musicPlayer.pause();
            return;
          }

          if (_musicStarted) {
            await _musicPlayer.setVolume(0.85);
            await _musicPlayer.resume();
          } else {
            await _musicPlayer.setReleaseMode(ReleaseMode.loop);
            await _musicPlayer.setVolume(0.85);
            await _musicPlayer.play(AssetSource('audio/quis_backsound.mp3'));
            _musicStarted = true;
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Gagal mengatur backsound kuis teori: $error');
        });
    return _audioOperations;
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _syncBackgroundMusic();
  }

  Future<void> _loadQuestions() async {
    _resultEffectPlayed = false;
    final list = await DatabaseHelper.instance.getQuizQuestions(
      widget.module.id,
      limit: 10,
      shuffle: true,
    );
    if (mounted) {
      setState(() {
        _questions = list;
        _isLoading = false;
        _userAnswers.clear();
        _isSubmitted = false;
      });
      _syncBackgroundMusic();
    }
  }

  Future<void> _submitQuiz() async {
    if (_questions.isEmpty || _isSubmitted || _isSubmitting) return;

    _isSubmitting = true;
    try {
      int correct = 0;
      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        if (_userAnswers[i] == q.correctOption) {
          correct++;
        }
      }

      final score = ((correct / _questions.length) * 100).round();
      // Nilai <= passingScore (70) dianggap belum lolos. Wajib > passingScore untuk lolos.
      final passed = score > widget.module.passingScore;

      unawaited(_playClickSound());

      setState(() {
        _correctCount = correct;
        _finalScore = score;
        _isSubmitted = true;
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }

      final provider = Provider.of<AppProvider>(context, listen: false);
      final resultSaving = _saveQuizResult(provider, score, passed);
      unawaited(_syncBackgroundMusic());

      await WidgetsBinding.instance.endOfFrame;
      if (mounted && !_resultEffectPlayed) {
        _resultEffectPlayed = true;
        _queueResultEffect();
      }
      await resultSaving;
    } finally {
      _isSubmitting = false;
    }
  }

  Future<void> _saveQuizResult(
    AppProvider provider,
    int score,
    bool passed,
  ) async {
    try {
      await provider.saveQuizResult(widget.module.id, score, passed);
    } catch (error, stackTrace) {
      debugPrint('Gagal menyimpan hasil kuis teori: $error\n$stackTrace');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hasil kuis sudah ditampilkan, tetapi gagal disimpan.'),
        ),
      );
    }
  }

  void _navigateToModuleMenu({required bool playResultSounds}) {
    if (_isNavigatingBack || !mounted) return;
    _isNavigatingBack = true;

    try {
      if (playResultSounds) {
        widget.onReturnToModuleMenu?.call();
      } else {
        widget.onBackToModuleMenu?.call();
      }
    } catch (error, stackTrace) {
      debugPrint('Gagal memulai efek audio saat kembali: $error\n$stackTrace');
    }

    if (mounted) Navigator.pop(context);
  }

  void _handleBackButton() => _navigateToModuleMenu(playResultSounds: false);

  void _handleResultReturn() => _navigateToModuleMenu(playResultSounds: true);

  Future<void> _restartQuiz() async {
    if (_isRestarting || _isSubmitting) return;

    _isRestarting = true;
    try {
      await _playClickSound(waitForCompletion: true);
      if (mounted) await _loadQuestions();
    } finally {
      _isRestarting = false;
    }
  }

  Future<void> _showIncompleteAnswersMessage() async {
    await _playClickSound();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Harap jawab semua soal (${_userAnswers.length}/${_questions.length} terjawab)',
        ),
        backgroundColor: Colors.orange.shade800,
      ),
    );
  }

  Color get _appBarIconColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : AppTheme.textPrimary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: isDark ? Colors.white : AppTheme.textPrimary,
          onPressed: _handleBackButton,
        ),
        title: Column(
          children: [
            Text(
              'KENALI BATIKMU',
              style: AppTheme.satoshi(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.primary,
              ),
            ),
            Text(
              'Detail Modul - Kuis Teori',
              style: AppTheme.satoshi(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: _isSubmitted
            ? const []
            : [
                IconButton(
                  tooltip: _isMuted
                      ? 'Nyalakan backsound'
                      : 'Matikan backsound',
                  onPressed: _toggleMute,
                  icon: Icon(
                    _isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                  ),
                  color: _appBarIconColor,
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.quiz_outlined,
                      size: 56,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Soal kuis untuk modul ini sedang disiapkan.',
                      style: AppTheme.satoshi(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Skor Akhir jika sudah di-submit
                  if (_isSubmitted) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _finalScore > widget.module.passingScore
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _finalScore > widget.module.passingScore
                              ? const Color(0xFF81C784)
                              : const Color(0xFFE57373),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Skor Akhir: $_finalScore ($_correctCount/${_questions.length})',
                            style: AppTheme.satoshi(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _finalScore > widget.module.passingScore
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFC62828),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Jawaban benar: $_correctCount  |  Jawaban salah: ${_questions.length - _correctCount}',
                            style: AppTheme.satoshi(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _finalScore > widget.module.passingScore
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFC62828),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _finalScore > widget.module.passingScore
                                ? 'Selamat! Kamu dinyatakan LULUS kuis teori modul ini.'
                                : 'Nilai minimal kelulusan adalah di atas ${widget.module.passingScore}% (> ${widget.module.passingScore}%). Silakan pelajari kembali materi dan ulangi kuis.',
                            style: AppTheme.inter(
                              fontSize: 12,
                              color: _finalScore > widget.module.passingScore
                                  ? const Color(0xFF1B5E20)
                                  : const Color(0xFFB71C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Daftar Soal Kuis
                  ..._questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final q = entry.value;
                    final userChoice = _userAnswers[index];
                    final isCorrect = userChoice == q.correctOption;

                    final options = [
                      'A. ${q.optionA}',
                      'B. ${q.optionB}',
                      'C. ${q.optionC}',
                      'D. ${q.optionD}',
                    ];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SOAL ${index + 1} DARI ${_questions.length}',
                                style: AppTheme.satoshi(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: isDark
                                      ? Colors.white70
                                      : AppTheme.textMuted,
                                ),
                              ),
                              if (_isSubmitted)
                                Text(
                                  isCorrect ? '1 / 1 Poin' : '0 / 1 Poin',
                                  style: AppTheme.satoshi(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isCorrect
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFC62828),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            q.question,
                            style: AppTheme.satoshi(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Pilihan Jawaban A, B, C, D
                          ...options.map((opt) {
                            final optLetter = opt.substring(0, 1);
                            final isSelectedByUser = userChoice == optLetter;
                            final isCorrectOption =
                                optLetter == q.correctOption;

                            Color borderColor = isDark
                                ? AppTheme.darkBorder
                                : AppTheme.border;
                            Color bgColor = isDark
                                ? AppTheme.darkSurface
                                : Colors.white;
                            Widget? trailingIcon;

                            if (_isSubmitted) {
                              if (isCorrectOption) {
                                borderColor = const Color(0xFF2E7D32);
                                bgColor = const Color(0xFFF1F8E9);
                                trailingIcon = const Icon(
                                  Icons.check_circle_outline,
                                  color: Color(0xFF2E7D32),
                                  size: 20,
                                );
                              } else if (isSelectedByUser) {
                                borderColor = const Color(0xFFC62828);
                                bgColor = const Color(0xFFFFEBEE);
                                trailingIcon = const Icon(
                                  Icons.cancel_outlined,
                                  color: Color(0xFFC62828),
                                  size: 20,
                                );
                              }
                            } else if (isSelectedByUser) {
                              borderColor = AppTheme.primary;
                              bgColor = AppTheme.primary.withValues(
                                alpha: 0.08,
                              );
                            }

                            return GestureDetector(
                              onTap: _isSubmitted || _isSubmitting
                                  ? null
                                  : () {
                                      if (_isSubmitting) return;
                                      _playClickSound();
                                      setState(() {
                                        _userAnswers[index] = optLetter;
                                      });
                                    },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        opt,
                                        style: AppTheme.inter(
                                          fontSize: 13,
                                          fontWeight: isSelectedByUser
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: _isSubmitted && isCorrectOption
                                              ? const Color(0xFF2E7D32)
                                              : _isSubmitted && isSelectedByUser
                                              ? const Color(0xFFC62828)
                                              : isDark
                                              ? Colors.white
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    ?trailingIcon,
                                  ],
                                ),
                              ),
                            );
                          }),

                          // Pembahasan Soal
                          if (_isSubmitted &&
                              q.explanation != null &&
                              q.explanation!.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDF7F2),
                                borderRadius: BorderRadius.circular(14),
                                border: const Border(
                                  left: BorderSide(
                                    color: Color(0xFF7A4B29),
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Penjelasan Materi:',
                                    style: AppTheme.satoshi(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF7A4B29),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    q.explanation!,
                                    style: AppTheme.inter(
                                      fontSize: 12,
                                      height: 1.45,
                                      color: const Color(0xFF4A3B32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          const Divider(color: AppTheme.border),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 10),

                  // Tombol Aksi
                  if (!_isSubmitted)
                    ElevatedButton(
                      onPressed: _userAnswers.length < _questions.length
                          ? _showIncompleteAnswersMessage
                          : _submitQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A3416),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Selesai & Kumpulkan Jawaban',
                        style: AppTheme.satoshi(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else ...[
                    ElevatedButton(
                      onPressed: _handleResultReturn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A3416),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Kembali ke Menu Modul',
                        style: AppTheme.satoshi(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _restartQuiz,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        side: const BorderSide(color: Color(0xFF7A4B29)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Ulangi Kuis (Acak Soal Baru)',
                        style: AppTheme.satoshi(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7A4B29),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
