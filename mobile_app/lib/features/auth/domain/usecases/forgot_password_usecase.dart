import '../repository/auth_repository.dart';

class ForgotPasswordUsecase {
  final AuthRepository repository;

  ForgotPasswordUsecase(
    this.repository,
  );

  Future<void> call({
    required String email,
  }) async {
    await repository.forgotPassword(
      email: email,
    );
  }
}