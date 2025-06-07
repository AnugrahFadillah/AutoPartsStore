import 'package:hive/hive.dart';

part 'wishlist.g.dart'; // Ini akan dibuat otomatis oleh hive_generator

@HiveType(typeId: 2) // typeId unik untuk model Wishlist
class Wishlist extends HiveObject {
  @HiveField(0)
  String id; // ID unik untuk item wishlist

  @HiveField(1)
  String userId; // ID pengguna yang memiliki wishlist ini

  @HiveField(2)
  String sparepartId; // ID sparepart yang ada di wishlist

  @HiveField(3)
  DateTime addedDate; // Tanggal ditambahkan ke wishlist

  Wishlist({
    required this.id,
    required this.userId,
    required this.sparepartId,
    required this.addedDate,
  });

  // Metode toMap atau toJson (opsional)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sparepartId': sparepartId,
      'addedDate': addedDate.toIso8601String(),
    };
  }

  // Factory constructor fromJson (opsional, jika wishlist bisa dari API)
  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      id: json['id'] as String,
      userId: json['userId'] as String,
      sparepartId: json['sparepartId'] as String,
      addedDate: DateTime.parse(json['addedDate'] as String),
    );
  }
}
