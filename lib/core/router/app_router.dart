import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/admin/screens/admin_scaffold.dart';
import 'package:manajemen_kosku/features/admin/dashboard/screens/admin_dashboard_screen.dart';
import 'package:manajemen_kosku/features/admin/profile/screens/admin_profile_screen.dart';
import 'package:manajemen_kosku/features/admin/properties/screens/admin_properties_screen.dart';
import 'package:manajemen_kosku/features/admin/properties/screens/admin_property_detail_screen.dart';
import 'package:manajemen_kosku/features/admin/properties/screens/create_contract_screen.dart';
import 'package:manajemen_kosku/features/admin/properties/screens/active_contract_screen.dart';
import '../../features/admin/verification/screens/admin_verification_screen.dart';
import '../../features/admin/verification/screens/verification_detail_screen.dart';
import '../../features/admin/payments/models/payment_model.dart'; // Import Model

import '../../features/tenant/screens/tenant_scaffold.dart';
import '../../features/tenant/home/screens/tenant_home_screen.dart';
// import '../../features/admin/payments/models/payment_model.dart'; // Untuk casting object
import '../../features/tenant/profile/screens/tenant_profile_screen.dart';
import '../../features/tenant/home/screens/tenant_payment_screen.dart';
import '../../features/admin/payments/screens/create_bill_screen.dart';
import '../../features/admin/tenants/screens/admin_tenants_screen.dart';

// import '../../features/admin/tenants/screens/admin_tenants_screen.dart';
import '../../features/admin/tenants/screens/tenant_detail_screen.dart';
import '../../features/admin/tenants/models/tenant_crud_model.dart';
import '../../features/admin/reports/screens/admin_reports_screen.dart';


import '../../features/admin/profile/screens/edit_profile_screen.dart';
import '../../features/admin/profile/screens/change_password_screen.dart';
// import '../../features/admin/tenants/models/tenant_crud_model.dart'; 

// import '../../features/tenant/profile/screens/tenant_profile_screen.dart';
import '../../features/tenant/profile/screens/tenant_edit_profile_screen.dart';
import '../../features/tenant/profile/screens/tenant_change_password_screen.dart';



// --- SCREEN DUMMY (Hanya Sementara agar tidak Error) ---
// Kita akan ganti ini nanti dengan screen asli satu per satu
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text("Halaman $title \n(Sedang Dibuat)")),
      );
}

// Provider untuk Router
final routerProvider = Provider<GoRouter>((ref) {
  // Pantau perubahan state Auth
  // Ini akan membuat router me-refresh diri jika status login berubah
  final authState = ref.watch(authProvider);

  return GoRouter(
    // Gunakan navigatorKey jika butuh akses context global (opsional)
    initialLocation: '/login',
    
    routes: [
      // --- 1. LOGIN ROUTE ---
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // --- 2. ADMIN ROUTES (Shell) ---
      // ShellRoute digunakan untuk membuat Bottom Navigation Bar yang menetap
     ShellRoute(
        builder: (context, state, child) {
          return AdminScaffold(child: child); 
        },
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/properties',
            builder: (context, state) => const AdminPropertiesScreen(),
            routes: [
              GoRoute(
                path: 'detail/:id',
                builder: (context, state) {
                  // Ambil ID dari URL
                  final id = state.pathParameters['id'];
                  return AdminPropertyDetailScreen(propertyId: id!);
                },
                // ... (sub routes contract nanti disini)
                routes: [
                  // --- ROUTE BARU: BUAT KONTRAK ---
                  // URL akan menjadi: /admin/properties/detail/1/create-contract?roomId=5
                  GoRoute(
                    path: 'create-contract',
                    builder: (context, state) {
                      // Ambil Property ID dari parent route
                      final propId = state.pathParameters['id']!;
                      // Ambil Room ID dari Query Parameter (?roomId=...) 
                      // (Atau bisa pakai extra object, tapi query param lebih aman di web/refresh)
                      final roomId = state.uri.queryParameters['roomId']; 

                      final priceString = state.uri.queryParameters['price'] ?? '0';
                      final price = double.tryParse(priceString) ?? 0.0;

                      
                      return CreateContractScreen(
                        propertyId: propId, 
                        kamarId: roomId! ,
                        initialPrice: price,// Pastikan kirim roomId saat navigasi

                        
                      );
                    },
                  ),
                  GoRoute(
                  path: 'active-contract',
                  builder: (context, state) {
                    final propId = state.pathParameters['id']!;
                    final roomId = state.uri.queryParameters['roomId'];
                    return ActiveContractScreen(propertyId: propId, kamarId: roomId!);
                  },
                ),
                ]
              ),
            ],
          ),
         GoRoute(
            path: '/admin/verification',
            // GANTI PlaceholderScreen dengan:
            builder: (context, state) => const AdminVerificationScreen(),
            routes: [
                 GoRoute(
                    path: 'detail', // Tidak perlu :id karena pakai extra
                    builder: (context, state) {
                      // Ambil data PaymentModel dari parameter 'extra'
                      final payment = state.extra as PaymentModel; 
                      return VerificationDetailScreen(payment: payment);
                    },
                 ),
                 GoRoute(
                    path: 'create',
                    builder: (context, state) => const CreateBillScreen(),
                 ),
            ]
          ),
         GoRoute(
            path: '/admin/tenants',
            builder: (context, state) => const AdminTenantsScreen(),
            routes: [
              // Route Detail Penyewa
              GoRoute(
                path: 'detail',
                builder: (context, state) {
                  // Ambil object tenant dari extra
                  final tenant = state.extra as TenantCrudModel;
                  return TenantDetailScreen(tenant: tenant);
                },
              ),
            ]
          ),
          GoRoute(
            path: '/admin/reports',
           builder: (context, state) => const AdminReportsScreen(),
          ),
          // --- TAMBAHAN TAB KE-6: PROFIL ---
          GoRoute(
            path: '/admin/profile',
            builder: (context, state) => const AdminProfileScreen(),
            routes: [
              // Route Edit Profil
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final user = state.extra as TenantCrudModel;
                  return EditProfileScreen(user: user);
                },
              ),
              // Route Ganti Password
              GoRoute(
                path: 'password',
                builder: (context, state) => const ChangePasswordScreen(),
              ),
            ]
          ),
        ],
      ),

      // --- 3. TENANT ROUTES (Shell) ---
    ShellRoute(
        builder: (context, state, child) {
          return TenantScaffold(child: child); // Ganti Scaffold biasa dengan TenantScaffold
        },
        routes: [
          GoRoute(
            path: '/tenant/home',
            builder: (context, state) => const TenantHomeScreen(), // Ganti Placeholder
            routes: [
                // Route Halaman Pembayaran (Upload Bukti)
               GoRoute(
                    path: 'payment',
                    builder: (context, state) {
                      // Ambil data tagihan yang dikirim dari Home
                      // Pastikan data yang dikirim adalah PaymentModel
                      final bill = state.extra as PaymentModel;
                      return TenantPaymentScreen(bill: bill); // Halaman Asli
                    },
                )
            ]
          ),
         GoRoute(
            path: '/tenant/profile',
            builder: (context, state) => const TenantProfileScreen(),
            routes: [
              // Sub-routes Profil Penyewa
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  // Casting extra ke TenantCrudModel (model user yang sama)
                  final user = state.extra as TenantCrudModel;
                  return TenantEditProfileScreen(user: user);
                },
              ),
              GoRoute(
                path: 'password',
                builder: (context, state) => const TenantChangePasswordScreen(),
              ),
            ]
          ),
        ],
      ),
    ],

    // --- REDIRECT LOGIC (Penjaga Pintu) ---
    redirect: (context, state) {
      // Cek State User Saat Ini
      final isLoggedIn = authState is AuthAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      // 1. Jika belum login dan mencoba akses halaman selain login -> tendang ke login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // 2. Jika sudah login
      if (isLoggedIn) {
        final user = (authState as AuthAuthenticated).user;
        
        // Jika user ada di halaman login, pindahkan otomatis sesuai ROLE
        if (isLoggingIn) {
          if (user.role == 'ADMIN') {
            return '/admin/dashboard';
          } else {
            return '/tenant/home';
          }
        }
      }

      return null; // Tidak ada redirect, biarkan user masuk
    },
  );
});