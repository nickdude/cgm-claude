import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../core/widgets/custom_textfield.dart';

import '../../../../core/widgets/primary_button.dart';

import '../providers/auth_provider.dart';

import '../widgets/auth_footer.dart';

import '../widgets/auth_header.dart';

import 'verify_email_screen.dart';

class RegisterScreen
    extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final fullNameController =
      TextEditingController();

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

              const AuthHeader(
                title: "Create Account 🚀",

                subtitle:
                    "Start monitoring your glucose smarter",
              ),

              const SizedBox(height: 40),

              CustomTextField(
                controller:
                    fullNameController,

                hint: "Full Name",
              ),

              const SizedBox(height: 20),

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

              const SizedBox(height: 30),

              PrimaryButton(
                title: "Register",

                isLoading:
                    authProvider.isLoading,

                onTap: () async {
                  final success =
                      await authProvider
                          .register(
                    fullName:
                        fullNameController.text
                            .trim(),

                    email:
                        emailController.text
                            .trim(),

                    password:
                        passwordController.text
                            .trim(),
                  );

                  if (success) {
                    ScaffoldMessenger.of(
                            context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Verification email sent",
                        ),
                      ),
                    );

                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const VerifyEmailScreen(),
                        ),
                    );
                  }
                },
              ),

              const SizedBox(height: 20),

              AuthFooter(
                title:
                    "Already have an account?",

                actionText: "Login",

                onTap: () {
                  Navigator.pop(
                    context,
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