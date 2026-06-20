import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/in_app_update_service.dart';
import 'email_verification_gate.dart';
import 'welcome_view.dart';
import '../shell/main_shell.dart';


class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Defer to first frame so that ScaffoldMessenger is mounted before the
    // flexible-update flow tries to show a SnackBar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        InAppUpdateService.checkForUpdates(context);
      }
    });
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
