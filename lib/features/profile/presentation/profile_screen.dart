import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/login_screen.dart';
import 'change_password_screen.dart';
import 'help_center_screen.dart';
import 'about_screen.dart';
import '../../dashboard/presentation/pendaftaran_anggota_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiClient = ApiClient();
  final _picker = ImagePicker();

  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _klinik;
  String? _fotoUrl;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await _apiClient.dio.get(ApiConstants.profile);
      if (res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _user = data['user'] as Map<String, dynamic>?;
            _klinik = (data['klinik'] ?? data) as Map<String, dynamic>?;
            _fotoUrl = data['foto_url'] ?? _user?['foto_url'] ?? _klinik?['foto_url'];
            _isLoading = false;
          });
        }
        return;
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final file = File(picked.path);
      final fileName = file.path.split(Platform.pathSeparator).last;

      final formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final res = await _apiClient.dio.post(
        ApiConstants.updatePhoto,
        data: formData,
      );

      if (res.data['success'] == true) {
        final newUrl = res.data['data']?['foto_url'];
        if (mounted) {
          setState(() {
            if (newUrl != null) _fotoUrl = newUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil diperbarui!'),
              backgroundColor: AppColors.statusGreen,
            ),
          );
        }
        await _fetchProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah foto profil: $e'),
            backgroundColor: AppColors.statusRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ubah Foto Profil',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih foto baru dari kamera atau galeri untuk foto profil akun Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.softRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primaryRed),
                ),
                title: const Text('Ambil dari Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.softRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.primaryRed),
                ),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _apiClient.dio.post(ApiConstants.logout);
    } catch (_) {}
    // Clear token & user session only, keep saved credentials
    await SecureStorageService.clearSession();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
      );
    }

    final isPengurus = _klinik?['is_pengurus'] == true || _user?['primary_role'] == 'Superadmin';
    final name = _user?['name'] ?? _klinik?['nama_pemilik_klinik'] ?? _klinik?['nama_klinik'] ?? 'Pengguna ASKLIN';
    final email = _user?['email'] ?? _klinik?['kontak']?['email'] ?? _klinik?['email'] ?? '-';
    final role = _user?['primary_role'] ?? (isPengurus ? 'Superadmin' : 'Klinik');
    final namaKlinik = _klinik?['nama_klinik'] ?? (isPengurus ? 'Pengurus Pusat ASKLIN' : '-');
    final noAnggota = _klinik?['no_anggota'] ?? (isPengurus ? 'Pengurus / Administrator' : 'Menunggu Verifikasi');
    final kota = _klinik?['alamat_lengkap']?['kota'] ?? _klinik?['wilayah']?['kota'] ?? (isPengurus ? 'DKI Jakarta (Pusat)' : 'Kab/Kota Terdaftar');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        onRefresh: _fetchProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header Merah dengan Avatar Klik & Edit
              AsklinHeaderOrnament(
                height: 250,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                        borderRadius: BorderRadius.circular(50),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 41,
                                backgroundColor: AppColors.softRed,
                                backgroundImage: (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                                    ? NetworkImage(_fotoUrl!)
                                    : null,
                                child: (_fotoUrl == null || _fotoUrl!.isEmpty)
                                    ? Icon(
                                        isPengurus ? Icons.admin_panel_settings : Icons.local_hospital,
                                        size: 42,
                                        color: AppColors.primaryRed,
                                      )
                                    : null,
                              ),
                            ),
                            if (_isUploadingPhoto)
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryRed,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              // Card Informasi Akun & Klinik
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Transform.translate(
                  offset: const Offset(0, -25),
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPengurus ? 'Informasi Akun Pengurus' : 'Informasi Keanggotaan',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Divider(height: 20),
                              _ProfileItem(
                                icon: Icons.badge_outlined,
                                label: 'Peran Pengguna',
                                value: role,
                              ),
                              _ProfileItem(
                                icon: isPengurus ? Icons.security : Icons.local_hospital_outlined,
                                label: isPengurus ? 'Instansi / Organisasi' : 'Nama Klinik',
                                value: namaKlinik,
                              ),
                              _ProfileItem(
                                icon: Icons.confirmation_number_outlined,
                                label: isPengurus ? 'Status Jabatan' : 'Nomor Anggota',
                                value: noAnggota,
                              ),
                              _ProfileItem(
                                icon: Icons.location_on_outlined,
                                label: isPengurus ? 'Wilayah Kepengurusan' : 'Wilayah Cabang',
                                value: kota,
                              ),
                              if (!isPengurus) ...[
                                const Divider(height: 20),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.assignment_outlined, color: AppColors.primaryRed),
                                  title: const Text('Formulir Pendaftaran Faskes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  subtitle: const Text('Ubah atau lengkapi data klinik & dokter PJ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  trailing: const Icon(Icons.chevron_right, size: 20),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => PendaftaranAnggotaScreen(initialData: _klinik)),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pengaturan & Bantuan
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.security, color: AppColors.primaryRed),
                              title: const Text('Ganti Password', style: TextStyle(fontSize: 14)),
                              trailing: const Icon(Icons.chevron_right, size: 20),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.help_outline, color: AppColors.primaryRed),
                              title: const Text('Pusat Bantuan & Kontak Pengurus', style: TextStyle(fontSize: 14)),
                              subtitle: const Text('+62 823-1098-1637 (WhatsApp/Call)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              trailing: const Icon(Icons.chevron_right, size: 20),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.info_outline, color: AppColors.primaryRed),
                              title: const Text('Tentang ASKLIN Mobile (v1.0.0)', style: TextStyle(fontSize: 14)),
                              trailing: const Icon(Icons.chevron_right, size: 20),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tombol Logout
                      AsklinSecondaryButton(
                        text: 'KELUAR DARI APLIKASI',
                        icon: Icons.logout,
                        textColor: AppColors.primaryRed,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Konfirmasi Logout'),
                              content: const Text('Apakah Anda yakin ingin keluar dari aplikasi ASKLIN?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _handleLogout();
                                  },
                                  child: const Text('Ya, Keluar', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
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
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
