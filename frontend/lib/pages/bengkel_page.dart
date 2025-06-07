import 'package:flutter/material.dart';
import '../models/bengkel.dart';
import '../services/api_service.dart';
import 'lokasi_bengkel_page.dart';

class BengkelPage extends StatefulWidget {
  const BengkelPage({super.key});

  @override
  State<BengkelPage> createState() => _BengkelPageState();
}

class _BengkelPageState extends State<BengkelPage> {
  final ApiService _apiService = ApiService();
  List<Bengkel> _bengkels = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBengkels();
  }

  Future<void> _fetchBengkels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final bengkels = await _apiService.getAllBengkels();
      setState(() {
        _bengkels = bengkels;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data bengkel: $e';
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
      appBar: AppBar(
        title: const Text('Daftar Bengkel'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          const LokasiBengkelPage(), // Without selectedBengkel to show all
                ),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : ListView.builder(
                itemCount: _bengkels.length,
                itemBuilder: (context, index) {
                  final bengkel = _bengkels[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.build)),
                      title: Text(bengkel.name),
                      subtitle: Text(bengkel.address),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    LokasiBengkelPage(selectedBengkel: bengkel),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
