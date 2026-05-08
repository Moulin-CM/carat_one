import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/version_check_manager.dart';
import '../../services/version_check_service.dart';
import '../../widgets/dashboard_skeleton.dart';
import 'welcome_view.dart';
import '../shell/main_shell.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isCheckingVersion = true;

  @override
  void initState() {
    super.initState();
    _checkVersionOnStartup();
  }

  Future<void> _checkVersionOnStartup() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Both calls do network IO + plugin channel work; awaiting them on
      // the platform thread keeps the UI thread free.
      await VersionCheckService.initialize();
      if (mounted) {
        await VersionCheckManager.checkAndShowUpdateDialog(
          context,
          showOnlyIfForceUpdate: true,
        );
      }
    }
    if (mounted) {
      setState(() {
        _isCheckingVersion = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingVersion) {
      // Render the dashboard layout as a shimmer placeholder so the
      // post-splash transition lands on something that already looks
      // like the destination, not a white screen with a spinner.
      // Render the bottom-nav placeholder too — destination is MainShell
      // (when logged in) which has a bottom nav, so showing it here keeps
      // the navbar from popping in 2-3 seconds later.
      return const DashboardSkeleton(showBottomNav: true);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still waiting for Firebase to restore session
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Render the bottom-nav placeholder too — destination is MainShell
      // (when logged in) which has a bottom nav, so showing it here keeps
      // the navbar from popping in 2-3 seconds later.
      return const DashboardSkeleton(showBottomNav: true);
        }

        final isLoggedIn = snapshot.hasData && snapshot.data != null;

        if (isLoggedIn) {
          return const MainShell();
        }
        return const WelcomeView();
      },
    );
  }
}
