import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Langkah 3: Input Kata Sandi Baru dan Konfirmasi Kata Sandi
class ForgotPasswordStep3Password extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onFinalize;
  final bool isLoading;

  const ForgotPasswordStep3Password({
    super.key,
    required this.formKey,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.onFinalize,
    required this.isLoading,
  });

  @override
  State<ForgotPasswordStep3Password> createState() => _ForgotPasswordStep3PasswordState();
}

class _ForgotPasswordStep3PasswordState extends State<ForgotPasswordStep3Password> {
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
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
            controller: widget.newPasswordController,
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
          _buildPasswordStrengthBar(widget.newPasswordController.text),
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
            controller: widget.confirmPasswordController,
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
              if (value != widget.newPasswordController.text) {
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
              onPressed: widget.isLoading ? null : widget.onFinalize,
              child: widget.isLoading
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
