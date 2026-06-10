import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

import '../widgets/auth_footer_link.dart';

import '../widgets/auth_primary_button.dart';

import '../widgets/auth_scaffold.dart';

import '../widgets/auth_text_field.dart';

import '../widgets/social_button.dart';

import '../helpers/social_auth_actions.dart';

import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final fullNameController = TextEditingController();

  final phoneNumberController = TextEditingController();

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  // Inline, field-level validation messages. Null = no error for that field.
  String? _fullNameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    fullNameController.dispose();

    phoneNumberController.dispose();

    emailController.dispose();

    passwordController.dispose();

    super.dispose();
  }

  /// Validates every field and populates the inline error messages.
  /// Returns true only when the whole form is valid.
  bool _validate({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) {
    String? fullNameError;
    String? phoneError;
    String? emailError;
    String? passwordError;

    if (fullName.isEmpty) {
      fullNameError = "Please enter your full name";
    }

    if (phone.isEmpty) {
      phoneError = "Please enter your phone number";
    } else if (phone.replaceAll(RegExp(r'[^0-9]'), '').length < 7) {
      phoneError = "Please enter a valid phone number";
    }

    if (email.isEmpty) {
      emailError = "Please enter your email";
    } else if (!_isValidEmail(email)) {
      emailError = "Please enter a valid email address";
    }

    if (password.isEmpty) {
      passwordError = "Please enter a password";
    } else if (password.length < 8) {
      passwordError = "Password must be at least 8 characters";
    }

    setState(() {
      _fullNameError = fullNameError;
      _phoneError = phoneError;
      _emailError = emailError;
      _passwordError = passwordError;
    });

    return fullNameError == null &&
        phoneError == null &&
        emailError == null &&
        passwordError == null;
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    return regex.hasMatch(email);
  }

  // Business logic / API integration preserved; only validation, error
  // handling and submission-guarding were added around it.
  Future<void> _handleRegister() async {
    final authProvider = context.read<AuthProvider>();

    // Prevent multiple submissions while a request is already in flight.
    if (authProvider.isLoading) return;

    final fullName = fullNameController.text.trim();

    final phone = phoneNumberController.text.trim();

    final email = emailController.text.trim();

    final password = passwordController.text.trim();

    // Block API submission until the form is valid; errors render inline.
    if (!_validate(
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
    )) {
      return;
    }

    final success = await authProvider.register(
      fullName: fullName,
      phoneNumber: phone,
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification email sent")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
      );
    } else {
      // Surface the backend message ("Email already exists", etc.) in the
      // same SnackBar style the login screen uses for auth failures.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ??
                "Registration failed. Please try again.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AuthScaffold(
      title: "Create your account",
      subtitle: "Start monitoring your glucose smarter.",
      showBackButton: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthTextField(
            controller: fullNameController,
            label: "Full name",
            hint: "Jane Doe",
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.name,
            errorText: _fullNameError,
            onChanged: (_) {
              if (_fullNameError != null) {
                setState(() => _fullNameError = null);
              }
            },
          ),

          const SizedBox(height: 16),

          AuthTextField(
            controller: phoneNumberController,
            label: "Phone number",
            hint: "+1 555 123 4567",
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            errorText: _phoneError,
            onChanged: (_) {
              if (_phoneError != null) {
                setState(() => _phoneError = null);
              }
            },
          ),

          const SizedBox(height: 16),

          AuthTextField(
            controller: emailController,
            label: "Email",
            hint: "you@example.com",
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
            onChanged: (_) {
              if (_emailError != null) {
                setState(() => _emailError = null);
              }
            },
          ),

          const SizedBox(height: 16),

          AuthTextField(
            controller: passwordController,
            label: "Password",
            hint: "At least 8 characters",
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleRegister(),
            errorText: _passwordError,
            onChanged: (_) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
          ),

          const SizedBox(height: 24),

          AuthPrimaryButton(
            label: "Register",
            isLoading: authProvider.isLoading,
            onTap: _handleRegister,
          ),

          const SizedBox(height: 24),

          SocialAuthButtons(
            isLoading: authProvider.isLoading,
            onGoogleTap: () => handleGoogleSocialLogin(
              context,
              successMessage: 'Account ready!',
            ),
            onFacebookTap: () => handleFacebookSocialLogin(
              context,
              successMessage: 'Account ready!',
            ),
          ),

          const SizedBox(height: 24),

          AuthFooterLink(
            prefix: "Already have an account?",
            actionText: "Login",
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
