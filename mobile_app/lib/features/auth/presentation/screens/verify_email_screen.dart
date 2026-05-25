import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

import '../../../../core/widgets/primary_button.dart';

class VerifyEmailScreen
    extends StatelessWidget {
  const VerifyEmailScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              height: 120,
              width: 120,

              decoration: BoxDecoration(
                color: AppColors.primary
                    .withOpacity(0.1),

                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.email_outlined,

                size: 60,

                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Verify Your Email",

              style: TextStyle(
                fontSize: 30,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "We sent a verification link to your email address.",

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 16,

                color:
                    AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 40),

            PrimaryButton(
              title: "Back To Login",

              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}