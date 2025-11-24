import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminScaffold extends StatelessWidget {
  final Widget child;
  const AdminScaffold({super.key, required this.child});

  // Helper untuk menentukan tab aktif (Sekarang ada 6 index: 0 s/d 5)
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/admin/dashboard')) return 0;
    if (location.startsWith('/admin/properties')) return 1;
    if (location.startsWith('/admin/verification')) return 2;
    if (location.startsWith('/admin/tenants')) return 3;
    if (location.startsWith('/admin/reports')) return 4;
    if (location.startsWith('/admin/profile')) return 5; // Tab Baru
    return 0;
  }

  // Helper navigasi
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/admin/dashboard');
        break;
      case 1:
        context.go('/admin/properties');
        break;
      case 2:
        context.go('/admin/verification');
        break;
      case 3:
        context.go('/admin/tenants');
        break;
      case 4:
        context.go('/admin/reports');
        break;
      case 5:
        context.go('/admin/profile'); // Navigasi ke Profil
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        // Tips UX: Karena ada 6 item, kita matikan label agar tidak berantakan
        // atau gunakan labelBehavior: NavigationDestinationLabelBehavior.alwaysShow 
        // jika ingin tetap memaksa teks muncul.
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dash',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work),
            label: 'Properti',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user),
            label: 'Verif', // Disingkat agar muat
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Penyewa',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}