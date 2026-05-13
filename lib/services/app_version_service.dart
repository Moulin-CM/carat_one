import 'package:firebase_database/firebase_database.dart';
import '../models/app_version_model.dart';


class AppVersionService {
  static final DatabaseReference _versionRef =
      FirebaseDatabase.instance.ref('app_version');

  /// Fetch app version information from Firebase Realtime Database
  static Future<AppVersionModel?> getVersionInfo() async {
    try {
      final snapshot = await _versionRef.get();

      if (snapshot.value == null) {
        return null;
      }

      final data = Map<dynamic, dynamic>.from(
        snapshot.value as Map<Object?, Object?>,
      );

      return AppVersionModel.fromJson(data);
    } catch (e) {
      // If version check fails, return null to allow app to continue
      // This prevents the app from breaking if Firebase is unavailable
      print('Error fetching app version: $e');
      return null;
    }
  }

  /// Listen to version changes in real-time (optional, for periodic checks)
  static Stream<AppVersionModel?> getVersionInfoStream() {
    return _versionRef.onValue.map((event) {
      if (event.snapshot.value == null) {
        return null;
      }

      try {
        final data = Map<dynamic, dynamic>.from(
          event.snapshot.value as Map<Object?, Object?>,
        );
        return AppVersionModel.fromJson(data);
      } catch (e) {
        print('Error parsing version info: $e');
        return null;
      }
    });
  }
}

