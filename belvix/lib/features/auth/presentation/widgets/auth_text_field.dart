import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Modern auth field: subtle light-grey fill, soft rounded corners,
/// optional leading icon, and a built-in show/hide eye for passwords.
class AuthTextField
    extends StatefulWidget {
  final TextEditingController controller;

  final String label;

  final String hint;

  final IconData? prefixIcon;

  final bool obscureText;

  final TextInputType keyboardType;

  final TextInputAction
      textInputAction;

  final void Function(String)?
      onSubmitted;

  /// Fired on every keystroke. Used by callers to clear a field-level
  /// validation error as soon as the user edits the field.
  final void Function(String)?
      onChanged;

  /// Inline validation message shown beneath the field. When non-null the
  /// field also switches to an error (red) border. Null = no error (default).
  final String? errorText;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType =
        TextInputType.text,
    this.textInputAction =
        TextInputAction.next,
    this.onSubmitted,
    this.onChanged,
    this.errorText,
  });

  @override
  State<AuthTextField> createState() =>
      _AuthTextFieldState();
}

class _AuthTextFieldState
    extends State<AuthTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();

    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final hasError =
        widget.errorText != null;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
            color: AppColors
                .textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller:
              widget.controller,
          obscureText: _obscured,
          keyboardType:
              widget.keyboardType,
          textInputAction:
              widget.textInputAction,
          onSubmitted:
              widget.onSubmitted,
          onChanged:
              widget.onChanged,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors
                .textPrimary,
          ),
          decoration:
              InputDecoration(
            isDense: true,
            filled: true,
            fillColor:
                const Color(
              0xFFF6F7F9,
            ),
            hintText: widget.hint,
            hintStyle:
                const TextStyle(
              color: AppColors
                  .textSecondary,
              fontSize: 14,
            ),
            prefixIcon:
                widget.prefixIcon ==
                        null
                    ? null
                    : Icon(
                        widget
                            .prefixIcon,
                        color: AppColors
                            .textSecondary,
                        size: 20,
                      ),
            suffixIcon: widget
                    .obscureText
                ? IconButton(
                    icon: Icon(
                      _obscured
                          ? Icons
                              .visibility_outlined
                          : Icons
                              .visibility_off_outlined,
                      color: AppColors
                          .textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscured =
                            !_obscured;
                      });
                    },
                  )
                : null,
            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: _buildBorder(
              color: hasError
                  ? AppColors.danger
                  : const Color(
                      0xFFE6E8EC,
                    ),
            ),
            enabledBorder:
                _buildBorder(
              color: hasError
                  ? AppColors.danger
                  : const Color(
                      0xFFE6E8EC,
                    ),
            ),
            focusedBorder:
                _buildBorder(
              color: hasError
                  ? AppColors.danger
                  : AppColors.primary,
              width: 1.4,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: const TextStyle(
              color:
                  AppColors.danger,
              fontSize: 12,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _buildBorder({
    Color color = const Color(
      0xFFE6E8EC,
    ),
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(14),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }
}
