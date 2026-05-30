import 'package:flutter/material.dart';

class CustomTextField
    extends StatelessWidget {
  final TextEditingController
      controller;

  final String hint;

  final bool obscureText;

  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType =
        TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,

      obscureText: obscureText,

      keyboardType: keyboardType,

      decoration: InputDecoration(
        hintText: hint,
      ),
    );
  }
}