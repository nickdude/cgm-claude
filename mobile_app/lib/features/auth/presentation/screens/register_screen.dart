import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

import '../widgets/auth_footer_link.dart';

import '../widgets/auth_primary_button.dart';

import '../widgets/auth_scaffold.dart';

import '../widgets/auth_text_field.dart';

import '../widgets/social_button.dart';

import '../helpers/social_auth_actions.dart';

import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final fullNameController = TextEditingController();

  final phoneNumberController = TextEditingController();

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  @override
  void dispose() {
    fullNameController.dispose();

    phoneNumberController.dispose();

    emailController.dispose();

    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AuthScaffold(
      title: "Create your account",
      subtitle: "Start monitoring your glucose smarter.",
      showBackButton: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthTextField(
            controller: fullNameController,
            label: "Full name",
            hint: "Jane Doe",
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.name,
          ),

          const SizedBox(height: 16),

          AuthTextField(
            controller: phoneNumberController,
            label: "Phone number",
            hint: "+1 555 123 4567",
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 16),

          AuthTextField(
            controller: emailController,
            label: "Email",
            hint: "you@example.com",
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          AuthTextField(
            controller: passwordController,
            label: "Password",
            hint: "At least 8 characters",
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            textInputAction: TextInputAction.done,
          ),

          const SizedBox(height: 24),

          // Business logic preserved verbatim from the previous
          // version — only the visual wrapper changed.
          AuthPrimaryButton(
            label: "Register",
            isLoading: authProvider.isLoading,
            onTap: () async {
              final success = await authProvider.register(
                fullName: fullNameController.text.trim(),
                phoneNumber: phoneNumberController.text.trim(),
                email: emailController.text.trim(),
                password: passwordController.text.trim(),
              );

              if (!context.mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Verification email sent")),
                );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
                );
              }
            },
          ),

          const SizedBox(height: 24),

          SocialAuthButtons(
            isLoading: authProvider.isLoading,
            onGoogleTap: () => handleGoogleSocialLogin(
              context,
              successMessage: 'Account ready!',
            ),
            onFacebookTap: () => handleFacebookSocialLogin(
              context,
              successMessage: 'Account ready!',
            ),
          ),

          const SizedBox(height: 24),

          AuthFooterLink(
            prefix: "Already have an account?",
            actionText: "Login",
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
