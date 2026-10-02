import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Inisialisasi FCM: Minta izin, ambil token, simpan ke Firestore, dan atur listener
  static Future<void> initFCM() async {
    // 1. Minta Izin Notifikasi (Android 13+ & iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Izin notifikasi diberikan.');
      
      // 2. Ambil token pertama kali & simpan
      await saveFCMToken();

      // 3. Pasang listener jika token diperbarui otomatis oleh Firebase
      _setupTokenRefreshListener();
    } else {
      debugPrint('Izin notifikasi ditolak oleh pengguna.');
    }
  }

  /// Mengambil FCM Token dari perangkat dan menyimpannya ke Firestore user
  static Future<String?> saveFCMToken() async {
    try {
      String? token = await _messaging.getToken();
      debugPrint("FCM Token Perangkat: $token");

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return token;
    } catch (e) {
      debugPrint("Gagal menyimpan FCM Token: $e");
      return null;
    }
  }

  /// Mendengarkan perubahan token jika di-refresh oleh Firebase
  static void _setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((newToken) async {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({
          'fcmToken': newToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  /// Menghapus FCM Token dari Firestore saat user Logout
  static Future<void> removeFCMTokenOnLogout() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'fcmToken': FieldValue.delete(),
        });
        debugPrint("FCM Token berhasil dihapus dari Firestore saat logout.");
      }
    } catch (e) {
      debugPrint("Gagal menghapus FCM Token saat logout: $e");
    }
  }
}