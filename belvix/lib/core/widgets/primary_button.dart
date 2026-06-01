import 'package:flutter/material.dart';

class PrimaryButton
    extends StatelessWidget {
  final String title;

  final VoidCallback onTap;

  final bool isLoading;

  /// Optional overrides; when null the widget falls back to the theme
  /// (so existing usages are unchanged).
  final Color? backgroundColor;

  final Color? foregroundColor;

  const PrimaryButton({
    super.key,
    required this.title,
    required this.onTap,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed:
          isLoading ? null : onTap,
      style:
          (backgroundColor != null ||
              foregroundColor != null)
          ? ElevatedButton.styleFrom(
              backgroundColor:
                  backgroundColor,
              foregroundColor:
                  foregroundColor,
            )
          : null,

      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
    );
  }
}