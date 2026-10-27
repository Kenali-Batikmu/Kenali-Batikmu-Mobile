import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Langkah 1: Input Alamat Email untuk pengiriman kode OTP pemulihan kata sandi
class ForgotPasswordStep1Email extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final VoidCallback onSendOtp;
  final bool isLoading;

  const ForgotPasswordStep1Email({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.onSendOtp,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
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
            controller: emailController,
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
              onPressed: isLoading ? null : onSendOtp,
              child: isLoading
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
}
