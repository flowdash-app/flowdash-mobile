import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);

    final analytics = ref.read(analyticsServiceProvider);
    final trace = analytics.startTrace('sign_in_with_google');
    trace?.start();

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithGoogle();

      await analytics.logSuccess(
        action: 'sign_in_with_google',
      );
      trace?.stop();
    } on GoogleSignInException catch (e) {
      // Handle Google Sign-In specific errors
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // User canceled - don't show error or log as failure
        trace?.stop();
        return;
      } else {
        // Other Google Sign-In errors
        await analytics.logFailure(
          action: 'sign_in_with_google',
          error: e.toString(),
        );
        trace?.stop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign in failed: ${e.toString()}'),
            ),
          );
        }
      }
    } catch (e) {
      await analytics.logFailure(
        action: 'sign_in_with_google',
        error: e.toString(),
      );
      trace?.stop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${e.toString()}'),
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
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleSignIn,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.login),
      label: Text(_isLoading ? 'Signing in...' : 'Sign in with Google'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
