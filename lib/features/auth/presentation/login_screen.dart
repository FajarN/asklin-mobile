import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../home/presentation/main_navigation_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true;
  String _selectedRole = 'Anggota Klinik'; // Tab selector

  final _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final savedEmail = await SecureStorageService.getSavedEmail();
    final savedPass = await SecureStorageService.getSavedPassword();
    final isRemembered = await SecureStorageService.isRememberMeEnabled();
    if (mounted && savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        if (savedPass != null && savedPass.isNotEmpty) {
          _passwordController.text = savedPass;
        }
        _rememberMe = isRemembered;
      });
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan email dan password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
          'device_name': 'flutter_mobile_app',
        },
      );

      if (response.data['success'] == true) {
        final token = response.data['data']['token'];
        final user = response.data['data']['user'];
        final role = user['primary_role'] ?? 'Klinik';

        await SecureStorageService.saveToken(token);
        await SecureStorageService.saveUserRole(role);

        if (_rememberMe) {
          await SecureStorageService.saveSavedCredentials(email, password);
        } else {
          await SecureStorageService.clearSavedCredentials();
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal masuk. Periksa email dan password Anda.'),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Ornament Melengkung
            AsklinHeaderOrnament(
              height: 250,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/ic_launcher.png',
                          height: 56,
                          width: 56,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ASKLIN MOBILE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Text(
                      'Asosiasi Klinik Indonesia',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form Login
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masuk ke Akun Anda',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih peran dan masukkan kredensial untuk melanjutkan.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Role Selector Chips (Anggota vs Pengurus)
                  Row(
                    children: [
                      Expanded(
                        child: AsklinCategoryChip(
                          label: 'Anggota Klinik',
                          isSelected: _selectedRole == 'Anggota Klinik',
                          onTap: () => setState(() => _selectedRole = 'Anggota Klinik'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AsklinCategoryChip(
                          label: 'Pengurus Organisasi',
                          isSelected: _selectedRole == 'Pengurus Organisasi',
                          onTap: () => setState(() => _selectedRole = 'Pengurus Organisasi'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Input Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Email',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Opsi Simpan Password / Ingat Saya
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: AppColors.primaryRed,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _rememberMe = val ?? true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        child: const Text(
                          'Simpan Password & Akun (Ingat Saya)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tombol Masuk
                  AsklinPrimaryButton(
                    text: 'MASUK SEKARANG',
                    isLoading: _isLoading,
                    icon: Icons.login_rounded,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 20),

                  // Opsi Daftar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum memiliki akun klinik? ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Daftar di sini',
                          style: TextStyle(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

