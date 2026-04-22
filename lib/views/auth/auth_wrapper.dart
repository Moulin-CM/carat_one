import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/version_check_manager.dart';
import '../../services/version_check_service.dart';
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still waiting for Firebase to restore session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
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