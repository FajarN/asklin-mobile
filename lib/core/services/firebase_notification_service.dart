import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_client.dart';
import '../network/api_constants.dart';
import '../storage/secure_storage_service.dart';
import '../../features/pengurus/presentation/verifikasi_klinik_detail_screen.dart';
import '../../features/notifikasi/presentation/notifikasi_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handler untuk notifikasi saat aplikasi terminated atau di latar belakang
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId} - ${message.notification?.title}");
  }
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final _apiClient = ApiClient();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool _isInitialized = false;
  bool _isFirebaseAvailable = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;
  bool get isFirebaseAvailable => _isFirebaseAvailable;

  /// Inisialisasi Firebase & Layanan Push Notification
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      _isFirebaseAvailable = true;
      if (kDebugMode) print("Firebase Core initialized successfully.");
    } catch (e) {
      _isFirebaseAvailable = false;
      if (kDebugMode) {
        print("Firebase Core not configured or missing google-services.json: $e");
      }
    }

    // Inisialisasi plugin notifikasi lokal (untuk heads-up banner saat foreground)
    await _initLocalNotifications();

    if (_isFirebaseAvailable) {
      await _setupFcmListeners();
    }

    _isInitialized = true;
  }

  /// Konfigurasi Notifikasi Lokal untuk Android
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleNotificationPayload(payload);
        } else {
          _navigateToNotificationScreen();
        }
      },
    );

    // Buat Notification Channel untuk Android 8.0+ (Oreo ke atas)
    const androidChannel = AndroidNotificationChannel(
      'asklin_high_importance_channel',
      'Notifikasi Resmi ASKLIN',
      description: 'Saluran untuk notifikasi verifikasi klinik, pengurus, dan informasi penting ASKLIN.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }
  }

  /// Setup Listener FCM (Foreground, Background, Token Refresh)
  Future<void> _setupFcmListeners() async {
    final messaging = FirebaseMessaging.instance;

    // 1. Minta izin notifikasi (wajib Android 13+)
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('User notification permission status: ${settings.authorizationStatus}');
      }
    } catch (e) {
      if (kDebugMode) print('Permission request error: $e');
    }

    // 2. Registrasi background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Ambil FCM Token perangkat
    try {
      _fcmToken = await messaging.getToken();
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        if (kDebugMode) print('FCM Device Token: $_fcmToken');
        await syncTokenToBackend(_fcmToken!);
      }
    } catch (e) {
      if (kDebugMode) print('Error getting FCM token: $e');
    }

    // 4. Dengarkan pembaruan token
    messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      syncTokenToBackend(newToken);
    });

    // 5. Dengarkan notifikasi yang masuk saat aplikasi sedang dibuka (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground notification received: ${message.notification?.title}');
      }
      _showForegroundNotification(message);
    });

    // 6. Dengarkan saat pengguna mengetuk notifikasi (dari background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notification tapped from background: ${message.data}');
      }
      _handleRemoteMessageNavigation(message);
    });

    // 7. Cek apakah aplikasi dibuka pertama kali dari notifikasi (Terminated state)
    try {
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessageNavigation(initialMessage);
      }
    } catch (_) {}
  }

  /// Tampilkan Heads-Up Notification saat aplikasi aktif di layar depan (Foreground)
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = const AndroidNotificationDetails(
      'asklin_high_importance_channel',
      'Notifikasi Resmi ASKLIN',
      channelDescription: 'Saluran untuk notifikasi verifikasi klinik, pengurus, dan informasi penting ASKLIN.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFC62828), // AppColors.primaryRed
    );

    final details = NotificationDetails(android: androidDetails);

    // Kirim string JSON atau ID anggota sebagai payload
    final anggotaId = message.data['anggota_id'] ?? '';
    final screen = message.data['screen'] ?? '';
    final payloadString = '$screen|$anggotaId';

    await _localNotifications.show(
      message.hashCode,
      notification.title ?? 'Notifikasi ASKLIN',
      notification.body ?? '',
      details,
      payload: payloadString,
    );
  }

  /// Kirim FCM Token ke backend API Laravel
  Future<void> syncTokenToBackend(String token) async {
    try {
      final authToken = await SecureStorageService.getToken();
      if (authToken == null || authToken.isEmpty) return;

      await _apiClient.dio.post(
        ApiConstants.updateFcmToken,
        data: {'fcm_token': token},
      );

      if (kDebugMode) print('FCM Token successfully synced to ASKLIN backend.');
    } catch (e) {
      if (kDebugMode) print('Failed to sync FCM Token to backend: $e');
    }
  }

  /// Berlangganan topik sesuai peran pengguna
  Future<void> subscribeToRoleTopics({
    required String role,
    String? kotaId,
    String? anggotaId,
  }) async {
    if (!_isFirebaseAvailable) return;

    final messaging = FirebaseMessaging.instance;
    final rLower = role.toLowerCase();

    try {
      // Topik umum untuk seluruh pengguna
      await messaging.subscribeToTopic('asklin_all');

      // Topik untuk Pengurus Cabang
      if (rLower.contains('cabang')) {
        await messaging.subscribeToTopic('asklin_pengurus_cabang');
        if (kotaId != null && kotaId.isNotEmpty) {
          await messaging.subscribeToTopic('asklin_cabang_$kotaId');
        }
      }

      // Topik untuk Ketua Umum, Sekjen, dan Pengurus Pusat
      if (rLower.contains('sekjen') ||
          rLower.contains('ketua') ||
          rLower.contains('pusat') ||
          rLower.contains('superadmin')) {
        await messaging.subscribeToTopic('asklin_pusat');
        await messaging.subscribeToTopic('asklin_ketum_sekjen');
      }

      // Topik untuk Klinik
      if (rLower.contains('klinik')) {
        await messaging.subscribeToTopic('asklin_klinik');
        if (anggotaId != null && anggotaId.isNotEmpty) {
          await messaging.subscribeToTopic('asklin_klinik_$anggotaId');
        }
      }

      if (kDebugMode) print('Subscribed to topics for role: $role');
    } catch (e) {
      if (kDebugMode) print('Error subscribing to topics: $e');
    }
  }

  /// Navigasi berdasarkan klik notifikasi
  void _handleRemoteMessageNavigation(RemoteMessage message) {
    final screen = message.data['screen']?.toString();
    final anggotaIdStr = message.data['anggota_id']?.toString();
    final anggotaId = anggotaIdStr != null ? int.tryParse(anggotaIdStr) : null;

    _navigateToScreen(screen, anggotaId);
  }

  void _handleNotificationPayload(String payload) {
    final parts = payload.split('|');
    final screen = parts.isNotEmpty ? parts[0] : '';
    final anggotaIdStr = parts.length > 1 ? parts[1] : '';
    final anggotaId = int.tryParse(anggotaIdStr);

    _navigateToScreen(screen, anggotaId);
  }

  Future<void> _navigateToScreen(String? screen, int? anggotaId) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final userRole = await SecureStorageService.getUserRole() ?? 'Pengurus ASKLIN';

    if (screen == 'verifikasi_detail' && anggotaId != null && anggotaId > 0) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifikasiKlinikDetailScreen(
            anggotaId: anggotaId,
            userRole: userRole,
          ),
        ),
      );
    } else {
      _navigateToNotificationScreen();
    }
  }

  void _navigateToNotificationScreen() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotifikasiScreen()),
    );
  }
}
