import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/sparepart.dart';

class CartProvider with ChangeNotifier {
  List<Sparepart> _items = [];
  String? _userId;

  List<Sparepart> get items => List.unmodifiable(_items);

  Future<void> loadCart(String userId) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('cart_$userId');
    if (data != null) {
      final List<dynamic> jsonList = json.decode(data);
      _items = jsonList.map((e) => Sparepart.fromJson(e)).toList();
    } else {
      _items = [];
    }
    notifyListeners();
  }

  Future<void> _saveCart() async {
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _items.map((e) => e.toJson()).toList();
    await prefs.setString('cart_$_userId', json.encode(jsonList));
  }

  void addToCart(Sparepart item) {
    _items.add(item);
    _saveCart();
    notifyListeners();
  }

  void removeFromCart(Sparepart item) {
    _items.remove(item);
    _saveCart();
    notifyListeners();
  }

  void removeAt(int index) {
    _items.removeAt(index);
    _saveCart();
    notifyListeners();
  }

  int get itemCount => _items.length;

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
