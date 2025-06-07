import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistService {
  static const String _key = 'user_wishlist';

  // Ambil list wishlist untuk user tertentu
  static Future<List<String>> getWishlist(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    final Map<String, dynamic> map = json.decode(data);
    final List<dynamic>? list = map[userId];
    return list?.cast<String>() ?? [];
  }

  // Tambah sparepartId ke wishlist user
  static Future<void> addToWishlist(String userId, String sparepartId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    Map<String, dynamic> map = data != null ? json.decode(data) : {};
    List<String> list = (map[userId] ?? []).cast<String>();
    if (!list.contains(sparepartId)) {
      list.add(sparepartId);
      map[userId] = list;
      await prefs.setString(_key, json.encode(map));
    }
  }

  // Hapus sparepartId dari wishlist user
  static Future<void> removeFromWishlist(
    String userId,
    String sparepartId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return;
    Map<String, dynamic> map = json.decode(data);
    List<String> list = (map[userId] ?? []).cast<String>();
    list.remove(sparepartId);
    map[userId] = list;
    await prefs.setString(_key, json.encode(map));
  }
}
