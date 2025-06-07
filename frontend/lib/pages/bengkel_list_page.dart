import 'package:flutter/material.dart';
import '../models/bengkel.dart';
import '../services/api_service.dart';

class BengkelListPage extends StatefulWidget {
  const BengkelListPage({super.key});

  @override
  State<BengkelListPage> createState() => _BengkelListPageState();
}

class _BengkelListPageState extends State<BengkelListPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Bengkel>> _futureBengkels;

  @override
  void initState() {
    super.initState();
    _futureBengkels = _apiService.getAllBengkels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Bengkel')),
      body: FutureBuilder<List<Bengkel>>(
        future: _futureBengkels,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final bengkels = snapshot.data ?? [];
          return ListView.builder(
            itemCount: bengkels.length,
            itemBuilder: (context, index) {
              final b = bengkels[index];
              return ListTile(
                title: Text(b.name),
                subtitle: Text('${b.address}\nLat: ${b.latitude}, Lon: ${b.longitude}'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
