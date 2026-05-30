import 'package:flutter/material.dart';

import '../../data/repository/onboarding_repository_impl.dart';

import '../../domain/usecases/submit_onboarding_usecase.dart';

class OnboardingProvider
    extends ChangeNotifier {
  bool isLoading = false;

  final SubmitOnboardingUsecase
      submitUsecase =
      SubmitOnboardingUsecase(
    OnboardingRepositoryImpl(),
  );

  Future<bool> submit({
    required Map<String, dynamic>
        data,
  }) async {
    try {
      isLoading = true;

      notifyListeners();

      await submitUsecase.call(
        data: data,
      );

      isLoading = false;

      notifyListeners();

      return true;
    } catch (e) {
      isLoading = false;

      notifyListeners();

      return false;
    }
  }
}