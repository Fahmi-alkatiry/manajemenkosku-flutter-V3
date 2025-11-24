import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
// 1. TAMBAHKAN IMPORT INI
import 'package:intl/date_symbol_data_local.dart'; 

import 'core/router/app_router.dart';

// 2. UBAH main() MENJADI ASYNC
void main() async {
  // Pastikan binding flutter sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // 3. TAMBAHKAN BARIS INI (Muat data bahasa Indonesia)
  await initializeDateFormatting('id_ID', null);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 3. Ambil konfigurasi router dari provider yang sudah kita buat
    final routerConfig = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Manajemen Kos',
      debugShowCheckedModeBanner: false, // Hilangkan pita debug di pojok kanan atas

      // 4. Konfigurasi Tema (Global Theme)
      // Kita set font default jadi Poppins dan warna utama Biru
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          primary: Colors.blueAccent, // Warna utama Admin
          secondary: Colors.orange, // Warna aksen (misal: tombol bayar/pending)
        ),
        useMaterial3: true, // Gunakan desain Material 3 yang lebih baru
        
        // Terapkan Google Fonts Poppins ke seluruh teks aplikasi
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        
        // Default style untuk AppBar (Putih bersih)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87, // Warna teks judul
          elevation: 0,
          centerTitle: true,
        ),
        
        // Warna background halaman default (sedikit abu-abu agar kartu terlihat menonjol)
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),

      // 5. Pasang konfigurasi GoRouter
      routerConfig: routerConfig,
    );
  }
}