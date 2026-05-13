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
    // Run version check without blocking UI - show WelcomeView immediately
    // and let the version check happen in the background
    if (mounted) {
      setState(() {
        _isCheckingVersion = false;
      });
    }

    // Do version check in background after UI is ready
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await VersionCheckService.initialize();
        if (mounted) {
          await VersionCheckManager.checkAndShowUpdateDialog(
            context,
            showOnlyIfForceUpdate: true,
          );
        }
      } catch (e) {
        // Ignore errors - version check is optional
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a minimal loading indicator only while waiting for auth state
        // Don't use DashboardSkeleton here - let WelcomeView/UI transitions handle loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
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
