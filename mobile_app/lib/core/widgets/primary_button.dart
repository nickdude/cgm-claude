import 'package:flutter/material.dart';

class PrimaryButton
    extends StatelessWidget {
  final String title;

  final VoidCallback onTap;

  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.title,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed:
          isLoading ? null : onTap,

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