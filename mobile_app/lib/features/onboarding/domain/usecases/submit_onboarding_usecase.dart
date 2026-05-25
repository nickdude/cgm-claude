import '../repository/onboarding_repository.dart';

class SubmitOnboardingUsecase {
  final OnboardingRepository
      repository;

  SubmitOnboardingUsecase(
    this.repository,
  );

  Future<void> call({
    required Map<String, dynamic>
        data,
  }) async {
    await repository.submitOnboarding(
      data: data,
    );
  }
}