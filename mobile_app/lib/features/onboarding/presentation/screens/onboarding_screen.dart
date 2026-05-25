import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_primary_button.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final diagnosedYearController = TextEditingController();

  int currentStep = 0;

  String gender = "Male";
  String diabetesType = "Type 1 Diabetes";
  String activityLevel = "Moderate";
  bool insulinUsage = true;

  static const int totalSteps = 8;

  @override
  void dispose() {
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    diagnosedYearController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateCurrentStep() {
    switch (currentStep) {
      case 0:
        return _parseInt(ageController.text) != null;
      case 1:
        return gender.isNotEmpty;
      case 2:
        return diabetesType.isNotEmpty;
      case 3:
        return _parseDouble(heightController.text) != null;
      case 4:
        return _parseDouble(weightController.text) != null;
      case 5:
        return true;
      case 6:
        return _parseInt(diagnosedYearController.text) != null;
      case 7:
        return activityLevel.isNotEmpty;
      default:
        return false;
    }
  }

  int? _parseInt(String value) => int.tryParse(value.trim());

  double? _parseDouble(String value) => double.tryParse(value.trim());

  Future<void> _goNext() async {
    if (!_validateCurrentStep()) {
      _showMessage(_validationMessageForStep());
      return;
    }

    if (currentStep < totalSteps - 1) {
      setState(() {
        currentStep += 1;
      });
      return;
    }

    final provider = context.read<OnboardingProvider>();

    final payload = {
      "age": _parseInt(ageController.text)!,
      "gender": gender,
      "diabetesType": diabetesType,
      "height": _parseDouble(heightController.text)!,
      "weight": _parseDouble(weightController.text)!,
      "insulinUsage": insulinUsage,
      "diagnosedYear": _parseInt(diagnosedYearController.text)!,
      "activityLevel": activityLevel,
    };

    final success = await provider.submit(data: payload);

    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    await auth.markOnboardingCompleted();

    if (!mounted) return;

    if (!success) {
      _showMessage(
        "We saved your onboarding locally and will sync again later.",
      );
    }

    final token = await StorageService.getToken();

    if (!mounted) return;

    await AppRouter.goToHome(context, token: token, user: auth.currentUser);
  }

  void _goBack() {
    if (currentStep == 0) {
      Navigator.maybePop(context);
      return;
    }

    setState(() {
      currentStep -= 1;
    });
  }

  String _validationMessageForStep() {
    switch (currentStep) {
      case 0:
        return "Please enter your age.";
      case 1:
        return "Please select your gender.";
      case 2:
        return "Please select your diabetes type.";
      case 3:
        return "Please enter your height in ft.";
      case 4:
        return "Please enter your weight in kg.";
      case 5:
        return "Please confirm your insulin usage.";
      case 6:
        return "Please enter your diagnosis year.";
      case 7:
        return "Please select your activity level.";
      default:
        return "Please complete this step.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final progress = (currentStep + 1) / totalSteps;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Column(
                    key: ValueKey(currentStep),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _goBack,
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Question ${currentStep + 1} of $totalSteps",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: const Color(0xFFE8EEF7),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        _stepTitle(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _stepSubtitle(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildStepContent(),
                      const SizedBox(height: 28),
                      AuthPrimaryButton(
                        label: currentStep == totalSteps - 1
                            ? "Finish"
                            : "Next",
                        isLoading: provider.isLoading,
                        onTap: _goNext,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _stepTitle() {
    switch (currentStep) {
      case 0:
        return "What is your age?";
      case 1:
        return "What is your gender?";
      case 2:
        return "Which type of diabetes do you have?";
      case 3:
        return "What is your height?";
      case 4:
        return "What is your weight?";
      case 5:
        return "Do you use insulin?";
      case 6:
        return "What year were you diagnosed?";
      case 7:
        return "How active are you?";
      default:
        return "Tell us about you";
    }
  }

  String _stepSubtitle() {
    switch (currentStep) {
      case 0:
        return "Enter your age in years.";
      case 1:
        return "Select the option that best describes you.";
      case 2:
        return "Choose the diabetes type you were diagnosed with.";
      case 3:
        return "Enter your height in ft.";
      case 4:
        return "Enter your weight in kg.";
      case 5:
        return "Tell us whether you currently use insulin.";
      case 6:
        return "Enter the year you were diagnosed.";
      case 7:
        return "Select the activity level that matches your routine.";
      default:
        return "";
    }
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return AuthTextField(
          controller: ageController,
          label: "Age (years)",
          hint: "Enter your age",
          prefixIcon: Icons.cake_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _goNext(),
        );
      case 1:
        return _buildChoiceGroup(
          options: const ["Male", "Female", "Other"],
          selectedValue: gender,
          onSelected: (value) {
            setState(() {
              gender = value;
            });
          },
        );
      case 2:
        return _buildChoiceGroup(
          options: const [
            "Type 1 Diabetes",
            "Type 2 Diabetes",
            "Gestational Diabetes",
            "Special Diabetes",
            "Other",
          ],
          selectedValue: diabetesType,
          onSelected: (value) {
            setState(() {
              diabetesType = value;
            });
          },
        );
      case 3:
        return AuthTextField(
          controller: heightController,
          label: "Height (ft)",
          hint: "Enter your height in ft",
          prefixIcon: Icons.height_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _goNext(),
        );
      case 4:
        return AuthTextField(
          controller: weightController,
          label: "Weight (kg)",
          hint: "Enter your weight in kg",
          prefixIcon: Icons.monitor_weight_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _goNext(),
        );
      case 5:
        return Column(
          children: [
            _buildToggleCard(
              title: "Yes, I use insulin",
              isSelected: insulinUsage,
              onTap: () {
                setState(() {
                  insulinUsage = true;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildToggleCard(
              title: "No, I do not use insulin",
              isSelected: !insulinUsage,
              onTap: () {
                setState(() {
                  insulinUsage = false;
                });
              },
            ),
          ],
        );
      case 6:
        return AuthTextField(
          controller: diagnosedYearController,
          label: "Diagnosed year",
          hint: "Enter the year",
          prefixIcon: Icons.calendar_month_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _goNext(),
        );
      case 7:
        return _buildChoiceGroup(
          options: const ["Low", "Moderate", "High"],
          selectedValue: activityLevel,
          onSelected: (value) {
            setState(() {
              activityLevel = value;
            });
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChoiceGroup({
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      children: options
          .map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildChoiceTile(
                title: option,
                isSelected: selectedValue == option,
                onTap: () => onSelected(option),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildChoiceTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF2FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF2FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
