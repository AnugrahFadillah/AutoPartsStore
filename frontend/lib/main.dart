import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'services/hive_service.dart'; // Sesuaikan path
import '/pages/login_page.dart'; // Atau home_page jika sudah login
import '/pages/home_page.dart';
import '/services/auth_service.dart';
import 'pages/sparepart_list_page.dart';
import 'pages/bengkel_list_page.dart';
import 'models/feedback.dart'; // import model feedback
import 'package:hive/hive.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones(); // Inisialisasi timezone
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  requestNotificationPermission(); // <--- tambahkan ini
  await schedulePromoSparepartNotification(); // <--- panggil di sini

  await HiveService.initHive();

  // Daftarkan adapter sebelum openBox
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(FeedbackModelAdapter());
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        // provider lain jika ada
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Sparepart Motor',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<bool>(
        future: AuthService().isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            if (snapshot.hasData && snapshot.data == true) {
              // Setelah login berhasil:
              return FutureBuilder(
                future: AuthService().getCurrentUser(),
                builder: (context, AsyncSnapshot userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  } else if (userSnapshot.hasData && userSnapshot.data != null) {
                    final user = userSnapshot.data;
                    Provider.of<CartProvider>(
                      context,
                      listen: false,
                    ).loadCart(user.id);
                    return const HomePage();
                  } else {
                    return const LoginPage();
                  }
                },
              );
            } else {
              return const LoginPage();
            }
          }
        },
      ),
    );
  }
}

class HomeMenu extends StatelessWidget {
  const HomeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu Utama')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Daftar Sparepart'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SparepartListPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Daftar Bengkel'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BengkelListPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> scheduleServiceReminderNotification() async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    1, // id notifikasi
    'Waktunya Servis Motor!',
    'Jangan lupa servis motor di bengkel terdekat agar tetap prima.',
    tz.TZDateTime.now(tz.local).add(const Duration(days: 30)), // 30 hari dari sekarang
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'service_reminder_channel',
        'Service Reminder',
        channelDescription: 'Pengingat servis motor berkala',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time, // agar bisa berulang di jam yang sama
  );
}

Future<void> schedulePromoSparepartNotification() async {
  final now = tz.TZDateTime.now(tz.local);
  // Jadwalkan pada menit genap berikutnya (misal: 12:02:00, 12:04:00, dst)
  final nextEvenMinute = now.minute.isEven
      ? now.add(Duration(minutes: 2 - (now.minute % 2), seconds: -now.second, milliseconds: -now.millisecond, microseconds: -now.microsecond))
      : now.add(Duration(minutes: 1, seconds: -now.second, milliseconds: -now.millisecond, microseconds: -now.microsecond));

  await flutterLocalNotificationsPlugin.zonedSchedule(
    2,
    'Promo Sparepart!',
    'Cek promo menarik sparepart motor hanya untukmu!',
    nextEvenMinute,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'promo_sparepart_channel',
        'Promo Sparepart',
        channelDescription: 'Notifikasi promo sparepart motor',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time, // hanya ini yang tersedia
  );
}

void requestNotificationPermission() async {
  // Minta izin ke pengguna untuk menampilkan notifikasi
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}