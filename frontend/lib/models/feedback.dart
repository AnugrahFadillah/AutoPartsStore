import 'package:hive/hive.dart';

part 'feedback.g.dart';

@HiveType(typeId: 3) // Ganti ke angka yang belum dipakai
class FeedbackModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String username;

  @HiveField(3)
  String message;

  @HiveField(4)
  DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.message,
    required this.createdAt,
  });
}
