import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';

import '../../../../core/widgets/custom_textfield.dart';

import '../../../../core/widgets/primary_button.dart';

import '../providers/auth_provider.dart';

import '../widgets/auth_footer.dart';

import 'register_screen.dart';

import '../../../dashboard/presentation/screens/dashboard_screen.dart';

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
  Widget build(BuildContext context) {
    final authProvider =
        context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Spacer(),

              const Text(
                "Welcome Back 👋",

                style: TextStyle(
                  fontSize: 34,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Monitor your glucose smarter",

                style: TextStyle(
                  fontSize: 16,
                  color: AppColors
                      .textSecondary,
                ),
              ),

              const SizedBox(height: 40),

              CustomTextField(
                controller:
                    emailController,
                hint: "Email",
                keyboardType:
                    TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              CustomTextField(
                controller:
                    passwordController,
                hint: "Password",
                obscureText: true,
              ),

              const SizedBox(height: 14),

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

                  child: const Text(
                    "Forgot Password?",
                  ),
                ),
              ),

              const SizedBox(height: 20),

              PrimaryButton(
                title: "Login",

                isLoading:
                    authProvider.isLoading,

                onTap: () async {
                  final success =
                      await authProvider
                          .login(
                    email:
                        emailController.text
                            .trim(),

                    password:
                        passwordController
                            .text
                            .trim(),
                  );

                  if (success) {
                    ScaffoldMessenger.of(
                            context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Login Success",
                        ),
                      ),
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const DashboardScreen(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(
                            context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Login Failed",
                        ),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 20),

              AuthFooter(
                title:
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

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}