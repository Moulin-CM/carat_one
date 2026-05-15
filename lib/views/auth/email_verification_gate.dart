import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../constants/app_translations.dart';
import '../../services/auth_service.dart';

class EmailVerificationGate extends StatefulWidget {
  const EmailVerificationGate({super.key});

  @override
  State<EmailVerificationGate> createState() => _EmailVerificationGateState();
}

class _EmailVerificationGateState extends State<EmailVerificationGate> {
  final AuthService _authService = AuthService();
  Timer? _pollTimer;
  bool _checking = false;
  bool _resending = false;
  bool _signingOut = false;
  String? _message;
  Color _messageColor = Colors.red;

  @override
  void initState() {
    super.initState();
    // Background poll every 5s — AuthWrapper rebuilds via userChanges once
    // getIdToken(true) fires after a successful reload.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _silentCheck();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _silentCheck() async {
    if (_checking) return;
    try {
      await _authService.reloadAndCheckEmailVerified();
    } catch (_) {
      // Silent; user-driven button surfaces errors.
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _message = null;
    });
    try {
      final verified = await _authService.reloadAndCheckEmailVerified();
      if (!mounted) return;
      if (!verified) {
        setState(() {
          _message =
              'Still not verified. Please click the link in your inbox.'.tr;
          _messageColor = Colors.red.shade700;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = e.toString().replaceAll('Exception: ', '');
        _messageColor = Colors.red.shade700;
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    if (_resending) return;
    setState(() {
      _resending = true;
      _message = null;
    });
    try {
      await _authService.sendEmailVerification();
      if (!mounted) return;
      setState(() {
        _message = 'Verification email sent. Check your inbox.'.tr;
        _messageColor = Colors.green.shade700;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = e.toString().replaceAll('Exception: ', '');
        _messageColor = Colors.red.shade700;
      });
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      // Best-effort delete: the unverified account is orphaned if the user
      // abandons the flow. delete() succeeds for users created in the current
      // session; otherwise we just sign out.
      try {
        await _authService.deleteCurrentUser();
      } catch (_) {}
      await _authService.signOut();
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4F8AF4);
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE7EEFF), Color(0xFFF9FBFF)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.85),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 56,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verify your email'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification link to'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Click the link in the email, then tap the button below to continue.'
                        .tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _messageColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _messageColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _messageColor, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _checking ? null : _check,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                      shadowColor: accent.withOpacity(0.4),
                    ),
                    child: _checking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            "I've verified — Continue".tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _resending ? null : _resend,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: accent),
                    ),
                    child: _resending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(accent),
                            ),
                          )
                        : Text(
                            'Resend verification email'.tr,
                            style: const TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _signingOut ? null : _signOut,
                    child: Text(
                      _signingOut
                          ? 'Signing out...'.tr
                          : 'Cancel & sign out'.tr,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
