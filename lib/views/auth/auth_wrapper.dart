import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/version_check_manager.dart';
import '../../services/version_check_service.dart';
import 'welcome_view.dart';
import '../dashboard/dashboard_view.dart';

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
    // Initialize version check service
    await VersionCheckService.initialize();

    // Check for update and show dialog if required
    if (mounted) {
      await VersionCheckManager.checkAndShowUpdateDialog(
        context,
        showOnlyIfForceUpdate: true,
      );
    }

    // Mark version check as complete
    if (mounted) {
      setState(() {
        _isCheckingVersion = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking version on first launch
    if (_isCheckingVersion) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // After version check, proceed with auth check
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, show dashboard
        if (snapshot.hasData && snapshot.data != null) {
          return const DashboardView();
        }

        // If user is not logged in, show welcome screen
        return const WelcomeView();
      },
    );
  }
}

