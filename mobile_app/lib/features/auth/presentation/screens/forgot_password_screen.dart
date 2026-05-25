import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../core/widgets/custom_textfield.dart';

import '../../../../core/widgets/primary_button.dart';

import '../providers/auth_provider.dart';

import '../widgets/auth_header.dart';

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
  Widget build(BuildContext context) {
    final authProvider =
        context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(),

      body: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 40),

            const AuthHeader(
              title: "Forgot Password",

              subtitle:
                  "We’ll send reset link to your email",
            ),

            const SizedBox(height: 40),

            CustomTextField(
              controller:
                  emailController,

              hint: "Email",
            ),

            const SizedBox(height: 30),

            PrimaryButton(
              title: "Send Reset Link",

              isLoading:
                  authProvider.isLoading,

              onTap: () async {
                final success =
                    await authProvider
                        .forgotPassword(
                  email:
                      emailController.text
                          .trim(),
                );

                if (success) {
                  ScaffoldMessenger.of(
                          context)
                      .showSnackBar(
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
          ],
        ),
      ),
    );
  }
}