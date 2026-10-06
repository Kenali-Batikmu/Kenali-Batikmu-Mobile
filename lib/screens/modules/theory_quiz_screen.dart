import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final Map<int, String> _userAnswers = {
    0: 'B', // Contoh untuk simulasi jawaban yang salah di soal 1
    1: 'B', // Benar di soal 2
    2: 'A',
    3: 'C',
  };

  bool _isSubmitted = false;

  final List<Map<String, dynamic>> _quizData = [
    {
      'no': 1,
      'question': 'Motif Batik Parang Kusumo secara filosofis melambangkan _______ yang tidak pernah padam dalam menghadapi ujian hidup.',
      'options': [
        'A. semangat perjuangan dan keteguhan hati',
        'B. ketenangan danau keraton yang syahdu',
        'C. keagungan senjata keris pusaka Mataram',
        'D. kesuburan tanah dan hasil bumi Nusantara',
      ],
      'correct': 'A',
      'explanation': "Kata 'Kusumo' bermakna bunga ksatria. Bentuk lereng miring menyerupai deburan ombak karang laut selatan menggambarkan gelombang tekad pantang menyerah, keteguhan hati, serta budi pekerti luhur ksatria Jawa.",
    },
    {
      'no': 2,
      'question': 'Ciri khas kemiringan garis lereng pada motif Parang Kusumo adalah sebesar _______ derajat.',
      'options': [
        'A. 30',
        'B. 45',
        'C. 60',
        'D. 90',
      ],
      'correct': 'B',
      'explanation': 'Kemiringan lereng 45 derajat melambangkan keteguhan arah dan konsistensi jalan hidup seorang ksatria.',
    },
    {
      'no': 3,
      'question': 'Motif Parang Kusumo diciptakan oleh raja Keraton Mataram pada masa pemerintahan _______.',
      'options': [
        'A. Sultan Agung Hanyakrakusuma',
        'B. Panembahan Senopati',
        'C. Sri Sultan Hamengkubuwono I',
        'D. Pakubuwana IV',
      ],
      'correct': 'B',
      'explanation': 'Motif Parang Kusumo digubah oleh Panembahan Senopati saat bertapa di Pantai Parangtritis dan terinspirasi oleh deburan ombak karang.',
    },
    {
      'no': 4,
      'question': 'Ornamen belah ketupat yang mengisi sela-sela lereng motif Parang dikenal dengan nama _______.',
      'options': [
        'A. Cecek',
        'B. Kaut',
        'C. Mlinjon',
        'D. Isen',
      ],
      'correct': 'C',
      'explanation': 'Mlinjon melambangkan senjata perisai atau benteng perlindungan moral dalam menghadapi godaan hidup.',
    },
  ];

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Jika sudah di-submit, tampilkan Banner Skor Akhir 80 (8/10) Sesuai PDF Page 9
            if (_isSubmitted) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: Text(
                  'Skor Akhir: 80 (8/10)',
                  style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Daftar Soal
            ..._quizData.asMap().entries.map((entry) {
              final index = entry.key;
              final q = entry.value;
              final userChoice = _userAnswers[index];
              final isCorrect = userChoice == q['correct'];

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Soal & Poin
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SOAL ${q['no']} DARI 10',
                          style: AppTheme.satoshi(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: isDark ? Colors.white70 : AppTheme.textMuted),
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
                      q['question'] as String,
                      style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                    const SizedBox(height: 14),

                    // Opsi Pilihan Ganda A, B, C, D
                    ...(q['options'] as List<String>).map((opt) {
                      final optLetter = opt.substring(0, 1);
                      final isSelectedByUser = userChoice == optLetter;
                      final isCorrectOption = optLetter == q['correct'];

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

                    // Penjelasan Materi jika sudah disubmit (Sesuai PDF Page 9)
                    if (_isSubmitted) ...[
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
                              q['explanation'] as String,
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

            // Tombol Done / Selesai Sesuai PDF Page 8 & 9
            if (!_isSubmitted)
              ElevatedButton(
                onPressed: () {
                  setState(() => _isSubmitted = true);
                  // Simpan skor 80 (8/10) ke provider
                  final provider = Provider.of<AppProvider>(context, listen: false);
                  provider.saveQuizResult(widget.module.id, 80, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A3416),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Done',
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
                  'Selesai & Simpan Nilai',
                  style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isSubmitted = false;
                    _userAnswers[0] = 'A'; // Sekarang pilih benar jika ingin coba lagi
                  });
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: Color(0xFF7A4B29)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Ulangi Kuis',
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
