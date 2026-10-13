import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../agenda/presentation/agenda_screen.dart';
import '../../berita/presentation/berita_screen.dart';
import '../../dashboard/presentation/member_dashboard_screen.dart';
import '../../organisasi/presentation/organisasi_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MemberDashboardScreen(), // Dasbor Keanggotaan
    BeritaScreen(),          // Berita & Artikel
    AgendaScreen(),          // Agenda & Kongres
    OrganisasiScreen(),      // Direktori Organisasi (DPP/DPD/DPC)
    ProfileScreen(),         // Profil & Pengaturan
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Keanggotaan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper),
              label: 'Berita',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              activeIcon: Icon(Icons.event),
              label: 'Agenda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_tree_outlined),
              activeIcon: Icon(Icons.account_tree),
              label: 'Organisasi',
            ),
            BottomNavigationBarItem(
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
