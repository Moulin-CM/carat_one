import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/version_check_manager.dart';
import '../../services/version_check_service.dart';
import '../../widgets/dashboard_skeleton.dart';
import 'email_verification_gate.dart';
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
      // userChanges() fires on profile updates (including emailVerified via
      // getIdToken(true)) — authStateChanges() would not.
      stream: FirebaseAuth.instance.userChanges(),
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

        final user = snapshot.data;
        if (user == null) {
          return const WelcomeView();
        }
        if (!user.emailVerified) {
          return const EmailVerificationGate();
        }
        return const MainShell();
      },
    );
  }
}
