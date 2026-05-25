import 'package:flutter/material.dart';

import '../../../../core/storage/storage_service.dart';

import '../../data/models/user_model.dart';

import '../../data/repository/auth_repository_impl.dart';

import '../../domain/usecases/login_usecase.dart';

import '../../domain/usecases/register_usecase.dart';

import '../../domain/usecases/forgot_password_usecase.dart';

import '../../domain/usecases/reset_password_usecase.dart';

class AuthProvider
    extends ChangeNotifier {
  bool isLoading = false;

  UserModel? currentUser;

  final LoginUsecase loginUsecase =
      LoginUsecase(
    AuthRepositoryImpl(),
  );

  final RegisterUsecase
      registerUsecase =
      RegisterUsecase(
    AuthRepositoryImpl(),
  );

  final ForgotPasswordUsecase
      forgotPasswordUsecase =
      ForgotPasswordUsecase(
    AuthRepositoryImpl(),
  );

  final ResetPasswordUsecase
      resetPasswordUsecase =
      ResetPasswordUsecase(
    AuthRepositoryImpl(),
  );

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;

      notifyListeners();

      final response =
          await loginUsecase.call(
        email: email,
        password: password,
      );

      await StorageService.setToken(
        response.token,
      );

      currentUser = response.user;

      isLoading = false;

      notifyListeners();

      return true;
    } catch (e) {
      isLoading = false;

      notifyListeners();

      print(e);

      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;

      notifyListeners();

      await registerUsecase.call(
        fullName: fullName,
        email: email,
        password: password,
      );

      isLoading = false;

      notifyListeners();

      return true;
    } catch (e) {
      isLoading = false;

      notifyListeners();

      print(e);

      return false;
    }
  }

  Future<bool> forgotPassword({
    required String email,
  }) async {
    try {
      isLoading = true;

      notifyListeners();

      await forgotPasswordUsecase.call(
        email: email,
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

  Future<bool> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      isLoading = true;

      notifyListeners();

      await resetPasswordUsecase.call(
        token: token,
        password: password,
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

  Future<void> logout() async {
    await StorageService.clear();

    currentUser = null;

    notifyListeners();
  }
}