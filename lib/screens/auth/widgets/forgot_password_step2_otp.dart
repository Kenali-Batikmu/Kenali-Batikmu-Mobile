import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// Langkah 2: Verifikasi 4 digit PIN OTP yang dikirim ke email
class ForgotPasswordStep2Otp extends StatelessWidget {
  final String email;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final VoidCallback onVerifyOtp;
  final VoidCallback onResendOtp;
  final VoidCallback onChangeEmail;
  final int resendSeconds;
  final bool canResend;
  final bool isLoading;
  final String? deliveryNotice;
  final bool isDemoNotice;

  const ForgotPasswordStep2Otp({
    super.key,
    required this.email,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.onVerifyOtp,
    required this.onResendOtp,
    required this.onChangeEmail,
    required this.resendSeconds,
    required this.canResend,
    required this.isLoading,
    this.deliveryNotice,
    this.isDemoNotice = false,
  });

  @override
  Widget build(BuildContext context) {
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
                text: email.trim(),
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
        if (deliveryNotice != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDemoNotice
                  ? const Color(0xFFFFF3E0)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDemoNotice
                    ? const Color(0xFFFFB74D)
                    : const Color(0xFF81C784),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isDemoNotice
                      ? Icons.auto_awesome
                      : Icons.mark_email_read_rounded,
                  size: 18,
                  color: isDemoNotice
                      ? const Color(0xFFE65100)
                      : const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    deliveryNotice!,
                    style: AppTheme.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDemoNotice
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
                controller: otpControllers[index],
                focusNode: otpFocusNodes[index],
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
                      otpFocusNodes[index + 1].requestFocus();
                    } else {
                      otpFocusNodes[index].unfocus();
                      onVerifyOtp();
                    }
                  } else {
                    if (index > 0) {
                      otpFocusNodes[index - 1].requestFocus();
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
          child: canResend
              ? TextButton.icon(
                  onPressed: isLoading ? null : onResendOtp,
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
                      'Kirim ulang kode dalam 00:${resendSeconds.toString().padLeft(2, '0')}',
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
            onPressed: onVerifyOtp,
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
            onPressed: onChangeEmail,
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
}
