import 'package:flutter/material.dart';
import '../models/sparepart.dart';
import '../services/api_service.dart';

class SparepartListPage extends StatefulWidget {
  const SparepartListPage({super.key});

  @override
  State<SparepartListPage> createState() => _SparepartListPageState();
}

class _SparepartListPageState extends State<SparepartListPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Sparepart>> _futureSpareparts;

  @override
  void initState() {
    super.initState();
    _futureSpareparts = _apiService.getAllSpareparts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Sparepart')),
      body: FutureBuilder<List<Sparepart>>(
        future: _futureSpareparts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final spareparts = snapshot.data ?? [];
          return ListView.builder(
            itemCount: spareparts.length,
            itemBuilder: (context, index) {
              final s = spareparts[index];
              return ListTile(
                title: Text(s.name),
                subtitle: Text('${s.brand} - Rp${s.price}'),
                trailing: s.imageUrl != null
                    ? Image.network(s.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
