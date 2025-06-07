// lib/pages/saran_kesan_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Untuk mendapatkan user
import '../models/user.dart';

class SaranKesanPage extends StatefulWidget {
  const SaranKesanPage({super.key});

  @override
  State<SaranKesanPage> createState() => _SaranKesanPageState();
}

class _SaranKesanPageState extends State<SaranKesanPage> {
  final TextEditingController _saranKesanController = TextEditingController();
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadUserNotes();
  }

  @override
  void dispose() {
    _saranKesanController.dispose();
    super.dispose();
  }

  Future<void> _loadUserNotes() async {
    setState(() => _isLoading = true);
    _currentUser = await _authService.getCurrentUser();
    if (_currentUser != null) {
      _saranKesanController.text = _currentUser!.notes ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSaranKesan() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    if (_currentUser == null) {
      setState(() {
        _statusMessage = 'Gagal menyimpan: Pengguna tidak ditemukan.';
        _isLoading = false;
      });
      return;
    }

    final updatedUser = User(
      id: _currentUser!.id,
      username: _currentUser!.username,
      email: _currentUser!.email,
      password: _currentUser!.password,
      imagePath: _currentUser!.imagePath,
      notes: _saranKesanController.text.trim(),
    );

    try {
      final bool success = await _authService.updateProfile(
        updatedUser,
      ); // Menggunakan updateProfile untuk menyimpan notes
      if (success) {
        setState(() {
          _statusMessage = 'Saran dan kesan berhasil disimpan!';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saran & Kesan berhasil disimpan!')),
          );
        }
      } else {
        setState(() {
          _statusMessage = 'Gagal menyimpan saran dan kesan.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saran & Kesan'), centerTitle: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Kami sangat menghargai masukan Anda!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _saranKesanController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Tulis saran atau kesan Anda di sini...',
                        hintText: 'Misalnya: "Aplikasi ini sangat membantu!"',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_statusMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color:
                                _statusMessage!.contains('berhasil')
                                    ? Colors.green
                                    : Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveSaranKesan,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Kirim Saran & Kesan',
                                style: TextStyle(fontSize: 18),
                              ),
                    ),
                  ],
                ),
              ),
    );
  }
}
