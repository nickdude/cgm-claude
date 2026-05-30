import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class AuthHeader
    extends StatelessWidget {
  final String title;

  final String subtitle;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          title,

          style: const TextStyle(
            fontSize: 34,

            fontWeight:
                FontWeight.bold,

            color:
                AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          subtitle,

          style: const TextStyle(
            fontSize: 16,

            color:
                AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}