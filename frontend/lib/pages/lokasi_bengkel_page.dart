import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:intl/intl.dart';
import '../models/bengkel.dart';

class LokasiBengkelPage extends StatefulWidget {
  final Bengkel? selectedBengkel;
  const LokasiBengkelPage({super.key, this.selectedBengkel});

  @override
  State<LokasiBengkelPage> createState() => _LokasiBengkelPageState();
}

class _LokasiBengkelPageState extends State<LokasiBengkelPage> {
  MapController? _mapController;
  LatLng? _currentPosition;
  List<Bengkel> _bengkels = [];
  bool _isLoading = false;
  String? _errorMessage;
  List<LatLng> _routePoints = [];
  Bengkel? _selectedBengkelForRoute;
  String? _routeDistance;
  String? _routeDuration;
  String _selectedTimezone = 'Asia/Jakarta'; // Default WIB
  Map<String, String> _timezoneLabels = {
    'Asia/Jakarta': 'WIB',
    'Asia/Makassar': 'WITA',
    'Asia/Jayapura': 'WIT',
    'Europe/London': 'London',
    'Asia/Amman': 'Amman',
  };
  DateTime? _currentTime;

  // Automotive Color Palette - selaras dengan HomePage
  static const Color primaryRed = Color(0xFFDC2626);
  static const Color darkGray = Color(0xFF1F2937);
  static const Color mediumGray = Color(0xFF374151);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color steelBlue = Color(0xFF1E40AF);

  // Tambahkan jam buka untuk setiap bengkel
  final Map<String, String> _bengkelOpenHours = {
    '1': '08:00',
    '2': '09:00',
    '3': '10:00',
    '4': '08:00',
    '5': '09:00',
  };

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initLocationAndBengkels();
    _fetchCurrentTime();
  }

  Future<void> _fetchCurrentTime() async {
    try {
      final apiKey = 'DSVJEUUP5Z9U';
      final url =
          'https://api.timezonedb.com/v2.1/get-time-zone?key=$apiKey&format=json&by=zone&zone=$_selectedTimezone';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // TimeZoneDB returns 'formatted' in 'YYYY-MM-DD HH:MM:SS' format
        final formatted = data['formatted'] as String?;
        if (formatted != null) {
          final datetime = DateTime.parse(formatted.replaceFirst(' ', 'T'));
          setState(() {
            _currentTime = datetime;
          });
        }
      }
    } catch (e) {
      setState(() {
        _currentTime = null;
      });
    }
  }

  void _onTimezoneChanged(String? timezone) async {
    if (timezone == null) return;
    setState(() {
      _selectedTimezone = timezone;
      _currentTime = null;
    });
    await _fetchCurrentTime();
  }

  Future<void> _initLocationAndBengkels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Initialize bengkel data
    _bengkels =
        widget.selectedBengkel != null
            ? [widget.selectedBengkel!]
            : [
              Bengkel(
                id: '1',
                name: 'Bengkel Motor Jogja',
                address: 'Jl. Kaliurang No. 10, Sleman',
                latitude: -7.747033,
                longitude: 110.355398,
              ),
              Bengkel(
                id: '2',
                name: 'Bengkel Sumber Rejeki',
                address: 'Jl. Malioboro No. 20, Yogyakarta',
                latitude: -7.792778,
                longitude: 110.365278,
              ),
              Bengkel(
                id: '3',
                name: 'Bengkel Maju Lancar',
                address: 'Jl. Gejayan No. 5, Yogyakarta',
                latitude: -7.769975,
                longitude: 110.388377,
              ),
              Bengkel(
                id: '4',
                name: 'Bengkel Pasti Beres',
                address: 'Jl. Magelang No. 100, Sleman, Yogyakarta',
                latitude: -7.747900,
                longitude: 110.340000,
              ),
              Bengkel(
                id: '5',
                name: 'Bengkel Amanah',
                address: 'Jl. Parangtritis No. 50, Bantul, Yogyakarta',
                latitude: -7.829000,
                longitude: 110.363000,
              ),
            ];

    await getLocation();
    setState(() => _isLoading = false);
  }

  Future<void> getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi tidak aktif');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Move map setelah map controller siap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mapController != null && _currentPosition != null) {
          try {
            _mapController!.move(_currentPosition!, 13.0);
          } catch (e) {
            print('Error moving map: $e');
          }
        }
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  // Ganti _getRoute agar fallback ke OSRM jika OpenRouteService gagal (403)
  Future<void> _getRoute(Bengkel bengkel) async {
    if (_currentPosition == null) return;

    setState(() => _isLoading = true);

    bool routeSuccess = false;
    try {
      // Coba OpenRouteService dulu
      await _getRouteFromOpenRouteService(bengkel);
      routeSuccess = true;
    } catch (e) {
      print('OpenRouteService failed: $e');
      // Jika error 403 atau lainnya, fallback ke OSRM
      try {
        await _getRouteFromOSRM(bengkel);
        routeSuccess = true;
      } catch (e2) {
        print('OSRM failed: $e2');
      }
    }

    // Jika semua gagal, fallback ke garis lurus
    if (!routeSuccess) {
      setState(() {
        _routePoints = [
          _currentPosition!,
          LatLng(bengkel.latitude, bengkel.longitude),
        ];
        _selectedBengkelForRoute = bengkel;
        final distance =
            Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              bengkel.latitude,
              bengkel.longitude,
            ) /
            1000;
        _routeDistance = '${distance.toStringAsFixed(1)} km';
        _routeDuration = '${(distance * 4).round()} menit';
      });
    }

    // Adjust map view to show the route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapController != null && _routePoints.isNotEmpty) {
        try {
          final bounds = LatLngBounds.fromPoints(_routePoints);
          _mapController!.fitBounds(
            bounds,
            options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
          );
        } catch (e) {
          print('Error fitting bounds: $e');
        }
      }
    });

    setState(() => _isLoading = false);
  }

  // OpenRouteService API (gratis, butuh API key)
  Future<void> _getRouteFromOpenRouteService(Bengkel bengkel) async {
    const String apiKey =
        'YOUR_OPENROUTESERVICE_API_KEY'; // Ganti dengan API key kamu
    final String url =
        'https://api.openrouteservice.org/v2/directions/driving-car?'
        'api_key=$apiKey&'
        'start=${_currentPosition!.longitude},${_currentPosition!.latitude}&'
        'end=${bengkel.longitude},${bengkel.latitude}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['features'][0];
        final geometry = route['geometry'];
        final properties = route['properties'];
        final List<List<num>> coordinates = List<List<num>>.from(
          geometry['coordinates'],
        );
        final List<LatLng> points =
            coordinates
                .map(
                  (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()),
                )
                .toList();
        final segments = properties['segments'][0];
        final distance = segments['distance'] / 1000;
        final duration = segments['duration'] / 60;
        setState(() {
          _routePoints = points;
          _selectedBengkelForRoute = bengkel;
          _routeDistance = '${distance.toStringAsFixed(1)} km';
          _routeDuration = '${duration.round()} menit';
        });
      } else {
        throw Exception('Failed to get route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting route from OpenRouteService: $e');
    }
  }

  // Google Directions API (berbayar, lebih akurat)
  Future<void> _getRouteFromGoogle(Bengkel bengkel) async {
    const String apiKey = 'YOUR_GOOGLE_API_KEY'; // Ganti dengan API key kamu
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&'
        'destination=${bengkel.latitude},${bengkel.longitude}&'
        'key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          final encodedPolyline = route['overview_polyline']['points'];
          final polylinePoints = PolylinePoints();
          final List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(
            encodedPolyline,
          );
          final List<LatLng> points =
              decodedPoints
                  .map((point) => LatLng(point.latitude, point.longitude))
                  .toList();
          setState(() {
            _routePoints = points;
            _selectedBengkelForRoute = bengkel;
            _routeDistance = leg['distance']['text'];
            _routeDuration = leg['duration']['text'];
          });
        } else {
          throw Exception('No route found');
        }
      } else {
        throw Exception('Failed to get route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting route from Google: $e');
    }
  }

  // OSRM (gratis, tanpa API key)
  Future<void> _getRouteFromOSRM(Bengkel bengkel) async {
    final String url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${_currentPosition!.longitude},${_currentPosition!.latitude};'
        '${bengkel.longitude},${bengkel.latitude}?'
        'overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          // Perbaikan parsing koordinat agar support dynamic
          final List coordinates = geometry['coordinates'];
          final List<LatLng> points =
              coordinates
                  .map<LatLng>(
                    (coord) => LatLng(
                      (coord[1] as num).toDouble(),
                      (coord[0] as num).toDouble(),
                    ),
                  )
                  .toList();
          final distance = route['distance'] / 1000;
          final duration = route['duration'] / 60;
          setState(() {
            _routePoints = points;
            _selectedBengkelForRoute = bengkel;
            _routeDistance = '${distance.toStringAsFixed(1)} km';
            _routeDuration = '${duration.round()} menit';
          });
        } else {
          throw Exception('No route found');
        }
      } else {
        throw Exception('Failed to get route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting route from OSRM: $e');
    }
  }

  void _clearRoute() {
    setState(() {
      _routePoints.clear();
      _selectedBengkelForRoute = null;
      _routeDistance = null;
      _routeDuration = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapController != null && _currentPosition != null) {
        try {
          _mapController!.move(_currentPosition!, 13.0);
        } catch (e) {
          print('Error clearing route: $e');
        }
      }
    });
  }

  double _calculateDistance(Bengkel bengkel) {
    if (_currentPosition == null) return 0;
    return Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          bengkel.latitude,
          bengkel.longitude,
        ) /
        1000; // Convert to km
  }

  void _moveToLocation(double lat, double lng, double zoom) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapController != null) {
        try {
          _mapController!.move(LatLng(lat, lng), zoom);
        } catch (e) {
          print('Error moving to location: $e');
        }
      }
    });
  }

  // Helper untuk konversi jam buka ke zona waktu terpilih
  String _getOpenHourInSelectedTimezone(String openHour) {
    if (_currentTime == null) {
      return '$openHour ${_timezoneLabels[_selectedTimezone]}';
    }

    // Parse opening hour
    final openParts = openHour.split(':');
    if (openParts.length != 2) {
      return '$openHour ${_timezoneLabels[_selectedTimezone]}';
    }

    int openHourInt = int.tryParse(openParts[0]) ?? 8;
    final openMinuteInt = int.tryParse(openParts[1]) ?? 0;

    // Adjust hour based on timezone
    switch (_selectedTimezone) {
      case 'Asia/Makassar': // WITA = WIB + 1
        openHourInt = (openHourInt + 1) % 24;
      case 'Asia/Jayapura': // WIT = WIB + 2
        openHourInt = (openHourInt + 2) % 24;
      case 'Europe/London': // London = WIB - 7
        openHourInt = (openHourInt - 7 + 24) % 24;
      case 'Asia/Amman': // Amman = WIB - 4
        openHourInt = (openHourInt - 4 + 24) % 24;
    }

    return '${openHourInt.toString().padLeft(2, '0')}:${openMinuteInt.toString().padLeft(2, '0')} ${_timezoneLabels[_selectedTimezone]}';
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
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.selectedBengkel?.name ?? 'Bengkel Terdekat',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          if (_routePoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: _clearRoute,
              tooltip: 'Hapus rute',
            ),
        ],
      ),
      body: Column(
        children: [
          // Error message banner
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: primaryRed.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.error, color: primaryRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: primaryRed),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: primaryRed),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),

          // Route info banner
          if (_selectedBengkelForRoute != null && _routeDuration != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: steelBlue.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: steelBlue.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.navigation, size: 20, color: steelBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Rute ke ${_selectedBengkelForRoute!.name}',
                    style: TextStyle(
                      color: darkGray,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: steelBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_routeDuration',
                      style: TextStyle(
                        color: steelBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Map
          Container(
            height: 350,
            margin: const EdgeInsets.all(16),
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
              child:
                  _isLoading
                      ? Container(
                        color: Colors.white,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: primaryRed),
                              const SizedBox(height: 16),
                              Text(
                                'Memuat peta...',
                                style: TextStyle(color: mediumGray),
                              ),
                            ],
                          ),
                        ),
                      )
                      : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          center:
                              _currentPosition ??
                              const LatLng(-7.797068, 110.370529),
                          zoom: 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png?key=rJ2NO6Lm1a5QFAFgBgCG2Klp1GSUTXdo",
                            userAgentPackageName: 'com.example.app',
                          ),
                          // Route polyline
                          if (_routePoints.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _routePoints,
                                  strokeWidth: 4.0,
                                  color: steelBlue,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              // Current location marker
                              if (_currentPosition != null)
                                Marker(
                                  point: _currentPosition!,
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: steelBlue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.my_location,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              // Bengkel markers
                              ..._bengkels.map((bengkel) {
                                final openHour =
                                    _bengkelOpenHours[bengkel.id] ?? '08:00';
                                return Marker(
                                  point: LatLng(
                                    bengkel.latitude,
                                    bengkel.longitude,
                                  ),
                                  child: GestureDetector(
                                    onTap:
                                        () => _showBengkelDetailBottomSheet(
                                          bengkel,
                                          openHour,
                                        ),
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color:
                                            bengkel == _selectedBengkelForRoute
                                                ? Colors.green.shade600
                                                : primaryRed,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.build,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ],
                      ),
            ),
          ),

          // Bengkel list
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        'Daftar Bengkel',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _bengkels.length,
                      itemBuilder: (context, index) {
                        final bengkel = _bengkels[index];
                        final distance = _calculateDistance(bengkel);
                        final isSelected = bengkel == _selectedBengkelForRoute;
                        final openHour =
                            _bengkelOpenHours[bengkel.id] ?? '08:00';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                isSelected
                                    ? Border.all(
                                      color: Colors.green.shade600,
                                      width: 2,
                                    )
                                    : Border.all(color: lightGray, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.green.shade100
                                        : primaryRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.build,
                                color:
                                    isSelected
                                        ? Colors.green.shade700
                                        : primaryRed,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              bengkel.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: darkGray,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  bengkel.address,
                                  style: TextStyle(
                                    color: mediumGray,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: mediumGray,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${distance.toStringAsFixed(1)} km',
                                      style: TextStyle(
                                        color: mediumGray,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: mediumGray,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Buka: $openHour WIB',
                                      style: TextStyle(
                                        color: mediumGray,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.arrow_forward_ios,
                              color:
                                  isSelected
                                      ? Colors.green.shade600
                                      : mediumGray,
                              size: isSelected ? 24 : 16,
                            ),
                            onTap: () {
                              _moveToLocation(
                                bengkel.latitude,
                                bengkel.longitude,
                                15.0,
                              );
                              _showBengkelDetailBottomSheet(bengkel, openHour);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () => getLocation(),
            icon: const Icon(Icons.my_location),
            label: const Text('Perbarui Lokasi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: steelBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  void _showBengkelDetailBottomSheet(Bengkel bengkel, String openHour) {
    final distance = _calculateDistance(bengkel);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Helper agar openHourDisplay selalu update
            String openHourDisplay = _getOpenHourInSelectedTimezone(openHour);

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bengkel info
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(Icons.build, color: primaryRed, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bengkel.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: darkGray,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${distance.toStringAsFixed(1)} km dari lokasi Anda',
                              style: TextStyle(
                                fontSize: 14,
                                color: mediumGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Timezone selection
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Zona Waktu',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedTimezone,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items:
                              _timezoneLabels.entries.map((entry) {
                                return DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(entry.value),
                                );
                              }).toList(),
                          onChanged: (String? timezone) async {
                            if (timezone != null) {
                              setModalState(() {
                                _selectedTimezone = timezone;
                                _currentTime = null;
                              });
                              await _fetchCurrentTime();
                              setModalState(() {}); // <--- Tambahkan ini agar UI update setelah fetch
                            }
                          },
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: mediumGray,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Buka: ${_getOpenHourInSelectedTimezone(openHour)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: mediumGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Address
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: mediumGray),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bengkel.address,
                            style: const TextStyle(
                              fontSize: 16,
                              color: darkGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _moveToLocation(
                              bengkel.latitude,
                              bengkel.longitude,
                              16.0,
                            );
                          },
                          icon: const Icon(Icons.zoom_in),
                          label: const Text('Lihat di Peta'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: steelBlue,
                            side: BorderSide(color: steelBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _getRoute(bengkel);
                          },
                          icon: const Icon(Icons.navigation),
                          label: const Text('Navigasi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: steelBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
