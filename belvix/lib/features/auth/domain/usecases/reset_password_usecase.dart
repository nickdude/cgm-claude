import '../repository/auth_repository.dart';

class ResetPasswordUsecase {
  final AuthRepository repository;

  ResetPasswordUsecase(
    this.repository,
  );

  Future<void> call({
    required String token,
    required String password,
  }) async {
    await repository.resetPassword(
      token: token,
      password: password,
    );
  }
}