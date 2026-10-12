import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 0; // 0: Input Email, 1: Verifikasi OTP, 2: Sandi Baru

  // Controller & Form Keys
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  // Controller untuk 4 digit OTP
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  // Controller untuk Kata Sandi Baru
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  // Countdown Timer untuk Kirim Ulang OTP (60 detik)
  Timer? _countdownTimer;
  int _resendSeconds = 60;
  bool _canResend = false;

  // Pesan info pengiriman (live vs simulasi demo)
  String? _deliveryNotice;
  bool _isDemoNotice = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final fn in _otpFocusNodes) {
      fn.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _resendSeconds = 60;
      _canResend = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds > 1) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _handleSendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final provider = context.read<AppProvider>();
    final email = _emailController.text.trim();

    final result = await provider.requestPasswordReset(email);

    if (!mounted) return;

    if (result.isSuccess) {
      for (final c in _otpControllers) {
        c.clear();
      }
      setState(() {
        _isDemoNotice = result.isDemoSimulated;
        _deliveryNotice = result.isDemoSimulated
            ? 'Mode Demo: Kode OTP Anda adalah ${provider.activeResetOtp}'
            : 'Kode verifikasi telah dikirim ke $email';
      });

      _startResendTimer();

      // Transisi ke Step 2 (Verifikasi OTP)
      setState(() => _currentStep = 1);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isDemoSimulated
                ? 'Mode Pengujian: Kode OTP Anda adalah ${provider.activeResetOtp}'
                : 'Kode verifikasi berhasil dikirim ke $email',
            style: AppTheme.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFC07F35),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Fokuskan pada kotak OTP pertama
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _otpFocusNodes[0].requestFocus();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? result.message,
            style: AppTheme.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleVerifyOtp() {
    final enteredOtp = _otpControllers.map((c) => c.text).join();
    if (enteredOtp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan masukkan 4-digit kode verifikasi lengkap.',
            style: AppTheme.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final isValid = provider.verifyResetOtp(enteredOtp);

    if (isValid) {
      FocusScope.of(context).unfocus();
      setState(() => _currentStep = 2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Kode verifikasi salah.',
            style: AppTheme.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleFinalizePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final provider = context.read<AppProvider>();
    final newPass = _newPasswordController.text;

    final success = await provider.finalizePasswordReset(newPass);

    if (!mounted) return;

    if (success) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Gagal memperbarui kata sandi.',
            style: AppTheme.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF8),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A2E1B).withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge Ikon Sukses Emas
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFE4BA73),
                            Color(0xFFC07F35),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC07F35).withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Kata Sandi Diperbarui!',
                      style: AppTheme.notoSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C1B10),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    Text(
                      'Kata sandi akun Anda telah berhasil diubah. Silakan masuk kembali menggunakan kata sandi baru Anda.',
                      style: AppTheme.plusJakartaSans(
                        fontSize: 13.5,
                        color: const Color(0xFF55473C),
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Tombol Kembali ke Login
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop(); // Tutup dialog
                          Navigator.of(context).pop(_emailController.text.trim()); // Kembali ke Login dengan email
                        },
                        child: Text(
                          'Masuk Sekarang',
                          style: AppTheme.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 0) {
          setState(() => _currentStep--);
        }
      },
      child: Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFBF8F3),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Ilustrasi Studio Batik
            Positioned.fill(
              child: Image.asset(
                'assets/images/login_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            // 2. Ambient Warm Gradient Overlay
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

            // 3. Konten Utama
            SafeArea(
              child: Column(
                children: [
                  // Header Bar Terpadu & Elegan
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFEADBCE),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A2E1B).withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (_currentStep > 0) {
                                  setState(() => _currentStep--);
                                } else {
                                  Navigator.of(context).pop();
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F1EB),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFEADBCE),
                                    width: 1.0,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: Color(0xFF4A3828),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFC07F35),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'KENALI BATIKMU',
                                    style: AppTheme.notoSerif(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.2,
                                      color: const Color(0xFF3D2616),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFC07F35),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 38),
                        ],
                      ),
                    ),
                  ),

                  // Area Form Scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        22,
                        8,
                        22,
                        viewInsetsBottom > 0 ? viewInsetsBottom + 20 : 24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            children: [
                              // Stepper Indikator Motif Batik
                              _buildStepIndicator(),
                              const SizedBox(height: 18),

                              // Kartu Glassmorphism Utama
                              ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 24,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFDF8)
                                          .withValues(alpha: 0.94),
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
                                      ],
                                    ),
                                    child: AnimatedSize(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      child: _buildCurrentStepContent(),
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
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildStepIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEADBCE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A2E1B).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStepNode(stepIndex: 0, label: 'Email', icon: Icons.mail_outline_rounded),
          ),
          _buildStepDivider(isActive: _currentStep >= 1),
          Expanded(
            child: _buildStepNode(stepIndex: 1, label: 'OTP', icon: Icons.shield_outlined),
          ),
          _buildStepDivider(isActive: _currentStep >= 2),
          Expanded(
            child: _buildStepNode(stepIndex: 2, label: 'Sandi', icon: Icons.lock_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode({
    required int stepIndex,
    required String label,
    required IconData icon,
  }) {
    final isDone = _currentStep > stepIndex;
    final isCurrent = _currentStep == stepIndex;

    Color bgColor = const Color(0xFFF3ECE3);
    Color iconColor = const Color(0xFFA09486);
    Color textColor = const Color(0xFFA09486);

    if (isCurrent) {
      bgColor = AppTheme.primary;
      iconColor = Colors.white;
      textColor = AppTheme.primaryDark;
    } else if (isDone) {
      bgColor = const Color(0xFFC07F35);
      iconColor = Colors.white;
      textColor = const Color(0xFFC07F35);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isDone ? Icons.check_rounded : icon,
            size: 12,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.plusJakartaSans(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider({required bool isActive}) {
    return Container(
      width: 10,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFC07F35) : const Color(0xFFEADBCE),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Email();
      case 1:
        return _buildStep2Otp();
      case 2:
        return _buildStep3NewPassword();
      default:
        return _buildStep1Email();
    }
  }

  Widget _buildStep1Email() {
    final provider = context.watch<AppProvider>();

    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3EA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8DFC8)),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: Color(0xFFC07F35),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pemulihan Akun',
                      style: AppTheme.notoSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C1B10),
                      ),
                    ),
                    Text(
                      'Langkah 1 dari 3',
                      style: AppTheme.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF8A7D70),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Masukkan alamat email yang terdaftar pada akun Kenali Batikmu. Kami akan mengirimkan 4-digit kode verifikasi ke alamat tersebut.',
            style: AppTheme.plusJakartaSans(
              fontSize: 13.5,
              color: const Color(0xFF55473C),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),

          Text(
            'Alamat Email',
            style: AppTheme.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C221A),
            ),
          ),
          const SizedBox(height: 8),

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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
                borderSide: const BorderSide(color: Color(0xFFE8DFC8), width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE8DFC8), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.6),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email tidak boleh kosong';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Tombol Kirim Kode
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: provider.isLoading ? null : _handleSendOtp,
              child: provider.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Kirim Kode Verifikasi',
                          style: AppTheme.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Otp() {
    final provider = context.watch<AppProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3EA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8DFC8)),
              ),
              child: const Icon(
                Icons.pin_outlined,
                color: Color(0xFFC07F35),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verifikasi Kode',
                    style: AppTheme.notoSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C1B10),
                    ),
                  ),
                  Text(
                    'Langkah 2 dari 3',
                    style: AppTheme.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF8A7D70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Text.rich(
          TextSpan(
            text: 'Kode 4-digit telah dikirimkan ke ',
            style: AppTheme.plusJakartaSans(
              fontSize: 13.5,
              color: const Color(0xFF55473C),
              height: 1.45,
            ),
            children: [
              TextSpan(
                text: _emailController.text.trim(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C1B10),
                ),
              ),
              const TextSpan(text: '. Masukkan kode tersebut di bawah ini.'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Banner Notifikasi Pengiriman / Demo Notice
        if (_deliveryNotice != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isDemoNotice
                  ? const Color(0xFFFFF3E0)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDemoNotice
                    ? const Color(0xFFFFB74D)
                    : const Color(0xFF81C784),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isDemoNotice
                      ? Icons.auto_awesome
                      : Icons.mark_email_read_rounded,
                  size: 18,
                  color: _isDemoNotice
                      ? const Color(0xFFE65100)
                      : const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _deliveryNotice!,
                    style: AppTheme.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _isDemoNotice
                          ? const Color(0xFFBF360C)
                          : const Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // 4 Kotak Input PIN OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return SizedBox(
              width: 58,
              height: 64,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: AppTheme.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C1B10),
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(1),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF7F3EA),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE8DFC8), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE8DFC8), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFC07F35), width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    if (index < 3) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else {
                      _otpFocusNodes[index].unfocus();
                      _handleVerifyOtp();
                    }
                  } else {
                    if (index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 20),

        // Countdown Timer & Kirim Ulang
        Center(
          child: _canResend
              ? TextButton.icon(
                  onPressed: provider.isLoading ? null : _handleSendOtp,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    'Kirim Ulang Kode OTP',
                    style: AppTheme.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: Color(0xFF8A7D70),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Kirim ulang kode dalam 00:${_resendSeconds.toString().padLeft(2, '0')}',
                      style: AppTheme.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFF8A7D70),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 18),

        // Tombol Verifikasi
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _handleVerifyOtp,
            child: Text(
              'Verifikasi Kode',
              style: AppTheme.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Opsi ganti email
        Center(
          child: TextButton(
            onPressed: () {
              setState(() => _currentStep = 0);
            },
            child: Text(
              'Ubah Alamat Email',
              style: AppTheme.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7A4B29),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3NewPassword() {
    final provider = context.watch<AppProvider>();

    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3EA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8DFC8)),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: Color(0xFFC07F35),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kata Sandi Baru',
                      style: AppTheme.notoSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C1B10),
                      ),
                    ),
                    Text(
                      'Langkah 3 dari 3',
                      style: AppTheme.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF8A7D70),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            'Silakan buat kata sandi baru yang kuat untuk mengamankan akun Batikmu Anda.',
            style: AppTheme.plusJakartaSans(
              fontSize: 13.5,
              color: const Color(0xFF55473C),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),

          // Field Kata Sandi Baru
          Text(
            'Kata Sandi Baru',
            style: AppTheme.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C221A),
            ),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNewPass,
            onChanged: (_) => setState(() {}),
            style: AppTheme.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF2C221A),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7F3EA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF8A7D70),
                size: 21,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF8A7D70),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
              ),
              hintText: 'Minimal 8 karakter',
              hintStyle: AppTheme.plusJakartaSans(
                color: const Color(0xFFA09486),
                fontSize: 13.5,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE8DFC8), width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE8DFC8), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.6),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Kata sandi baru tidak boleh kosong';
              }
              if (value.trim().length < 8) {
                return 'Kata sandi minimal 8 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          // Meter Kekuatan Sandi Responsif
          _buildPasswordStrengthBar(_newPasswordController.text),
          const SizedBox(height: 18),

          // Field Konfirmasi Kata Sandi Baru
          Text(
            'Konfirmasi Kata Sandi Baru',
            style: AppTheme.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C221A),
            ),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPass,
            style: AppTheme.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF2C221A),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7F3EA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              prefixIcon: const Icon(
                Icons.lock_reset_rounded,
                color: Color(0xFF8A7D70),
                size: 21,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF8A7D70),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
              ),
              hintText: 'Ulangi kata sandi baru',
              hintStyle: AppTheme.plusJakartaSans(
                color: const Color(0xFFA09486),
                fontSize: 13.5,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE8DFC8), width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE8DFC8), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.6),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Konfirmasi kata sandi wajib diisi';
              }
              if (value != _newPasswordController.text) {
                return 'Konfirmasi kata sandi tidak cocok';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Tombol Simpan Sandi
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: provider.isLoading ? null : _handleFinalizePassword,
              child: provider.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Simpan & Masuk',
                      style: AppTheme.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Bar Indikator Kekuatan Password
  Widget _buildPasswordStrengthBar(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) strength++;

    Color barColor = const Color(0xFFE8DFC8);
    String label = 'Minimal 8 karakter';

    if (password.isNotEmpty) {
      if (strength == 1) {
        barColor = const Color(0xFFE57373); // Merah muda
        label = 'Kekuatan: Cukup (disarankan gunakan kombinasi angka/huruf besar)';
      } else if (strength == 2) {
        barColor = const Color(0xFFFFB74D); // Amber
        label = 'Kekuatan: Sedang (tambahkan simbol unik)';
      } else if (strength >= 3) {
        barColor = const Color(0xFF66BB6A); // Hijau
        label = 'Kekuatan: Sangat Kuat ✓';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (index) {
            final active = index < strength;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                decoration: BoxDecoration(
                  color: active ? barColor : const Color(0xFFE8DFC8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTheme.plusJakartaSans(
            fontSize: 11.5,
            color: password.isNotEmpty && strength >= 3
                ? const Color(0xFF2E7D32)
                : const Color(0xFF8A7D70),
          ),
        ),
      ],
    );
  }
}
