import '../../domain/repository/onboarding_repository.dart';

import '../datasource/onboarding_remote_datasource.dart';

class OnboardingRepositoryImpl
    implements OnboardingRepository {
  final OnboardingRemoteDatasource
      remoteDatasource =
      OnboardingRemoteDatasource();

  @override
  Future<void> submitOnboarding({
    required Map<String, dynamic>
        data,
  }) async {
    await remoteDatasource
        .submitOnboarding(
      data: data,
    );
  }
}