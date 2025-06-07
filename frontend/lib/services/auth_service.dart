import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart'; // Untuk hashing password
import '../models/user.dart';
import 'hive_service.dart'; // Untuk menyimpan data user di Hive

class AuthService {
  static const String _loggedInKey = 'isLoggedIn';
  static const String _userIdKey = 'currentUserId';

  // --- Registrasi Pengguna ---
  Future<bool> registerUser({
    required String username,
    required String password,
    required String email,
    String? imagePath, // Tambahkan parameter ini
  }) async {
    final userBox = HiveService.getUserBox();

    // Cek apakah username atau email sudah terdaftar
    final existingUser = userBox.values.cast<User?>().firstWhere(
      (user) => user?.username == username || user?.email == email,
      orElse: () => null,
    );

    if (existingUser != null) {
      // Pengguna sudah ada
      return false;
    }

    // Hash password sebelum menyimpan
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    // Buat objek User baru
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // ID unik sederhana
      username: username,
      password: hashedPassword, // Simpan password yang sudah di-hash
      email: email,
      imagePath: imagePath, // <-- Tambahkan ini
      // Tambahkan data lain jika diperlukan
    );

    await HiveService.addUser(newUser); // Simpan user ke Hive
    return true; // Registrasi berhasil
  }

  // --- Login Pengguna ---
  Future<User?> loginUser({
    required String username,
    required String password,
  }) async {
    final userBox = HiveService.getUserBox();

    // Cari pengguna berdasarkan username
    final user = userBox.values.cast<User?>().firstWhere(
      (u) => u?.username == username,
      orElse: () => null,
    );

    if (user != null && BCrypt.checkpw(password, user.password)) {
      // Password cocok, login berhasil
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loggedInKey, true);
      await prefs.setString(
        _userIdKey,
        user.id,
      ); // Simpan ID pengguna yang login
      return user;
    } else {
      // Username atau password salah
      return null;
    }
  }

  // --- Logout Pengguna ---
  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_userIdKey);
  }

  // --- Mengecek Status Login ---
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  // --- Mendapatkan ID Pengguna yang Sedang Login ---
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // --- Mendapatkan Objek Pengguna yang Sedang Login ---
  Future<User?> getCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId != null) {
      return HiveService.getUser(userId);
    }
    return null;
  }

  // Update profil pengguna (opsional, bisa dipindah ke HiveService jika mau)
  Future<bool> updateProfile(User user) async {
    try {
      await HiveService.updateUser(user);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
}
