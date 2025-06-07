import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sparepart.dart';
import '../models/bengkel.dart';

class ApiService {
  static const String _baseUrl = 'https://bengkel-akap-1061342868557.us-central1.run.app/api';

  // Sparepart
  Future<List<Sparepart>> getAllSpareparts() async {
    final response = await http.get(Uri.parse('$_baseUrl/spareparts'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Sparepart.fromJson(e)).toList();
    }
    throw Exception('Failed to load spareparts');
  }

  Future<Sparepart> getSparepartById(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl/spareparts/$id'));
    if (response.statusCode == 200) {
      return Sparepart.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load sparepart');
  }

  Future<void> createSparepart(Sparepart sparepart) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/spareparts'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(sparepart.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create sparepart');
    }
  }

  Future<void> updateSparepart(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/spareparts/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update sparepart');
    }
  }

  Future<void> deleteSparepart(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/spareparts/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete sparepart');
    }
  }

  // Bengkel
  Future<List<Bengkel>> getAllBengkels() async {
    final response = await http.get(Uri.parse('$_baseUrl/bengkels'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Bengkel.fromJson(e)).toList();
    }
    throw Exception('Failed to load bengkels');
  }

  Future<void> createBengkel(Bengkel bengkel) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/bengkels'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(bengkel.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create bengkel');
    }
  }

  Future<Map<String, dynamic>> getExchangeRates(String baseCurrency) async {
    final response = await http.get(
      Uri.parse(
        'https://api.frankfurter.dev/v1/latest?from=$baseCurrency&symbols=USD,THB,EUR',
      ),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['rates'];
    }
    throw Exception('Failed to load exchange rates');
  }

  // TomTom LBS API
  static const String _tomTomApiKey =
      'rJ2NO6Lm1a5QFAFgBgCG2Klp1GSUTXdo';
  static const String _tomTomPlacesApiBaseUrl =
      'https://api.tomtom.com/search/2/search/';

  Future<List<Bengkel>> getNearbyWorkshops(
    double latitude,
    double longitude,
  ) async {
    final query = 'bengkel'; // atau 'auto repair shop'
    final url =
        '$_tomTomPlacesApiBaseUrl$query.json'
        '?key=$_tomTomApiKey'
        '&lat=$latitude'
        '&lon=$longitude'
        '&radius=10000'
        '&categorySet=7302'; // 7302 = Automotive Service

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> results = data['results'] as List<dynamic>;
      return results.map((json) => Bengkel.fromJson(json)).toList();
    }
    throw Exception('Failed to load nearby workshops from TomTom');
  }
}
