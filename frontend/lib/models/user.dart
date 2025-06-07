import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';

part 'user.g.dart'; // Ini akan dibuat otomatis oleh hive_generator

@HiveType(typeId: 0) // typeId harus unik untuk setiap model Hive
class User extends HiveObject {
  @HiveField(0)
  String id; // ID unik untuk pengguna

  @HiveField(1)
  String username;

  @HiveField(2)
  String email;

  @HiveField(3)
  String password; // Password yang sudah di-hash

  @HiveField(4)
  String? imagePath; // Path ke gambar profil (opsional)

  @HiveField(5)
  String? notes; // Contoh untuk menyimpan saran/kesan atau catatan lain

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    this.imagePath,
    this.notes,
  });

  copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    String? imagePath,
    String? notes,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
    );
  }

  // Metode toMap atau toJson (opsional, jika nanti perlu dikirim ke backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      // Jangan pernah kirim password yang belum di-hash atau sensitif langsung
      // Jika perlu, pastikan sudah di-hash!
      // 'password': password,
      'imagePath': imagePath,
      'notes': notes,
    };
  }

  // Factory constructor untuk membuat objek User dari JSON (jika User bisa dari API)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      // Pastikan password sudah di-hash jika memang harus diambil dari API
      password: (json['password'] ?? '') as String,
      imagePath: json['imagePath'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
