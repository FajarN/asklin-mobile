import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../home/presentation/main_navigation_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreeTerms = false;
  bool _isLoading = false;

  final _apiClient = ApiClient();

  Future<void> _handleRegister() async {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus menyetujui syarat & ketentuan.')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.register,
        data: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'nama_klinik': _clinicNameController.text.trim(),
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
          'device_name': 'flutter_mobile_app',
        },
      );

      if (response.data['success'] == true) {
        final token = response.data['data']['token'];
        await SecureStorageService.saveToken(token);
        await SecureStorageService.saveUserRole('Klinik');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Selamat datang di ASKLIN Mobile.'),
            backgroundColor: AppColors.statusGreen,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal melakukan pendaftaran. Pastikan data terisi benar.'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pendaftaran Akun Klinik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Formulir Akun Mandiri',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lengkapi data penanggung jawab dan klinik Anda di bawah ini.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Nama Lengkap Penanggung Jawab
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap / Pimpinan',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),

            // Nama Klinik
            TextField(
              controller: _clinicNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Klinik',
                prefixIcon: Icon(Icons.local_hospital_outlined),
              ),
            ),
            const SizedBox(height: 14),

            // Email
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Alamat Email Resmi',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),

            // Nomor HP / WA
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor WhatsApp / HP',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),

            // Password
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password (min. 8 karakter)',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 14),

            // Konfirmasi Password
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi Password',
                prefixIcon: Icon(Icons.lock_reset),
              ),
            ),
            const SizedBox(height: 16),

            // Persetujuan Syarat Ketentuan
            Row(
              children: [
                Checkbox(
                  value: _agreeTerms,
                  activeColor: AppColors.primaryRed,
                  onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                ),
                const Expanded(
                  child: Text(
                    'Saya menyetujui Anggaran Dasar & Anggaran Rumah Tangga (AD/ART) ASKLIN.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tombol Daftar
            AsklinPrimaryButton(
              text: 'DAFTAR SEKARANG',
              isLoading: _isLoading,
              icon: Icons.app_registration_rounded,
              onPressed: _handleRegister,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
