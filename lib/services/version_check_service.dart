import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_version_model.dart';


class VersionCheckService {
  static PackageInfo? _packageInfo;

  /// Initialize package info (call once at app startup)
  static Future<void> initialize() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
  }

  /// Get current app version string (e.g., "1.0.2")
  static Future<String> getCurrentVersion() async {
    await initialize();
    return _packageInfo?.version ?? '0.0.0';
  }

  /// Get current build number (e.g., 2)
  static Future<int> getCurrentBuild() async {
    await initialize();
    return int.tryParse(_packageInfo?.buildNumber ?? '0') ?? 0;
  }

  /// Compare version strings (e.g., "1.0.2" vs "1.0.3")
  /// Returns: -1 if current < required, 0 if equal, 1 if current > required
  static int compareVersions(String currentVersion, String requiredVersion) {
    final currentParts = currentVersion.split('.').map(int.tryParse).toList();
    final requiredParts = requiredVersion.split('.').map(int.tryParse).toList();

    // Ensure both lists have the same length (pad with zeros)
    while (currentParts.length < requiredParts.length) {
      currentParts.add(0);
    }
    while (requiredParts.length < currentParts.length) {
      requiredParts.add(0);
    }

    // Compare each part
    for (int i = 0; i < currentParts.length; i++) {
      final current = currentParts[i] ?? 0;
      final required = requiredParts[i] ?? 0;

      if (current < required) return -1;
      if (current > required) return 1;
    }

    return 0;
  }

  /// Check if update is required based on version info
  static Future<bool> isUpdateRequired(AppVersionModel versionInfo) async {
    final currentVersion = await getCurrentVersion();
    final currentBuild = await getCurrentBuild();

    // If force update is enabled, check against minimum required version/build
    if (versionInfo.forceUpdate) {
      final versionCompare = compareVersions(currentVersion, versionInfo.minRequiredVersion);
      
      // If version is lower, update is required
      if (versionCompare < 0) {
        return true;
      }
      
      // If version is same but build is lower, update is required
      if (versionCompare == 0 && currentBuild < versionInfo.minRequiredBuild) {
        return true;
      }
    }

    return false;
  }

  /// Check if a newer version is available (optional update, not forced)
  static Future<bool> isNewerVersionAvailable(AppVersionModel versionInfo) async {
    final currentVersion = await getCurrentVersion();
    final currentBuild = await getCurrentBuild();

    final versionCompare = compareVersions(currentVersion, versionInfo.latestVersion);
    
    // If current version is lower, newer version is available
    if (versionCompare < 0) {
      return true;
    }
    
    // If version is same but build is lower, newer version is available
    if (versionCompare == 0 && currentBuild < versionInfo.latestBuild) {
      return true;
    }

    return false;
  }
}

