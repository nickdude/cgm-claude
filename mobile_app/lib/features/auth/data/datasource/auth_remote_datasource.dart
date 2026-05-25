import 'package:dio/dio.dart';

import '../../../../../core/network/dio_client.dart';

class AuthRemoteDatasource {
  final Dio dio = DioClient.dio;

  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return await dio.post(
      "/auth/login",

      data: {"email": email, "password": password},
    );
  }

  Future<Response> register({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    return await dio.post(
      "/auth/register",

      data: {
        "fullName": fullName,
        "phoneNumber": phoneNumber,
        "email": email,
        "password": password,
      },
    );
  }

  Future<Response> forgotPassword({required String email}) async {
    return await dio.post("/auth/forgot-password", data: {"email": email});
  }

  Future<Response> resetPassword({
    required String token,
    required String password,
  }) async {
    return await dio.post(
      "/auth/reset-password/$token",

      data: {"password": password},
    );
  }
}
