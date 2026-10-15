import 'package:flutter/material.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../agenda/presentation/agenda_screen.dart';
import '../../berita/presentation/berita_screen.dart';
import '../../dashboard/presentation/member_dashboard_screen.dart';
import '../../organisasi/presentation/organisasi_screen.dart';
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

    final List<Widget> pages = [
      _isPengurus ? const PengurusVerifikasiScreen() : const MemberDashboardScreen(),
      const BeritaScreen(),
      const AgendaScreen(),
      const OrganisasiScreen(),
      const ProfileScreen(),
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
          items: [
            BottomNavigationBarItem(
              icon: Icon(_isPengurus ? Icons.verified_user_outlined : Icons.dashboard_outlined),
              activeIcon: Icon(_isPengurus ? Icons.verified_user : Icons.dashboard),
              label: _isPengurus ? 'Verifikasi' : 'Keanggotaan',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper),
              label: 'Berita',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              activeIcon: Icon(Icons.event),
              label: 'Agenda',
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
          ],
        ),
      ),
    );
  }
}
