import 'package:flutter/material.dart';
import 'app_version_service.dart';
import 'version_check_service.dart';
import '../models/app_version_model.dart';
import '../widgets/force_update_dialog.dart';

class VersionCheckManager {
  /// Check for app update and show dialog if required
  /// Returns true if update is required (and dialog is shown), false otherwise
  static Future<bool> checkAndShowUpdateDialog(
    BuildContext context, {
    bool showOnlyIfForceUpdate = true,
  }) async {
    try {
      // Fetch version info from Firebase
      final versionInfo = await AppVersionService.getVersionInfo();

      // If no version info available, allow app to continue
      if (versionInfo == null) {
        return false;
      }

      // Check if update is required
      final isUpdateRequired = await VersionCheckService.isUpdateRequired(versionInfo);

      // If force update is required, show dialog
      if (isUpdateRequired && versionInfo.forceUpdate) {
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false, // Cannot dismiss force update dialog
            builder: (context) => ForceUpdateDialog(
              updateMessage: versionInfo.updateMessage,
              updateUrl: versionInfo.updateUrl,
              isForceUpdate: true,
            ),
          );
        }
        return true;
      }

      // Optional: Show update dialog for newer versions (non-forced)
      if (!showOnlyIfForceUpdate) {
        final isNewerAvailable = await VersionCheckService.isNewerVersionAvailable(versionInfo);
        if (isNewerAvailable && context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: true, // Can dismiss optional update
            builder: (context) => ForceUpdateDialog(
              updateMessage: versionInfo.updateMessage,
              updateUrl: versionInfo.updateUrl,
              isForceUpdate: false,
            ),
          );
        }
      }

      return false;
    } catch (e) {
      // If version check fails, allow app to continue
      // This prevents the app from breaking if Firebase is unavailable
      print('Error checking app version: $e');
      return false;
    }
  }

  /// Check for app update silently (without showing dialog)
  /// Returns AppVersionModel if update is required, null otherwise
  static Future<AppVersionModel?> checkForUpdate() async {
    try {
      final versionInfo = await AppVersionService.getVersionInfo();
      if (versionInfo == null) {
        return null;
      }

      final isUpdateRequired = await VersionCheckService.isUpdateRequired(versionInfo);
      if (isUpdateRequired && versionInfo.forceUpdate) {
        return versionInfo;
      }

      return null;
    } catch (e) {
      print('Error checking app version: $e');
      return null;
    }
  }
}

