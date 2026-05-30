import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../../../app/constants/social_auth_constants.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/storage/storage_service.dart';
import '../providers/auth_provider.dart';

Future<void> handleGoogleSocialLogin(
  BuildContext context, {
  required String successMessage,
}) async {
  final authProvider = context.read<AuthProvider>();

  if (authProvider.isLoading) return;

  try {
    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: SocialAuthConstants.googleClientId,
    );

    final googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      return;
    }

    final auth = await googleUser.authentication;
    final idToken = auth.idToken;

    if (idToken == null || idToken.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to continue with Google right now'),
          ),
        );
      }

      return;
    }

    final success = await authProvider.loginWithGoogle(idToken: idToken);

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google login failed. Please try again.'),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );

    final token = await StorageService.getToken();

    if (!context.mounted) return;

    await AppRouter.goToHome(
      context,
      token: token,
      user: authProvider.currentUser,
    );
  } catch (_) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google sign in failed. Please try again.'),
      ),
    );
  }
}

Future<void> handleFacebookSocialLogin(
  BuildContext context, {
  required String successMessage,
}) async {
  final authProvider = context.read<AuthProvider>();

  if (authProvider.isLoading) return;

  try {
    final result = await FacebookAuth.instance.login(
      permissions: const ['email', 'public_profile'],
    );

    if (result.status != LoginStatus.success) {
      return;
    }

    final accessToken = result.accessToken?.tokenString;

    if (accessToken == null || accessToken.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to continue with Facebook right now'),
          ),
        );
      }

      return;
    }

    final success = await authProvider.loginWithFacebook(
      accessToken: accessToken,
    );

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Facebook login failed. Please try again.'),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );

    final token = await StorageService.getToken();

    if (!context.mounted) return;

    await AppRouter.goToHome(
      context,
      token: token,
      user: authProvider.currentUser,
    );
  } catch (_) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Facebook sign in failed. Please try again.'),
      ),
    );
  }
}