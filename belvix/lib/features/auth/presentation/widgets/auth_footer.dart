import 'package:flutter/material.dart';

class AuthFooter
    extends StatelessWidget {
  final String title;

  final String actionText;

  final VoidCallback onTap;

  const AuthFooter({
    super.key,
    required this.title,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,

      children: [
        Text(title),

        TextButton(
          onPressed: onTap,

          child: Text(actionText),
        ),
      ],
    );
  }
}