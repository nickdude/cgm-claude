import '../../data/models/login_model.dart';

abstract class AuthRepository {
  Future<LoginModel> login({required String email, required String password});

  Future<LoginModel> loginWithGoogle({required String idToken});

  Future<LoginModel> loginWithFacebook({required String accessToken});

  Future<void> register({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
  });

  Future<void> forgotPassword({required String email});

  Future<void> resetPassword({required String token, required String password});
}
