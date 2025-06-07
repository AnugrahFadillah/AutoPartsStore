// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';
import '../pages/katalog_sparepart_page.dart';
import '../pages/profile_page.dart';
import '../pages/saran_kesan_page.dart';
import '../pages/lokasi_bengkel_page.dart';
import '../widgets/bottom_nav.dart';
import '../models/sparepart.dart';
import '../services/api_service.dart';
import 'detail_sparepart_page.dart';
import 'cart_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  int _selectedIndex = 0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isShaking = false;
  final double _shakeThreshold = 10.0;

  // Add this to fix the error
  bool _isLoading = false;
  List<Sparepart> _popularProducts = [];

  static List<Widget> _widgetOptions = <Widget>[
    const HomePageContent(),
    const KatalogSparepartPage(),
    const LokasiBengkelPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      // Debug print
      print('Acceleration: $acceleration');
      if (acceleration > _shakeThreshold) {
        _onShakeDetected();
      }
    });
  }

  void _onShakeDetected() {
    if (!_isShaking && mounted) {
      _isShaking = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhenti sejenak agar keselamatan terjaga'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      Timer(const Duration(seconds: 1), () {
        _isShaking = false;
      });
    }
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPopularProducts() async {
    setState(() => _isLoading = true);
    try {
      final allSpareparts = await _apiService.getAllSpareparts();
      _popularProducts = allSpareparts.take(3).toList();
    } catch (e) {
      _popularProducts = [
        Sparepart(
          id: '4',
          name: 'Ban Motor Dunlop D102',
          brand: 'Dunlop',
          price: 450000,
          stock: 10,
          description: 'Ban motor premium dengan grip maksimal',
          imageUrl:
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTM3rA94vtcNp7LbJQO0akYB7qfSyLjfnWA3Q&s',
        ),
        Sparepart(
          id: '7',
          name: 'Oli Shell Advance AX7',
          brand: 'Shell',
          price: 85000,
          stock: 50,
          description: 'Oli mesin motor sintetis berkualitas tinggi',
          imageUrl:
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQZu4rDSHkfaFBadtMLPsSyxU7cf4jitOYi6Q&s',
        ),
        Sparepart(
          id: '8',
          name: 'Aki Motor GS GTZ-5S',
          brand: 'GS',
          price: 250000,
          stock: 15,
          description: 'Aki kering maintenance free',
          imageUrl:
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQwgKpQ_bokfZUjqemnu8-GKfaSKLzf5T8SNg&s',
        ),
      ];
    }
    setState(() => _isLoading = false);
  }

  void _onCategoryTap(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                KatalogSparepartPage(initialCategory: category.toLowerCase()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  final ApiService _apiService = ApiService();
  List<Sparepart> _popularProducts = [];
  bool _isLoading = false;

  // Sensor related variables
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  int _shakeCount = 0;
  DateTime? _lastShakeTime;
  final double _shakeThreshold = 15.0; // Adjust as needed
  final int _shakeTimeWindowMillis = 1000; // Time window for consecutive shakes

  // Automotive Color Palette
  static const Color primaryRed = Color(0xFFDC2626);
  static const Color darkGray = Color(0xFF1F2937);
  static const Color mediumGray = Color(0xFF374151);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color steelBlue = Color(0xFF1E40AF);

  @override
  void initState() {
    super.initState();
    _loadPopularProducts();
    _startShakeDetection();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _startShakeDetection() {
    _accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) {
      final double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (acceleration > _shakeThreshold) {
        final DateTime currentTime = DateTime.now();
        if (_lastShakeTime == null ||
            currentTime.difference(_lastShakeTime!).inMilliseconds >
                _shakeTimeWindowMillis) {
          _shakeCount = 1;
        } else {
          _shakeCount++;
        }
        _lastShakeTime = currentTime;

        if (_shakeCount >= 3) {
          _showShakeSnackbar();
          _shakeCount = 0;
          _lastShakeTime = null;
        }
      }
    });
  }

  void _showShakeSnackbar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Berhenti sejenak untuk keselamatanmu",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: darkGray,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  Future<void> _loadPopularProducts() async {
    setState(() => _isLoading = true);
    try {
      final allSpareparts = await _apiService.getAllSpareparts();
      _popularProducts = allSpareparts.take(3).toList();
    } catch (e) {
      _popularProducts = [
        Sparepart(
          id: '4',
          name: 'Ban Motor Dunlop D102',
          brand: 'Dunlop',
          price: 450000,
          stock: 10,
          description: 'Ban motor premium dengan grip maksimal',
          imageUrl:
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTM3rA94vtcNp7LbJQO0akYB7qfSyLjfnWA3Q&s',
        ),
        Sparepart(
          id: '7',
          name: 'Oli Shell Advance AX7',
          brand: 'Shell',
          price: 85000,
          stock: 50,
          description: 'Oli mesin motor sintetis berkualitas tinggi',
          imageUrl:
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQZu4rDSHkfaFBadtMLPsSyxU7cf4jitOYi6Q&s',
        ),
        Sparepart(
          id: '8',
          name: 'Aki Motor GS GTZ-5S',
          brand: 'GS',
          price: 250000,
          stock: 15,
          description: 'Aki kering maintenance free',
          imageUrl:
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQwgKpQ_bokfZUjqemnu8-GKfaSKLzf5T8SNg&s',
        ),
      ];
    }
    setState(() => _isLoading = false);
  }

  void _onCategoryTap(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                KatalogSparepartPage(initialCategory: category.toLowerCase()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: darkGray,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.build, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'AutoParts Store',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Promo dengan design yang lebih menarik
            Container(
              margin: const EdgeInsets.all(16),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ImageSlideshow(
                  width: double.infinity,
                  height: 200,
                  initialPage: 0,
                  indicatorColor: primaryRed,
                  indicatorBackgroundColor: Colors.white.withOpacity(0.5),
                  autoPlayInterval: 4000,
                  isLoop: true,
                  children:
                      [
                            {
                              "imageUrl":
                                  "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRikWs_9a7SdZzOLKuwqyvHyA99CokPdL6wRA&s",
                              "title": "Oli Yamalube Diskon 20%",
                              "description": "Promo spesial minggu ini!",
                            },
                            {
                              "imageUrl":
                                  "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTM3rA94vtcNp7LbJQO0akYB7qfSyLjfnWA3Q&s",
                              "title": "Ban IRC Buy 1 Get 1",
                              "description": "Penawaran terbatas!",
                            },
                            {
                              "imageUrl":
                                  "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR2BlX0kVha_pt3jBqb0x_lxk4LfEG9N2Sjxg&s",
                              "title": "Sparepart Original Honda",
                              "description": "Garansi resmi!",
                            },
                          ]
                          .map(
                            (item) => Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(item["imageUrl"]!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      darkGray.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item["title"]!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item["description"]!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ),

            // Kategori Section dengan design yang lebih menarik
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: primaryRed,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Kategori Sparepart",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 8, // Reduced spacing
                    mainAxisSpacing: 8, // Reduced spacing
                    childAspectRatio: 0.85, // Add this to control item height
                    children: [
                      _buildCategoryItem(
                        Icons.oil_barrel,
                        "Oli",
                        primaryRed,
                        onTap: () => _onCategoryTap('oli'),
                      ),
                      _buildCategoryItem(
                        Icons.tire_repair,
                        "Ban",
                        accentOrange,
                        onTap: () => _onCategoryTap('ban'),
                      ),
                      _buildCategoryItem(
                        Icons.electric_bolt,
                        "Aki",
                        steelBlue,
                        onTap: () => _onCategoryTap('aki'),
                      ),
                      _buildCategoryItem(
                        Icons.car_repair,
                        "Rem",
                        Colors.green.shade600,
                        onTap: () => _onCategoryTap('rem'),
                      ),
                      _buildCategoryItem(
                        Icons.lightbulb,
                        "Lampu",
                        Colors.amber.shade600,
                        onTap: () => _onCategoryTap('lampu'),
                      ),
                      _buildCategoryItem(
                        Icons.filter_alt,
                        "Filter",
                        Colors.purple.shade600,
                        onTap: () => _onCategoryTap('filter'),
                      ),
                      _buildCategoryItem(
                        Icons.settings,
                        "Mesin",
                        mediumGray,
                        onTap: () => _onCategoryTap('mesin'),
                      ),
                      _buildCategoryItem(
                        Icons.more_horiz,
                        "Lainnya",
                        Colors.teal.shade600,
                        onTap: () => _onCategoryTap(''),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Produk Terlaris Section dengan design yang lebih menarik
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: primaryRed,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Produk Terlaris",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: darkGray,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const KatalogSparepartPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Lihat Semua",
                            style: TextStyle(
                              color: primaryRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 240,
                    child:
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _popularProducts.length,
                              itemBuilder: (context, index) {
                                final product = _popularProducts[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => DetailSparepartPage(
                                              sparepart: product,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 160,
                                    margin: const EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: lightGray,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(12),
                                                  ),
                                              image:
                                                  product.imageUrl != null
                                                      ? DecorationImage(
                                                        image: NetworkImage(
                                                          product.imageUrl!,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      )
                                                      : null,
                                              color: lightGray,
                                            ),
                                            child:
                                                product.imageUrl == null
                                                    ? const Center(
                                                      child: Icon(
                                                        Icons.image,
                                                        size: 40,
                                                        color: mediumGray,
                                                      ),
                                                    )
                                                    : null,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    color: darkGray,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      product.brand,
                                                      style: TextStyle(
                                                        color: mediumGray,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Rp ${formatRupiah(product.price)}',
                                                      style: const TextStyle(
                                                        color: primaryRed,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String formatRupiah(num number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(number).replaceAll(',', '.');
  }

  Widget _buildCategoryItem(
    IconData icon,
    String label,
    Color color, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final iconSize = constraints.maxWidth * 0.3; // 30% of width
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Add this
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Reduced padding
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2), width: 1),
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              const SizedBox(height: 4), // Reduced spacing
              Text(
                label,
                style: TextStyle(
                  fontSize: 11, // Reduced font size
                  fontWeight: FontWeight.w500,
                  color: darkGray,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }
}

void requestNotificationPermission() async {
  final plugin = FlutterLocalNotificationsPlugin();
}
