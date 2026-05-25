import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../app/router/app_router.dart';

import '../../../../app/theme/app_colors.dart';

import '../../../../core/storage/storage_service.dart';

import '../../../../core/widgets/custom_textfield.dart';

import '../../../../core/widgets/primary_button.dart';

import '../providers/auth_provider.dart';

import '../widgets/auth_footer.dart';

import 'register_screen.dart';

import 'forgot_password_screen.dart';

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
        user:
            authProvider.currentUser,
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

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),

          child: ConstrainedBox(
            constraints:
                BoxConstraints(
              minHeight: MediaQuery.of(
                          context)
                      .size
                      .height -
                  48,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                const SizedBox(
                  height: 60,
                ),

                const Text(
                  "Welcome Back 👋",

                  style: TextStyle(
                    fontSize: 34,
                    fontWeight:
                        FontWeight.bold,
                    color: AppColors
                        .textPrimary,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  "Monitor your glucose smarter",

                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors
                        .textSecondary,
                  ),
                ),

                const SizedBox(
                  height: 40,
                ),

                CustomTextField(
                  controller:
                      emailController,
                  hint: "Email",
                  keyboardType:
                      TextInputType
                          .emailAddress,
                ),

                const SizedBox(
                  height: 20,
                ),

                CustomTextField(
                  controller:
                      passwordController,
                  hint: "Password",
                  obscureText: true,
                ),

                const SizedBox(
                  height: 14,
                ),

                Align(
                  alignment: Alignment
                      .centerRight,

                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  const ForgotPasswordScreen(),
                        ),
                      );
                    },

                    child: const Text(
                      "Forgot Password?",
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                PrimaryButton(
                  title: "Login",
                  isLoading:
                      authProvider
                          .isLoading,
                  onTap:
                      _handleLogin,
                ),

                const SizedBox(
                  height: 20,
                ),

                AuthFooter(
                  title:
                      "Don't have an account?",
                  actionText:
                      "Register",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                const RegisterScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(
                  height: 40,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
