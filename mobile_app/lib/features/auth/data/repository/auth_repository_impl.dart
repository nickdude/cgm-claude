import '../../domain/repository/auth_repository.dart';

import '../datasource/auth_remote_datasource.dart';

import '../models/login_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource = AuthRemoteDatasource();

  @override
  Future<LoginModel> login({
    required String email,
    required String password,
  }) async {
    final response = await remoteDatasource.login(
      email: email,
      password: password,
    );

    return LoginModel.fromJson(response.data["data"]);
  }

  @override
  Future<void> register({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    await remoteDatasource.register(
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      password: password,
    );
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await remoteDatasource.forgotPassword(email: email);
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await remoteDatasource.resetPassword(token: token, password: password);
  }
}
