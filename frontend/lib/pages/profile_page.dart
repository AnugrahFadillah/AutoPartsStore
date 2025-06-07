// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../providers/cart_provider.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'feedback_page.dart';
import '../services/wishlist_service.dart';
import '../models/sparepart.dart';
import '../services/hive_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Automotive Color Palette (sama dengan HomePage)
  static const Color primaryRed = Color(0xFFDC2626);
  static const Color darkGray = Color(0xFF1F2937);
  static const Color mediumGray = Color(0xFF374151);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color steelBlue = Color(0xFF1E40AF);

  List<Sparepart> _wishlistSpareparts = [];
  int _wishlistCount = 0;

  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final user = await _authService.getCurrentUser();
    List<Sparepart> wishlistSpareparts = [];
    int wishlistCount = 0;
    if (user != null) {
      final wishlistIds = await WishlistService.getWishlist(user.id);
      final sparepartBox = HiveService.getSparepartBox();
      wishlistSpareparts =
          sparepartBox.values
              .where((sp) => wishlistIds.contains(sp.id))
              .toList();
      wishlistCount = wishlistIds.length;
    }
    setState(() {
      _currentUser = user;
      _usernameController.text = _currentUser?.username ?? '';
      _emailController.text = _currentUser?.email ?? '';
      _wishlistSpareparts = wishlistSpareparts;
      _wishlistCount = wishlistCount;
      _isLoading = false;
    });
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_currentUser == null) {
      setState(() {
        _errorMessage = 'Gagal memuat data pengguna.';
        _isLoading = false;
      });
      return;
    }

    final updatedUser = User(
      id: _currentUser!.id,
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _currentUser!.password,
      imagePath: _currentUser!.imagePath,
      notes: _currentUser!.notes,
    );

    try {
      final bool success = await _authService.updateProfile(updatedUser);
      if (success) {
        setState(() {
          _currentUser = updatedUser;
          _isEditing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profil berhasil diperbarui!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Gagal memperbarui profil.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
        // Jika ingin menyimpan ke user, tambahkan di sini
        // _currentUser = _currentUser?.copyWith(imagePath: pickedFile.path);
      });
      // Tampilkan notifikasi berhasil
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto profil berhasil diubah!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;

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
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Profil Pengguna',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body:
          _isLoading && _currentUser == null
              ? const Center(
                child: CircularProgressIndicator(color: primaryRed),
              )
              : _currentUser == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: mediumGray),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data profil.',
                      style: TextStyle(fontSize: 16, color: mediumGray),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Profile Section
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: darkGray,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Profile Picture
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: lightGray,
                                  backgroundImage:
                                      _pickedImage != null
                                          ? FileImage(_pickedImage!)
                                          : (_currentUser!.imagePath != null
                                              ? FileImage(
                                                File(_currentUser!.imagePath!),
                                              )
                                              : null),
                                  child:
                                      (_pickedImage == null &&
                                              _currentUser!.imagePath == null)
                                          ? Icon(
                                            Icons.person,
                                            size: 60,
                                            color: mediumGray,
                                          )
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Tombol Ubah Foto
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text('Ubah Foto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              elevation: 0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // User Info
                          Text(
                            _currentUser!.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser!.email,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Profile Form Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(24),
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
                                'Informasi Pribadi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: darkGray,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Username Field
                          _buildInputField(
                            controller: _usernameController,
                            label: 'Nama Pengguna',
                            icon: Icons.person_outline,
                            readOnly: !_isEditing,
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          _buildInputField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            readOnly: !_isEditing,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Profile Stats Section
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
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.shopping_cart_outlined,
                              label: 'Keranjang',
                              value: cartCount.toString(),
                              color: primaryRed,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.favorite_border,
                              label: 'Wishlist',
                              value: _wishlistCount.toString(),
                              color: accentOrange,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Change Password Button
                          _buildActionButton(
                            icon: Icons.edit_outlined,
                            label: 'Edit Profil',
                            color: steelBlue,
                            onTap: () async {
                              // Navigasi ke halaman edit profile
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          EditProfilePage(user: _currentUser!),
                                ),
                              );
                              if (updated == true) {
                                _loadUserProfile(); // Refresh profile jika ada perubahan
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // Feedback Button
                          _buildActionButton(
                            icon: Icons.feedback_outlined,
                            label: 'Feedback',
                            color: accentOrange,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FeedbackPages(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Logout Button
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade400,
                                  Colors.red.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _authService.logoutUser();
                                if (mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Keluar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Wishlist List Section
                    if (_wishlistSpareparts.isNotEmpty)
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
                            const Text(
                              'Wishlist Kamu',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: darkGray,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._wishlistSpareparts.map(
                              (sp) => ListTile(
                                leading:
                                    sp.imageUrl != null
                                        ? Image.network(
                                          sp.imageUrl!,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        )
                                        : const Icon(Icons.image, size: 40),
                                title: Text(sp.name),
                                subtitle: Text(
                                  'Rp ${sp.price.toStringAsFixed(0)}',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool readOnly,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? lightGray : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              readOnly
                  ? lightGray
                  : (_isEditing ? primaryRed : mediumGray.withOpacity(0.3)),
          width: readOnly ? 0 : 1.5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: TextStyle(color: readOnly ? mediumGray : darkGray, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: readOnly ? mediumGray : primaryRed,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: readOnly ? mediumGray : primaryRed),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: darkGray,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: mediumGray, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: darkGray,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: mediumGray, size: 16),
          ],
        ),
      ),
    );
  }
}
