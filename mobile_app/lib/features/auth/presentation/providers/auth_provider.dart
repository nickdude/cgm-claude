import 'package:flutter/material.dart';

import '../../../../core/storage/storage_service.dart';

import '../../data/models/user_model.dart';

import '../../data/repository/auth_repository_impl.dart';

import '../../domain/usecases/login_usecase.dart';

import '../../domain/usecases/register_usecase.dart';

import '../../domain/usecases/forgot_password_usecase.dart';

import '../../domain/usecases/reset_password_usecase.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoading = false;

  UserModel? currentUser;

  final LoginUsecase loginUsecase = LoginUsecase(AuthRepositoryImpl());

  final RegisterUsecase registerUsecase = RegisterUsecase(AuthRepositoryImpl());

  final ForgotPasswordUsecase forgotPasswordUsecase = ForgotPasswordUsecase(
    AuthRepositoryImpl(),
  );

  final ResetPasswordUsecase resetPasswordUsecase = ResetPasswordUsecase(
    AuthRepositoryImpl(),
  );

  Future<bool> login({required String email, required String password}) async {
    try {
      isLoading = true;

      notifyListeners();

      final response = await loginUsecase.call(
        email: email,
        password: password,
      );

      await StorageService.setToken(response.token);

      await _persistUser(response.user);

      currentUser = response.user;

      isLoading = false;

      notifyListeners();

      return true;
    } catch (e) {
      isLoading = false;

      notifyListeners();

      debugPrint("Login failed: $e");

      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;

      notifyListeners();

      await registerUsecase.call(
        fullName: fullName,
        phoneNumber: phoneNumber,
        email: email,
        password: password,
      );

      isLoading = false;

      notifyListeners();

      return true;
    } catch (e) {
      isLoading = false;

      notifyListeners();

      debugPrint("Register failed: $e");

      return false;
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    try {
      isLoading = true;

      notifyListeners();

      await forgotPasswordUsecase.call(email: email);

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

      await resetPasswordUsecase.call(token: token, password: password);

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

  Future<void> loadCachedSession() async {
    final cached = await StorageService.getUser();

    if (cached != null) {
      try {
        currentUser = UserModel.fromJson(cached);
      } catch (_) {
        currentUser = null;
      }
    }

    final profile = await StorageService.isProfileCompleted();

    final onboarding = await StorageService.isOnboardingCompleted();

    final cgm = await StorageService.isCgmConnected();

    if (currentUser != null) {
      currentUser = currentUser!.copyWith(
        isProfileCompleted: profile || currentUser!.isProfileCompleted,
        isOnboardingCompleted: onboarding || currentUser!.isOnboardingCompleted,
        isCgmConnected: cgm || currentUser!.isCgmConnected,
      );
    }
  }

  Future<void> markProfileCompleted() async {
    await StorageService.setProfileCompleted(true);

    if (currentUser != null) {
      currentUser = currentUser!.copyWith(isProfileCompleted: true);

      await _persistUser(currentUser!);

      notifyListeners();
    }
  }

  Future<void> updateProfileLocal({
    required String fullName,
    required String phoneNumber,
    String? profileImage,
  }) async {
    if (currentUser == null) return;

    currentUser = currentUser!.copyWith(
      fullName: fullName,
      phoneNumber: phoneNumber,
      profileImage: profileImage,
      isProfileCompleted: true,
    );

    await _persistUser(currentUser!);

    notifyListeners();
  }

  Future<void> markOnboardingCompleted() async {
    await StorageService.setOnboardingCompleted(true);

    if (currentUser != null) {
      currentUser = currentUser!.copyWith(isOnboardingCompleted: true);

      await _persistUser(currentUser!);

      notifyListeners();
    }
  }

  Future<void> markCgmConnected() async {
    await StorageService.setCgmConnected(true);

    if (currentUser != null) {
      currentUser = currentUser!.copyWith(isCgmConnected: true);

      await _persistUser(currentUser!);

      notifyListeners();
    }
  }

  Future<void> _persistUser(UserModel user) async {
    await StorageService.setUser(user.toJson());

    await StorageService.setProfileCompleted(user.isProfileCompleted);

    await StorageService.setOnboardingCompleted(user.isOnboardingCompleted);

    await StorageService.setCgmConnected(user.isCgmConnected);
  }
}
