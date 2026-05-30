import '../repository/auth_repository.dart';

class RegisterUsecase {
  final AuthRepository repository;

  RegisterUsecase(this.repository);

  Future<void> call({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    await repository.register(
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      password: password,
    );
  }
}
