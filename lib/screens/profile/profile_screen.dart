import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../providers/app_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _cardColor = Color(0xFF2B231D);
  static const Color _headerColor = Color(0xFF5A3416);

  // ---------------------------------------------------------------------------
  // Simpan perubahan profil. Field yang tidak diubah memakai nilai saat ini.
  // ---------------------------------------------------------------------------
  Future<void> _saveProfile(
    BuildContext context,
    UserModel? user, {
    String? name,
    String? email,
    String? phone,
    String? password,
  }) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.updateProfile(
      name: (name ?? user?.name ?? '').trim(),
      email: (email ?? user?.email ?? '').trim(),
      phone: (phone ?? user?.phone ?? '').trim(),
      password: (password ?? '').trim(), // kosong = kata sandi tidak diubah
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom sheet edit satu field (Nama / Kata Sandi / Nomor HP / Email)
  // ---------------------------------------------------------------------------
  void _showEditFieldModal(
    BuildContext context, {
    required String title,
    required String label,
    required String initialValue,
    required TextInputType keyboardType,
    required Future<void> Function(String value) onSave,
    bool obscure = false,
    String? Function(String value)? validator,
  }) {
    final controller = TextEditingController(text: initialValue);
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    obscureText: obscure,
                    keyboardType: keyboardType,
                    autofocus: true,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: label,
                      errorText: errorText,
                      labelStyle: const TextStyle(color: AppTheme.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.black12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.primary),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final value = controller.text.trim();
                        final error = validator?.call(value);
                        if (error != null) {
                          setModalState(() => errorText = error);
                          return;
                        }
                        await onSave(value);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profil berhasil diperbarui')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Foto profil: file lokal (Android/iOS) atau URL/blob (web)
  // ---------------------------------------------------------------------------
  ImageProvider? _avatarImage(String? path) {
    if (path == null || path.isEmpty) return null;
    if (kIsWeb || path.startsWith('http')) return NetworkImage(path);
    return FileImage(File(path));
  }

  Future<void> _pickPhoto(BuildContext context, ImageSource source) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return; // dibatalkan pengguna
      final ok = await provider.setProfilePhoto(picked.path);
      messenger.showSnackBar(
        SnackBar(content: Text(ok ? 'Foto profil berhasil diperbarui' : 'Foto gagal disimpan. Coba lagi.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka kamera/galeri. Periksa izin aplikasi.')),
      );
    }
  }

  void _showPhotoOptions(BuildContext context, UserModel? user) {
    final hasPhoto = user?.profileImagePath != null && user!.profileImagePath!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Ubah Foto Profil', style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildPhotoOption(
                  icon: Icons.photo_camera_outlined,
                  label: 'Ambil dari kamera',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(context, ImageSource.camera);
                  },
                ),
                _buildPhotoOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Pilih dari galeri',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(context, ImageSource.gallery);
                  },
                ),
                if (hasPhoto)
                  _buildPhotoOption(
                    icon: Icons.delete_outline,
                    label: 'Hapus foto',
                    color: const Color(0xFFC0392B),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      await Provider.of<AppProvider>(context, listen: false).removeProfilePhoto();
                      messenger.showSnackBar(const SnackBar(content: Text('Foto profil dihapus')));
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? AppTheme.accentGold),
      title: Text(
        label,
        style: color == null
            ? AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold)
            : AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold, color: color),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Keluar dari Akun?', style: AppTheme.satoshi(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text(
            'Anda dapat masuk kembali kapan saja untuk melanjutkan latihan canting dan modul belajar.',
            style: AppTheme.inter(fontSize: 13, color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: AppTheme.inter(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final provider = Provider.of<AppProvider>(context, listen: false);
                await provider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A4B29),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    final canPop = Navigator.of(context).canPop();
    final topPad = MediaQuery.of(context).padding.top;
    final avatarImage = _avatarImage(user?.profileImagePath);

    const double avatarSize = 108;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // ikon status bar putih di atas header cokelat
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // --- Header cokelat melengkung + motif kawung (avatar & nama di dalamnya) ---
              Stack(
                children: [
                  Positioned.fill(
                    child: ClipPath(
                      clipper: _CurvedHeaderClipper(),
                      child: Container(
                        color: _headerColor,
                        child: CustomPaint(
                          painter: _KawungPainter(),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: topPad + 8, bottom: 52),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Baris judul: tombol kembali + "Profil Saya"
                          SizedBox(
                            height: 44,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (canPop)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: GestureDetector(
                                        onTap: () => Navigator.of(context).pop(),
                                        child: Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.18),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
                                        ),
                                      ),
                                    ),
                                  Text(
                                    'Profil Saya',
                                    style: AppTheme.satoshi(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Avatar + tombol edit foto
                          GestureDetector(
                            onTap: () => _showPhotoOptions(context, user),
                            child: Stack(
                              children: [
                                Container(
                                  width: avatarSize,
                                  height: avatarSize,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.accentGold, width: 3),
                                    image: avatarImage != null ? DecorationImage(image: avatarImage, fit: BoxFit.cover) : null,
                                  ),
                                  child: avatarImage == null
                                      ? Center(
                                          child: Text(
                                            (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'S',
                                            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGold,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _headerColor, width: 2),
                                    ),
                                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          Text(
                            user?.name ?? 'Sekar Ayu Kinanti',
                            style: AppTheme.satoshi(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Akun Kenali Batikmu',
                            style: AppTheme.inter(fontSize: 12, color: AppTheme.accentGold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ------------------------------ Konten ------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      // ------------------------ Kartu data profil -------------------------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              icon: Icons.person_outline,
                              label: 'Nama',
                              value: user?.name ?? '-',
                              onEdit: () => _showEditFieldModal(
                                context,
                                title: 'Ubah Nama',
                                label: 'Nama Lengkap',
                                initialValue: user?.name ?? '',
                                keyboardType: TextInputType.name,
                                validator: (v) => v.isEmpty ? 'Nama tidak boleh kosong' : null,
                                onSave: (v) => _saveProfile(context, user, name: v),
                              ),
                            ),
                            _buildDivider(),
                            _buildInfoRow(
                              icon: Icons.lock_outline,
                              label: 'Kata Sandi',
                              value: '••••••••••',
                              onEdit: () => _showEditFieldModal(
                                context,
                                title: 'Ubah Kata Sandi',
                                label: 'Kata Sandi Baru',
                                initialValue: '',
                                keyboardType: TextInputType.visiblePassword,
                                obscure: true,
                                validator: (v) => v.isEmpty ? 'Kata sandi baru tidak boleh kosong' : null,
                                onSave: (v) => _saveProfile(context, user, password: v),
                              ),
                            ),
                            _buildDivider(),
                            _buildInfoRow(
                              icon: Icons.phone_outlined,
                              label: 'Nomor Telepon',
                              value: (user?.phone != null && user!.phone!.isNotEmpty) ? user.phone! : 'Belum diisi',
                              onEdit: () => _showEditFieldModal(
                                context,
                                title: 'Ubah Nomor Telepon',
                                label: 'Nomor HP',
                                initialValue: user?.phone ?? '',
                                keyboardType: TextInputType.phone,
                                onSave: (v) => _saveProfile(context, user, phone: v),
                              ),
                            ),
                            _buildDivider(),
                            _buildInfoRow(
                              icon: Icons.mail_outline,
                              label: 'Alamat Email',
                              value: user?.email ?? '-',
                              onEdit: () => _showEditFieldModal(
                                context,
                                title: 'Ubah Alamat Email',
                                label: 'Email',
                                initialValue: user?.email ?? '',
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => (v.isEmpty || !v.contains('@')) ? 'Masukkan email yang valid' : null,
                                onSave: (v) => _saveProfile(context, user, email: v),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ---------------------------- Keluar dari akun ----------------------
                      OutlinedButton.icon(
                        onPressed: () => _showLogoutDialog(context),
                        icon: const Icon(Icons.logout, size: 16, color: Color(0xFF7A4B29)),
                        label: const Text(
                          'Keluar dari Akun',
                          style: TextStyle(color: Color(0xFF7A4B29), fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: Color(0xFFD4A373)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Colors.white12);
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentGold, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.inter(fontSize: 11, color: Colors.white60)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.edit_outlined, color: AppTheme.accentGold, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Potongan melengkung di bagian bawah header
// -----------------------------------------------------------------------------
class _CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 26)
      ..quadraticBezierTo(size.width / 2, size.height + 8, 0, size.height - 26)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// -----------------------------------------------------------------------------
// Motif kawung emas tipis yang diulang di seluruh header
// -----------------------------------------------------------------------------
class _KawungPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppTheme.accentGold.withValues(alpha: 0.3);

    const double cell = 40;
    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        canvas.drawOval(Rect.fromCenter(center: Offset(x + 20, y + 9), width: 12, height: 18), paint);
        canvas.drawOval(Rect.fromCenter(center: Offset(x + 20, y + 31), width: 12, height: 18), paint);
        canvas.drawOval(Rect.fromCenter(center: Offset(x + 9, y + 20), width: 18, height: 12), paint);
        canvas.drawOval(Rect.fromCenter(center: Offset(x + 31, y + 20), width: 18, height: 12), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}