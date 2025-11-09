import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  // fixed warning: use super.key for constructors
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      // CRITICAL: Check if widget is still mounted before using ref
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final firebaseService = ref.read(firebaseServiceProvider);
        await firebaseService.reloadUser();
        final user = firebaseService.currentUser;

        if (user?.emailVerified ?? false) {
          timer.cancel();

          if (mounted) {
            await firebaseService.updateEmailVerificationStatus();
            // Navigation handled automatically by authStateProvider in main.dart
          }
        }
      } catch (e) {
        // If error occurs (widget disposed or network issue), cancel timer
        debugPrint('Verification check error: $e');
        timer.cancel();
      }
    });
  }

  Future<void> _resendEmail() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(firebaseServiceProvider).resendVerificationEmail();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send email';

      if (e.code == 'too-many-requests') {
        message =
            'Too many requests. Please wait a few minutes before trying again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread,
                size: 100,
                color: Color(0xFFF5C842),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We\'ve sent a verification email to your address. Please check your inbox and click the verification link.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resendEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5C842),
                    foregroundColor: const Color(0xFF1A1D2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1A1D2E),
                          ),
                        )
                      : const Text(
                          'Resend Email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  // Cancel timer before signing out
                  _timer?.cancel();

                  if (mounted) {
                    await ref.read(firebaseServiceProvider).signOut();
                  }
                },
                child: const Text(
                  'Back to Login',
                  style: TextStyle(
                    color: Color(0xFFF5C842),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
