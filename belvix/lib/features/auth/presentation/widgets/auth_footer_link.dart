import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// "Don't have an account? Register" style footer used across auth.
///
/// Drop-in replacement for the legacy `AuthFooter`; same constructor
/// surface so existing call-sites need no logic change.
class AuthFooterLink
    extends StatelessWidget {
  final String prefix;

  final String actionText;

  final VoidCallback onTap;

  const AuthFooterLink({
    super.key,
    required this.prefix,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: AppColors
                .textSecondary,
          ),
          children: [
            TextSpan(
              text: "$prefix ",
            ),
            WidgetSpan(
              alignment:
                  PlaceholderAlignment
                      .middle,
              child: GestureDetector(
                onTap: onTap,
                behavior:
                    HitTestBehavior
                        .opaque,
                child: Text(
                  actionText,
                  style:
                      const TextStyle(
                    fontSize: 14,
                    color: AppColors
                        .primary,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
