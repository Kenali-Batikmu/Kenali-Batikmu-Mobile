import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../providers/app_provider.dart';

class TheoryQuizScreen extends StatefulWidget {
  final ModuleModel module;

  const TheoryQuizScreen({super.key, required this.module});

  @override
  State<TheoryQuizScreen> createState() => _TheoryQuizScreenState();
}

class _TheoryQuizScreenState extends State<TheoryQuizScreen> {
  final Map<int, String> _userAnswers = {};
  bool _isSubmitted = false;
  bool _isLoading = true;
  List<QuizQuestionModel> _questions = [];
  int _finalScore = 0;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final list = await DatabaseHelper.instance.getQuizQuestions(widget.module.id, limit: 10, shuffle: true);
    if (mounted) {
      setState(() {
        _questions = list;
        _isLoading = false;
        _userAnswers.clear();
        _isSubmitted = false;
      });
    }
  }

  void _submitQuiz() {
    if (_questions.isEmpty) return;

    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (_userAnswers[i] == q.correctOption) {
        correct++;
      }
    }

    final score = ((correct / _questions.length) * 100).round();
    final passed = score >= widget.module.passingScore;

    setState(() {
      _correctCount = correct;
      _finalScore = score;
      _isSubmitted = true;
    });

    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.saveQuizResult(widget.module.id, score, passed);
  }

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text('KENALI BATIKMU', style: AppTheme.satoshi(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.primary)),
            Text('Detail Modul - Kuis Teori', style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
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
                        const Icon(Icons.quiz_outlined, size: 56, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'Soal kuis untuk modul ini sedang disiapkan.',
                          style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Skor Akhir jika sudah di-submit
                      if (_isSubmitted) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _finalScore >= widget.module.passingScore
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _finalScore >= widget.module.passingScore
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
                                  color: _finalScore >= widget.module.passingScore
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFC62828),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _finalScore >= widget.module.passingScore
                                    ? 'Selamat! Kamu dinyatakan LULUS kuis teori modul ini.'
                                    : 'Nilai minimal kelulusan adalah ${widget.module.passingScore}%. Silakan pelajari kembali materi dan ulangi kuis.',
                                style: AppTheme.inter(
                                  fontSize: 12,
                                  color: _finalScore >= widget.module.passingScore
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
                                      color: isDark ? Colors.white70 : AppTheme.textMuted,
                                    ),
                                  ),
                                  if (_isSubmitted)
                                    Text(
                                      isCorrect ? '1 / 1 Poin' : '0 / 1 Poin',
                                      style: AppTheme.satoshi(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                q.question,
                                style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold, height: 1.4),
                              ),
                              const SizedBox(height: 14),

                              // Pilihan Jawaban A, B, C, D
                              ...options.map((opt) {
                                final optLetter = opt.substring(0, 1);
                                final isSelectedByUser = userChoice == optLetter;
                                final isCorrectOption = optLetter == q.correctOption;

                                Color borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;
                                Color bgColor = isDark ? AppTheme.darkSurface : Colors.white;
                                Widget? trailingIcon;

                                if (_isSubmitted) {
                                  if (isCorrectOption) {
                                    borderColor = const Color(0xFF2E7D32);
                                    bgColor = const Color(0xFFF1F8E9);
                                    trailingIcon = const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 20);
                                  } else if (isSelectedByUser) {
                                    borderColor = const Color(0xFFC62828);
                                    bgColor = const Color(0xFFFFEBEE);
                                    trailingIcon = const Icon(Icons.cancel_outlined, color: Color(0xFFC62828), size: 20);
                                  }
                                } else if (isSelectedByUser) {
                                  borderColor = AppTheme.primary;
                                  bgColor = AppTheme.primary.withValues(alpha: 0.08);
                                }

                                return GestureDetector(
                                  onTap: _isSubmitted
                                      ? null
                                      : () {
                                          setState(() {
                                            _userAnswers[index] = optLetter;
                                          });
                                        },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: borderColor, width: 1.5),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            opt,
                                            style: AppTheme.inter(
                                              fontSize: 13,
                                              fontWeight: isSelectedByUser ? FontWeight.bold : FontWeight.normal,
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
                              if (_isSubmitted && q.explanation != null && q.explanation!.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDF7F2),
                                    borderRadius: BorderRadius.circular(14),
                                    border: const Border(
                                      left: BorderSide(color: Color(0xFF7A4B29), width: 4),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Penjelasan Materi:',
                                        style: AppTheme.satoshi(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF7A4B29)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        q.explanation!,
                                        style: AppTheme.inter(fontSize: 12, height: 1.45, color: const Color(0xFF4A3B32)),
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
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Harap jawab semua soal (${_userAnswers.length}/${_questions.length} terjawab)'),
                                      backgroundColor: Colors.orange.shade800,
                                    ),
                                  );
                                }
                              : _submitQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A3416),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'Selesai & Kumpulkan Jawaban',
                            style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        )
                      else ...[
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A3416),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'Kembali ke Menu Modul',
                            style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _loadQuestions,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            side: const BorderSide(color: Color(0xFF7A4B29)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'Ulangi Kuis (Acak Soal Baru)',
                            style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF7A4B29)),
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
