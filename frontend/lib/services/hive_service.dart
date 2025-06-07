import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/sparepart.dart';
import '../models/wishlist.dart';
import '../models/feedback.dart'; // Tambahkan import ini

class HiveService {
  // Nama Box untuk setiap model
  static const String _userBox = 'userBox';
  static const String _sparepartBox = 'sparepartBox';
  static const String _wishlistBox = 'wishlistBox';

  // Inisialisasi Hive
  static Future<void> initHive() async {
    await Hive.initFlutter();
    // Daftarkan adapter untuk setiap model (hanya jika belum terdaftar)
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SparepartAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(WishlistAdapter());
    if (!Hive.isAdapterRegistered(3))
      Hive.registerAdapter(FeedbackModelAdapter()); // <-- Tambahkan ini

    // Buka Box untuk setiap model
    await Hive.openBox<User>(_userBox);
    await Hive.openBox<Sparepart>(_sparepartBox);
    await Hive.openBox<Wishlist>(_wishlistBox);
    await Hive.openBox<FeedbackModel>('feedbacks'); // <-- Tambahkan ini juga
  }

  // --- Operasi untuk User ---
  static Box<User> getUserBox() {
    return Hive.box<User>(_userBox);
  }

  static Future<void> addUser(User user) async {
    await getUserBox().put(user.id, user); // Gunakan ID sebagai key
  }

  static User? getUser(String id) {
    return getUserBox().get(id);
  }

  static List<User> getAllUsers() {
    return getUserBox().values.toList();
  }

  static Future<void> updateUser(User user) async {
    await getUserBox().put(user.id, user);
  }

  static Future<void> deleteUser(String id) async {
    await getUserBox().delete(id);
  }

  // --- Operasi untuk Sparepart ---
  static Box<Sparepart> getSparepartBox() {
    return Hive.box<Sparepart>(_sparepartBox);
  }

  static Future<void> addSparepart(Sparepart sparepart) async {
    await getSparepartBox().put(sparepart.id, sparepart);
  }

  static Sparepart? getSparepart(String id) {
    return getSparepartBox().get(id);
  }

  static List<Sparepart> getAllSpareparts() {
    return getSparepartBox().values.toList();
  }

  static Future<void> updateSparepart(Sparepart sparepart) async {
    await getSparepartBox().put(sparepart.id, sparepart);
  }

  static Future<void> deleteSparepart(String id) async {
    await getSparepartBox().delete(id);
  }

  // --- Operasi untuk Wishlist ---
  static Box<Wishlist> getWishlistBox() {
    return Hive.box<Wishlist>(_wishlistBox);
  }

  static Future<void> addWishlist(Wishlist wishlist) async {
    await getWishlistBox().put(wishlist.id, wishlist);
  }

  static Wishlist? getWishlist(String id) {
    return getWishlistBox().get(id);
  }

  static List<Wishlist> getAllWishlists() {
    return getWishlistBox().values.toList();
  }

  static Future<void> updateWishlist(Wishlist wishlist) async {
    await getWishlistBox().put(wishlist.id, wishlist);
  }

  static Future<void> deleteWishlist(String id) async {
    await getWishlistBox().delete(id);
  }

  // Penting: Tutup Hive Box saat aplikasi ditutup (opsional tapi disarankan)
  static Future<void> closeHive() async {
    await Hive.close();
  }
}
