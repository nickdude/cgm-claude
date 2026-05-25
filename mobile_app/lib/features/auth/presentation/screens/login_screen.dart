import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../app/router/app_router.dart';

import '../../../../core/storage/storage_service.dart';

import '../providers/auth_provider.dart';

import '../widgets/auth_footer_link.dart';

import '../widgets/auth_primary_button.dart';

import '../widgets/auth_scaffold.dart';

import '../widgets/auth_text_field.dart';

import 'forgot_password_screen.dart';

import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  @override
  void dispose() {
    emailController.dispose();

    passwordController.dispose();

    super.dispose();
  }

  // Business logic preserved verbatim from the previous version.
  Future<void> _handleLogin() async {
    final email = emailController
        .text
        .trim();

    final password =
        passwordController.text
            .trim();

    if (email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter email and password",
          ),
        ),
      );

      return;
    }

    final authProvider = context
        .read<AuthProvider>();

    final success =
        await authProvider.login(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Welcome back!",
          ),
        ),
      );

      final token = await StorageService
          .getToken();

      if (!mounted) return;

      await AppRouter.goToHome(
        context,
        token: token,
        user: authProvider
            .currentUser,
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Login failed. Please check your credentials.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        context.watch<AuthProvider>();

    return AuthScaffold(
      title:
          "Take control of your health",
      subtitle:
          "Sign in to keep monitoring your glucose smarter.",
      showBackButton: true,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          AuthTextField(
            controller:
                emailController,
            label: "Email",
            hint:
                "you@example.com",
            prefixIcon:
                Icons.mail_outline,
            keyboardType:
                TextInputType
                    .emailAddress,
          ),

          const SizedBox(height: 16),

          AuthTextField(
            controller:
                passwordController,
            label: "Password",
            hint: "Enter your password",
            prefixIcon:
                Icons.lock_outline,
            obscureText: true,
            textInputAction:
                TextInputAction.done,
            onSubmitted: (_) =>
                _handleLogin(),
          ),

          const SizedBox(height: 8),

          Align(
            alignment:
                Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ForgotPasswordScreen(),
                  ),
                );
              },
              style: TextButton
                  .styleFrom(
                padding:
                    EdgeInsets.zero,
                minimumSize:
                    Size.zero,
                tapTargetSize:
                    MaterialTapTargetSize
                        .shrinkWrap,
              ),
              child: const Text(
                "Forgot Password?",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight
                          .w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          AuthPrimaryButton(
            label: "Login",
            isLoading: authProvider
                .isLoading,
            onTap: _handleLogin,
          ),

          const SizedBox(height: 24),

          AuthFooterLink(
            prefix:
                "Don't have an account?",
            actionText: "Register",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const RegisterScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
