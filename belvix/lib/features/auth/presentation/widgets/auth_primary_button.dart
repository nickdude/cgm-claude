import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Black filled CTA used across the auth screens.
///
/// Behaves identically to the legacy `PrimaryButton` (loading spinner
/// disables tap), so it's a drop-in for any existing onTap handler.
class AuthPrimaryButton
    extends StatelessWidget {
  final String label;

  final VoidCallback onTap;

  final bool isLoading;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isLoading
              ? AppColors
                  .textPrimary
                  .withOpacity(0.7)
              : AppColors
                  .textPrimary,
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors
                  .textPrimary
                  .withOpacity(
                0.18,
              ),
              blurRadius: 14,
              offset:
                  const Offset(
                0,
                6,
              ),
            ),
          ],
        ),
        child: Material(
          color:
              Colors.transparent,
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          child: InkWell(
            borderRadius:
                BorderRadius
                    .circular(14),
            onTap: isLoading
                ? null
                : onTap,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2.2,
                        valueColor:
                            AlwaysStoppedAnimation<
                                Color>(
                          Colors
                              .white,
                        ),
                      ),
                    )
                  : Text(
                      label,
                      style:
                          const TextStyle(
                        color: Colors
                            .white,
                        fontSize:
                            16,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
