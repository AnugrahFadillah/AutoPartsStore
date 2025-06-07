// lib/models/bengkel_model.dart
class Bengkel {
  final String id;
  final String name;
  final String address;
  final double latitude; // Lintang
  final double longitude; // Bujur

  Bengkel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  // Factory constructor untuk mengurai data JSON dari TomTom API
  factory Bengkel.fromJson(Map<String, dynamic> json) {
    // Untuk TomTom API
    if (json.containsKey('position')) {
      final point = json['position'] as Map<String, dynamic>;
      final addressData = json['address'] as Map<String, dynamic>?;
      final poiData = json['poi'] as Map<String, dynamic>?;

      return Bengkel(
        id: json['id'].toString(),
        name: poiData?['name'] as String? ?? 'Nama Bengkel Tidak Diketahui',
        latitude: (point['lat'] as num).toDouble(),
        longitude: (point['lon'] as num).toDouble(),
        address:
            addressData?['freeformAddress'] as String? ??
            'Alamat Tidak Diketahui',
      );
    }
    // Untuk backend sendiri (jaga-jaga jika pakai API backend)
    return Bengkel(
      id: json['id'].toString(),
      name: json['name'],
      address: json['address'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
