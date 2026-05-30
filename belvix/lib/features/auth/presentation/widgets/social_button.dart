import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D0F172A),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isLoading ? null : onTap,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: iconColor, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({
    super.key,
    required this.isLoading,
    required this.onGoogleTap,
    required this.onFacebookTap,
  });

  final bool isLoading;
  final VoidCallback onGoogleTap;
  final VoidCallback onFacebookTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7EDF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
        //   Row(
        //     children: [
        //       Container(
        //         padding: const EdgeInsets.all(8),
        //         decoration: BoxDecoration(
        //           color: AppColors.primary.withValues(alpha: 0.08),
        //           borderRadius: BorderRadius.circular(12),
        //         ),
        //         child: const Icon(
        //           Icons.bolt_rounded,
        //           color: AppColors.primary,
        //           size: 18,
        //         ),
        //       ),
        //       const SizedBox(width: 10),
        //       const Expanded(
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             Text(
        //               'Fast sign in',
        //               style: TextStyle(
        //                 color: AppColors.textPrimary,
        //                 fontSize: 14,
        //                 fontWeight: FontWeight.w800,
        //               ),
        //             ),
        //             SizedBox(height: 2),
        //             Text(
        //               'Use Google or Facebook to continue',
        //               style: TextStyle(
        //                 color: AppColors.textSecondary,
        //                 fontSize: 12,
        //                 height: 1.35,
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackButtons = constraints.maxWidth < 360;

              if (stackButtons) {
                return Column(
                  children: [
                    SocialButton(
                      label: 'Continue with Google',
                      icon: Icons.g_mobiledata_rounded,
                      onTap: onGoogleTap,
                      backgroundColor: const Color(0xFFFBFCFE),
                      borderColor: const Color(0xFFE7EDF5),
                      iconColor: const Color(0xFF4285F4),
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 12),
                    SocialButton(
                      label: 'Continue with Facebook',
                      icon: Icons.facebook_rounded,
                      onTap: onFacebookTap,
                      backgroundColor: const Color(0xFFFBFCFE),
                      borderColor: const Color(0xFFE7EDF5),
                      iconColor: const Color(0xFF1877F2),
                      isLoading: isLoading,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: SocialButton(
                      label: 'Google',
                      icon: Icons.g_mobiledata_rounded,
                      onTap: onGoogleTap,
                      backgroundColor: const Color(0xFFFBFCFE),
                      borderColor: const Color(0xFFE7EDF5),
                      iconColor: const Color(0xFF4285F4),
                      isLoading: isLoading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SocialButton(
                      label: 'Facebook',
                      icon: Icons.facebook_rounded,
                      onTap: onFacebookTap,
                      backgroundColor: const Color(0xFFFBFCFE),
                      borderColor: const Color(0xFFE7EDF5),
                      iconColor: const Color(0xFF1877F2),
                      isLoading: isLoading,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}