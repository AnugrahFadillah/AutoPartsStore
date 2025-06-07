import 'package:hive/hive.dart';

part 'sparepart.g.dart';

@HiveType(typeId: 1)
class Sparepart extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String brand;

  @HiveField(3)
  double price;

  @HiveField(4)
  int stock;

  @HiveField(5)
  String? description;

  @HiveField(6)
  String? imageUrl;

  Sparepart({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.stock,
    this.description,
    this.imageUrl,
  });

  factory Sparepart.fromJson(Map<String, dynamic> json) {
    return Sparepart(
      id: json['id'].toString(),
      name: json['name'],
      brand: json['brand'],
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      description: json['description'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'stock': stock,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}
