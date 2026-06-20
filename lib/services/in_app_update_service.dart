import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform, debugPrint;
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import '../constants/app_translations.dart';

/// Wrapper around Google Play's In-App Updates API.
///
/// Two flows are supported:
///   • Immediate — full-screen blocking UI, used when the release is marked
///     high priority (priority >= 4) in Play Console. This is the
///     equivalent of the legacy custom "force update" dialog.
///   • Flexible — background download; once ready, the user is prompted to
///     install. Used for any non-priority update so the user can keep
///     working while the download runs.
///
/// The whole flow is a no-op on non-Android platforms and silently
/// degrades when Play Services are unavailable (e.g. sideloaded builds,
/// debug installs, devices without Play Store).
class InAppUpdateService {
  static bool _flexibleInProgress = false;

  /// Entry point — call once on app start (after the auth UI is up).
  ///
  /// Returns `true` when an immediate update was started (caller can stop
  /// further work), `false` otherwise.
  static Future<bool> checkForUpdates(BuildContext context) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return false;
      }

      // Priority is set in Play Console (0–5). 4+ is treated as "must
      // update now"; lower priorities use the non-blocking flexible flow.
      final isHighPriority = info.updatePriority >= 4;

      if (isHighPriority && info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return true;
      }

      if (info.flexibleUpdateAllowed && context.mounted) {
        await _startFlexibleFlow(context);
      }
      return false;
    } catch (e) {
      // No Play Store, network error, or device too old — fail silently so
      // the app stays usable. The next launch will retry.
      debugPrint('In-app update check failed: $e');
      return false;
    }
  }

  static Future<void> _startFlexibleFlow(BuildContext context) async {
    if (_flexibleInProgress) return;
    _flexibleInProgress = true;
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success && context.mounted) {
        _promptCompleteFlexibleUpdate(context);
      }
    } catch (e) {
      debugPrint('Flexible update failed to start: $e');
    } finally {
      _flexibleInProgress = false;
    }
  }

  static void _promptCompleteFlexibleUpdate(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text('Update downloaded. Restart to install.'.tr),
        action: SnackBarAction(
          label: 'Restart'.tr,
          onPressed: () async {
            try {
              await InAppUpdate.completeFlexibleUpdate();
            } catch (e) {
              debugPrint('Failed to complete flexible update: $e');
            }
          },
        ),
      ),
    );
  }
}
