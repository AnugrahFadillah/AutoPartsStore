import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sparepart.dart';
import '../services/api_service.dart'; // Untuk konversi mata uang
import '../providers/cart_provider.dart';
import '../services/wishlist_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class DetailSparepartPage extends StatefulWidget {
  final Sparepart sparepart;

  const DetailSparepartPage({super.key, required this.sparepart});

  @override
  State<DetailSparepartPage> createState() => _DetailSparepartPageState();
}

class _DetailSparepartPageState extends State<DetailSparepartPage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _exchangeRates;
  String _selectedCurrency = 'IDR'; // Default mata uang
  bool _isLoadingRates = false;
  String? _currencyError;

  // Automotive Color Palette (sama dengan katalog)
  static const Color primaryRed = Color(0xFFDC2626);
  static const Color darkGray = Color(0xFF1F2937);
  static const Color mediumGray = Color(0xFF374151);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color accentOrange = Color(0xFFEA580C);

  // Tambahkan state
  bool _isInWishlist = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchExchangeRates();
    _loadWishlistStatus();
  }

  Future<void> _fetchExchangeRates() async {
    setState(() {
      _isLoadingRates = true;
      _currencyError = null;
    });
    try {
      final rates = await _apiService.getExchangeRates('IDR');
      if (rates is Map && rates.isNotEmpty) {
        setState(() {
          _exchangeRates = rates;
        });
      } else {
        setState(() {
          _currencyError = 'Kurs tidak tersedia.';
        });
      }
    } catch (e) {
      setState(() {
        _currencyError =
            'Gagal memuat kurs mata uang: ${e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString()}';
      });
    } finally {
      setState(() {
        _isLoadingRates = false;
      });
    }
  }

  Future<void> _loadWishlistStatus() async {
    final user = await AuthService().getCurrentUser();
    if (user != null) {
      _userId = user.id;
      final wishlist = await WishlistService.getWishlist(user.id);
      setState(() {
        _isInWishlist = wishlist.contains(widget.sparepart.id);
      });
    }
  }

  double _convertPrice(double price, String targetCurrency) {
    if (_exchangeRates == null || _exchangeRates!.isEmpty) {
      return price;
    }
    if (targetCurrency == 'IDR') {
      return price;
    }
    if (_exchangeRates!.containsKey(targetCurrency)) {
      final double rate = (_exchangeRates![targetCurrency] as num).toDouble();
      return price * rate; // Frankfurter API returns direct conversion rate
    }
    return price;
  }

  String _formatPrice(double price, String currency) {
    // Format untuk berbagai mata uang
    if (currency == 'IDR') {
      return 'Rp${formatRupiah(price)}';
    } else if (currency == 'USD') {
      return '\$${price.toStringAsFixed(2)}';
    } else if (currency == 'THB') {
      return '฿${price.toStringAsFixed(2)}';
    } else if (currency == 'EUR') {
      return '€${price.toStringAsFixed(2)}';
    }
    return '${currency} ${price.toStringAsFixed(2)}';
  }

  String formatRupiah(num number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0)
        .format(number)
        .replaceAll(',', '.');
  }

  @override
  Widget build(BuildContext context) {
    final double convertedPrice = _convertPrice(
      widget.sparepart.price,
      _selectedCurrency,
    );

    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: darkGray,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Sparepart',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_userId != null)
            IconButton(
              icon: Icon(
                _isInWishlist ? Icons.favorite : Icons.favorite_border,
                color: _isInWishlist ? primaryRed : Colors.white,
              ),
              tooltip:
                  _isInWishlist
                      ? 'Hapus dari Wishlist'
                      : 'Masukkan ke Wishlist',
              onPressed: () async {
                if (_isInWishlist) {
                  await WishlistService.removeFromWishlist(
                    _userId!,
                    widget.sparepart.id,
                  );
                } else {
                  await WishlistService.addToWishlist(
                    _userId!,
                    widget.sparepart.id,
                  );
                }
                setState(() {
                  _isInWishlist = !_isInWishlist;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isInWishlist
                          ? 'Ditambahkan ke wishlist!'
                          : 'Dihapus dari wishlist!',
                    ),
                    backgroundColor: primaryRed,
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Hero Image Section
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child:
                  widget.sparepart.imageUrl != null &&
                          widget.sparepart.imageUrl!.isNotEmpty
                      ? ClipRRect(
                        child: Image.network(
                          widget.sparepart.imageUrl!,
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                color: lightGray,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 80,
                                    color: mediumGray,
                                  ),
                                ),
                              ),
                        ),
                      )
                      : Container(
                        color: lightGray,
                        child: const Center(
                          child: Icon(
                            Icons.hardware,
                            size: 80,
                            color: mediumGray,
                          ),
                        ),
                      ),
            ),

            // Product Info Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    widget.sparepart.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Brand
                  Row(
                    children: [
                      Icon(Icons.verified, color: mediumGray, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Merek: ${widget.sparepart.brand}',
                        style: TextStyle(
                          fontSize: 16,
                          color: mediumGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stock Status
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color:
                              widget.sparepart.stock > 0
                                  ? Colors.green
                                  : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.sparepart.stock > 0
                            ? 'Tersedia (${widget.sparepart.stock} unit)'
                            : 'Stok Habis',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              widget.sparepart.stock > 0
                                  ? Colors.green
                                  : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Price Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: primaryRed, size: 20),
                      const SizedBox(width: 4),
                      const Text(
                        'Harga:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _isLoadingRates
                      ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                        ),
                      )
                      : _currencyError != null
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatPrice(widget.sparepart.price, 'IDR'),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primaryRed,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Error memuat kurs: $_currencyError',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  _formatPrice(
                                    convertedPrice,
                                    _selectedCurrency,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: primaryRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Currency Selector
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: mediumGray.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.language,
                                  color: mediumGray,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Mata Uang:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: mediumGray,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButton<String>(
                                    value: _selectedCurrency,
                                    isExpanded: true,
                                    underline: Container(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedCurrency = newValue;
                                        });
                                      }
                                    },
                                    items:
                                        <String>[
                                          'IDR',
                                          'USD',
                                          'EUR',
                                          'THB',
                                        ].map<DropdownMenuItem<String>>((
                                          String value,
                                        ) {
                                          String flag = '';
                                          switch (value) {
                                            case 'IDR':
                                              flag = '🇮🇩';
                                              break;
                                            case 'USD':
                                              flag = '🇺🇸';
                                              break;
                                            case 'EUR':
                                              flag = '🇪🇺';
                                              break;
                                            case 'THB':
                                              flag = '🇹🇭';
                                              break;
                                          }
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              '$flag $value',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Description Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: mediumGray, size: 20),
                      const SizedBox(width: 4),
                      const Text(
                        'Deskripsi:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightGray.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.sparepart.description ??
                          'Tidak ada deskripsi tersedia untuk produk ini.',
                      style: TextStyle(
                        fontSize: 16,
                        color: mediumGray,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Button
            Container(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      widget.sparepart.stock > 0
                          ? () {
                            context.read<CartProvider>().addToCart(
                              widget.sparepart,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.shopping_cart,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${widget.sparepart.name} berhasil dimasukkan ke keranjang!',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: primaryRed,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                          : null,
                  icon: const Icon(Icons.shopping_cart),
                  label: Text(
                    widget.sparepart.stock > 0
                        ? 'Masukkan ke Keranjang'
                        : 'Stok Tidak Tersedia',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 16,
                    ),
                    backgroundColor:
                        widget.sparepart.stock > 0 ? primaryRed : mediumGray,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: widget.sparepart.stock > 0 ? 2 : 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
