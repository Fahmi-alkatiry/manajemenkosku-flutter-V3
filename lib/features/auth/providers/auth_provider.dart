import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../../core/services/storage_service.dart';

// --- STATE DEFINITION ---
// Kita definisikan state auth kita bisa berupa apa saja
abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// --- NOTIFIER ---
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final StorageService _storageService;

  AuthNotifier(this._authService, this._storageService) : super(AuthInitial()) {
    checkLoginStatus(); // Cek login saat aplikasi mulai
  }

  // 1. Cek status login (dipanggil saat App Start)
  Future<void> checkLoginStatus() async {
    final user = await _storageService.getUser();
    if (user != null) {
      state = AuthAuthenticated(user);
    } else {
      state = AuthUnauthenticated();
    }
  }

  // 2. Fungsi Login
  Future<void> login(String email, String password) async {
    state = AuthLoading();
    try {
      final result = await _authService.login(email, password);
      
      // Parsing data dari Backend
      final token = result['token'];
      final userData = result['user'];
      
      // Buat model user
      final user = UserModel.fromJson(userData, token: token);

      // Simpan ke HP
      await _storageService.saveAuthData(user, token);

      // Update State jadi Authenticated
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 3. Fungsi Logout
  Future<void> logout() async {
    await _storageService.clearAuthData();
    state = AuthUnauthenticated();
  }
}

// --- PROVIDER DEFINITION ---
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, StorageService());
});