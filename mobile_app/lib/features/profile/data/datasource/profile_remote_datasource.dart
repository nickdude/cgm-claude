import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

import '../../../../core/storage/storage_service.dart';

class ProfileRemoteDatasource {
  final Dio dio = DioClient.dio;

  Future<Response> getProfile() async {
    final token =
        await StorageService.getToken();

    return await dio.get(
      "/profile/me",

      options: Options(
        headers: {
          "Authorization":
              "Bearer $token",
        },
      ),
    );
  }

  Future<Response> updateProfile({
    required String fullName,
    required String profileImage,
  }) async {
    final token =
        await StorageService.getToken();

    return await dio.put(
      "/profile/update",

      data: {
        "fullName": fullName,
        "profileImage":
            profileImage,
      },

      options: Options(
        headers: {
          "Authorization":
              "Bearer $token",
        },
      ),
    );
  }
}