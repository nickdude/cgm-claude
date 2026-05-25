import 'package:flutter/material.dart';

import '../../../../core/widgets/custom_textfield.dart';

import '../../../../core/widgets/primary_button.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),

      body: Padding(
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
                          const EdgeInsets.all(
                        8,
                      ),

                      decoration:
                          const BoxDecoration(
                        color: Colors.blue,

                        shape:
                            BoxShape.circle,
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

              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}