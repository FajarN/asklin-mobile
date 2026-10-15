import 'package:flutter/material.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/presentation/member_dashboard_screen.dart';
import '../../informasi/presentation/informasi_screen.dart';
import '../../organisasi/presentation/organisasi_screen.dart';
import '../../pembayaran/presentation/konfirmasi_iuran_screen.dart';
import '../../pengurus/presentation/pengurus_data_anggota_screen.dart';
import '../../pengurus/presentation/pengurus_verifikasi_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isPengurus = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final role = await SecureStorageService.getUserRole();
    final roleLower = (role ?? '').toLowerCase();
    final isPengurus = roleLower.contains('cabang') ||
        roleLower.contains('daerah') ||
        roleLower.contains('sekjen') ||
        roleLower.contains('ketua') ||
        roleLower.contains('superadmin') ||
        roleLower.contains('pusat') ||
        roleLower.contains('bendahara');

    if (mounted) {
      setState(() {
        _isPengurus = isPengurus;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
      );
    }

    final List<Widget> pages = _isPengurus
        ? [
            const PengurusVerifikasiScreen(),
            const PengurusDataAnggotaScreen(),
            const InformasiScreen(),
            const OrganisasiScreen(),
            const ProfileScreen(),
          ]
        : [
            const MemberDashboardScreen(),
            const KonfirmasiIuranScreen(),
            const InformasiScreen(),
            const OrganisasiScreen(),
            const ProfileScreen(),
          ];

    final List<BottomNavigationBarItem> items = _isPengurus
        ? [
            const BottomNavigationBarItem(
              icon: Icon(Icons.verified_user_outlined),
              activeIcon: Icon(Icons.verified_user),
              label: 'Verifikasi',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt),
              label: 'Data Anggota',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'Informasi',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_tree_outlined),
              activeIcon: Icon(Icons.account_tree),
              label: 'Organisasi',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ]
        : [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Keanggotaan',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.payments_outlined),
              activeIcon: Icon(Icons.payments),
              label: 'Pembayaran',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'Informasi',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_tree_outlined),
              activeIcon: Icon(Icons.account_tree),
              label: 'Organisasi',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryRed,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: items,
        ),
      ),
    );
  }
}
