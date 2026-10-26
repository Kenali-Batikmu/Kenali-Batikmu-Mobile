import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import 'widgets/forgot_password_step_indicator.dart';
import 'widgets/forgot_password_success_dialog.dart';
import 'widgets/forgot_password_step1_email.dart';
import 'widgets/forgot_password_step2_otp.dart';
import 'widgets/forgot_password_step3_password.dart';

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
      showForgotPasswordSuccessDialog(
        context: context,
        email: _emailController.text.trim(),
      );
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

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
    final provider = context.watch<AppProvider>();

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
                                // Stepper Indikator
                                ForgotPasswordStepIndicator(currentStep: _currentStep),
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
                                        child: _buildCurrentStepContent(provider),
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

  Widget _buildCurrentStepContent(AppProvider provider) {
    switch (_currentStep) {
      case 0:
        return ForgotPasswordStep1Email(
          formKey: _emailFormKey,
          emailController: _emailController,
          onSendOtp: _handleSendOtp,
          isLoading: provider.isLoading,
        );
      case 1:
        return ForgotPasswordStep2Otp(
          email: _emailController.text,
          otpControllers: _otpControllers,
          otpFocusNodes: _otpFocusNodes,
          onVerifyOtp: _handleVerifyOtp,
          onResendOtp: _handleSendOtp,
          onChangeEmail: () => setState(() => _currentStep = 0),
          resendSeconds: _resendSeconds,
          canResend: _canResend,
          isLoading: provider.isLoading,
          deliveryNotice: _deliveryNotice,
          isDemoNotice: _isDemoNotice,
        );
      case 2:
        return ForgotPasswordStep3Password(
          formKey: _passwordFormKey,
          newPasswordController: _newPasswordController,
          confirmPasswordController: _confirmPasswordController,
          onFinalize: _handleFinalizePassword,
          isLoading: provider.isLoading,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
