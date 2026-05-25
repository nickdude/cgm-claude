import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

import '../widgets/auth_footer_link.dart';

import '../widgets/auth_primary_button.dart';

import '../widgets/auth_scaffold.dart';

import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen
    extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
  });

  @override
  State<ForgotPasswordScreen>
      createState() =>
          _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final emailController =
      TextEditingController();

  @override
  void dispose() {
    emailController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        context.watch<AuthProvider>();

    return AuthScaffold(
      title: "Forgot password?",
      subtitle:
          "Enter the email you used to sign up — we'll send you a reset link.",
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
            textInputAction:
                TextInputAction.done,
          ),

          const SizedBox(height: 24),

          // Business logic preserved verbatim from the previous
          // version — only the visual wrapper changed.
          AuthPrimaryButton(
            label: "Send reset link",
            isLoading: authProvider
                .isLoading,
            onTap: () async {
              final success =
                  await authProvider
                      .forgotPassword(
                email:
                    emailController
                        .text
                        .trim(),
              );

              if (success) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Reset email sent",
                    ),
                  ),
                );

                Navigator.pop(
                  context,
                );
              }
            },
          ),

          const SizedBox(height: 24),

          AuthFooterLink(
            prefix:
                "Remember your password?",
            actionText: "Login",
            onTap: () {
              Navigator.pop(
                context,
              );
            },
          ),
        ],
      ),
    );
  }
}
