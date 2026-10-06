import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../dashboard/main_navigation_screen.dart';
import '../legal/terms_and_privacy_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan setujui Syarat & Kebijakan Privasi terlebih dahulu',
            style: AppTheme.inter(color: Colors.white),
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    final success = await provider.register(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Gagal membuat akun',
            style: AppTheme.inter(color: Colors.white),
          ),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Top Badge Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4ECE4),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, color: AppTheme.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'KENALI BATIKMU',
                          style: AppTheme.satoshi(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Headline
                Text(
                  'Daftar ke Kenali Batikmu',
                  textAlign: TextAlign.center,
                  style: AppTheme.satoshi(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mulai perjalanan belajar mencanting & mengeksplorasi ragam batik nusantara.',
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field Nama Lengkap
                      Text(
                        'Nama Lengkap',
                        style: AppTheme.satoshi(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: AppTheme.inter(fontSize: 14),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline, color: AppTheme.textMuted, size: 20),
                          hintText: 'cth. Sekar Ayu Wardani',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama lengkap tidak boleh kosong';
                          }
                          if (value.trim().length < 2) {
                            return 'Nama terlalu pendek';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Field Email
                      Text(
                        'Email',
                        style: AppTheme.satoshi(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTheme.inter(fontSize: 14),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textMuted, size: 20),
                          hintText: 'nama@email.com',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Field Kata Sandi
                      Text(
                        'Kata Sandi',
                        style: AppTheme.satoshi(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: AppTheme.inter(fontSize: 14),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 20),
                          hintText: 'Minimal 8 karakter',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppTheme.textMuted,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kata sandi tidak boleh kosong';
                          }
                          if (value.length < 8) {
                            return 'Kata sandi minimal 8 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Checkbox Persetujuan Syarat & Privasi
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreeToTerms,
                              activeColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              onChanged: (val) {
                                setState(() => _agreeToTerms = val ?? false);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Saya menyetujui ',
                                  style: AppTheme.inter(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const TermsAndPrivacyScreen(isPrivacy: false)),
                                    );
                                  },
                                  child: Text(
                                    'Syarat',
                                    style: AppTheme.satoshi(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                                Text(
                                  ' & ',
                                  style: AppTheme.inter(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const TermsAndPrivacyScreen(isPrivacy: true)),
                                    );
                                  },
                                  child: Text(
                                    'Kebijakan Privasi',
                                    style: AppTheme.satoshi(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: provider.isLoading ? null : _handleRegister,
                        child: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Daftar Sekarang',
                                    style: AppTheme.satoshi(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Back to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sudah punya akun? ',
                      style: AppTheme.inter(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Masuk',
                        style: AppTheme.satoshi(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Footer Tag
                Center(
                  child: Text(
                    'PLATFORM EDUKASI BATIK NUSANTARA',
                    style: AppTheme.satoshi(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
