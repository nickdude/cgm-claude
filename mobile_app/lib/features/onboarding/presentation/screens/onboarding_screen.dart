import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../app/router/app_router.dart';

import '../../../../core/storage/storage_service.dart';

import '../../../../core/widgets/custom_textfield.dart';

import '../../../../core/widgets/primary_button.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

import '../providers/onboarding_provider.dart';

class OnboardingScreen
    extends StatefulWidget {
  const OnboardingScreen({
    super.key,
  });

  @override
  State<OnboardingScreen>
      createState() =>
          _OnboardingScreenState();
}

class _OnboardingScreenState
    extends State<OnboardingScreen> {
  final ageController =
      TextEditingController();

  final heightController =
      TextEditingController();

  final weightController =
      TextEditingController();

  final diagnosedYearController =
      TextEditingController();

  String gender = "Male";

  String diabetesType = "Type 1";

  String activityLevel = "Moderate";

  bool insulinUsage = true;

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<
            OnboardingProvider>();

    return Scaffold(
      appBar: AppBar(),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              "Tell Us About You",

              style: TextStyle(
                fontSize: 32,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Personalize your CGM insights",
            ),

            const SizedBox(height: 40),

            CustomTextField(
              controller:
                  ageController,

              hint: "Age",

              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField(
              value: gender,

              items: const [
                DropdownMenuItem(
                  value: "Male",
                  child: Text("Male"),
                ),

                DropdownMenuItem(
                  value: "Female",
                  child: Text("Female"),
                ),
              ],

              onChanged: (value) {
                gender = value!;
              },
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField(
              value: diabetesType,

              items: const [
                DropdownMenuItem(
                  value: "Type 1",
                  child:
                      Text("Type 1"),
                ),

                DropdownMenuItem(
                  value: "Type 2",
                  child:
                      Text("Type 2"),
                ),
              ],

              onChanged: (value) {
                diabetesType = value!;
              },
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller:
                  heightController,

              hint: "Height",

              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller:
                  weightController,

              hint: "Weight",

              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 20),

            SwitchListTile(
              value: insulinUsage,

              title: const Text(
                "Using Insulin?",
              ),

              onChanged: (value) {
                setState(() {
                  insulinUsage =
                      value;
                });
              },
            ),

            const SizedBox(height: 20),

            CustomTextField(
              controller:
                  diagnosedYearController,

              hint:
                  "Diagnosed Year",

              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField(
              value: activityLevel,

              items: const [
                DropdownMenuItem(
                  value: "Low",
                  child: Text("Low"),
                ),

                DropdownMenuItem(
                  value: "Moderate",
                  child:
                      Text("Moderate"),
                ),

                DropdownMenuItem(
                  value: "High",
                  child:
                      Text("High"),
                ),
              ],

              onChanged: (value) {
                activityLevel =
                    value!;
              },
            ),

            const SizedBox(height: 40),

            PrimaryButton(
              title: "Continue",

              isLoading:
                  provider.isLoading,

              onTap: () async {
                final age = int.tryParse(
                  ageController.text
                      .trim(),
                );

                final height = double
                    .tryParse(
                  heightController.text
                      .trim(),
                );

                final weight = double
                    .tryParse(
                  weightController.text
                      .trim(),
                );

                final diagnosedYear = int
                    .tryParse(
                  diagnosedYearController
                      .text
                      .trim(),
                );

                if (age == null ||
                    height == null ||
                    weight == null ||
                    diagnosedYear ==
                        null) {
                  ScaffoldMessenger
                          .of(
                            context,
                          )
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please fill all numeric fields",
                      ),
                    ),
                  );

                  return;
                }

                final success =
                    await provider
                        .submit(
                  data: {
                    "age": age,
                    "gender": gender,
                    "diabetesType":
                        diabetesType,
                    "height": height,
                    "weight": weight,
                    "insulinUsage":
                        insulinUsage,
                    "diagnosedYear":
                        diagnosedYear,
                    "activityLevel":
                        activityLevel,
                  },
                );

                if (!mounted) return;

                final auth =
                    context.read<
                        AuthProvider>();

                if (success) {
                  await auth
                      .markOnboardingCompleted();
                } else {
                  // Even if the API call fails, locally mark
                  // onboarding done so the user can proceed.
                  // Backend will reconcile on next session refresh.
                  await auth
                      .markOnboardingCompleted();
                }

                if (!mounted) return;

                final token =
                    await StorageService
                        .getToken();

                if (!mounted) return;

                await AppRouter.goToHome(
                  context,
                  token: token,
                  user:
                      auth.currentUser,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}