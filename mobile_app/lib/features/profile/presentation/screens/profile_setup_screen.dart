import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../app/router/app_router.dart';

import '../../../../core/storage/storage_service.dart';

import '../../../../core/widgets/custom_textfield.dart';

import '../../../../core/widgets/primary_button.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileSetupScreen
    extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
  });

  @override
  State<ProfileSetupScreen>
      createState() =>
          _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends State<ProfileSetupScreen> {
  final fullNameController =
      TextEditingController();

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final auth = context.read<
        AuthProvider>();

    if (auth.currentUser != null &&
        auth.currentUser!.fullName
            .isNotEmpty) {
      fullNameController.text =
          auth.currentUser!.fullName;
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();

    super.dispose();
  }

  Future<void> _continue() async {
    if (fullNameController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter your name",
          ),
        ),
      );

      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final auth = context.read<
        AuthProvider>();

    await auth
        .markProfileCompleted();

    if (!mounted) return;

    final token = await StorageService
        .getToken();

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    await AppRouter.goToHome(
      context,
      token: token,
      user: auth.currentUser,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 20),

            const Text(
              "Complete Your Profile",
              style: TextStyle(
                fontSize: 32,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Let's personalize your CGM experience",
            ),

            const SizedBox(height: 40),

            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 55,
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding:
                          const EdgeInsets
                              .all(8),
                      decoration:
                          const BoxDecoration(
                        color:
                            Colors.blue,
                        shape: BoxShape
                            .circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color:
                            Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            CustomTextField(
              controller:
                  fullNameController,
              hint: "Full Name",
            ),

            const SizedBox(height: 30),

            PrimaryButton(
              title: "Continue",
              isLoading:
                  isSubmitting,
              onTap: _continue,
            ),
          ],
        ),
      ),
    );
  }
}
