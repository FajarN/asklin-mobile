import 'package:flutter/material.dart';
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
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _klinik;

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
        setState(() {
          _user = data['user'] as Map<String, dynamic>?;
          _klinik = (data['klinik'] ?? data) as Map<String, dynamic>?;
          _isLoading = false;
        });
        return;
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _apiClient.dio.post(ApiConstants.logout);
    } catch (_) {}
    await SecureStorageService.clearAll();

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
            // Header Merah dengan Avatar
            AsklinHeaderOrnament(
              height: 240,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 37,
                        backgroundColor: AppColors.softRed,
                        child: Icon(
                          isPengurus ? Icons.admin_panel_settings : Icons.person,
                          size: 45,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                    const SizedBox(height: 24),

                    // Tombol Keluar
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout, color: AppColors.primaryRed),
                        label: const Text(
                          'KELUAR DARI AKUN',
                          style: TextStyle(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        onPressed: _handleLogout,
                      ),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

