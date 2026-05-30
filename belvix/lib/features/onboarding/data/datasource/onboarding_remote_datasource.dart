import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

import '../../../../core/storage/storage_service.dart';

class OnboardingRemoteDatasource {
  final Dio dio = DioClient.dio;

  Future<Response> submitOnboarding({
    required Map<String, dynamic>
        data,
  }) async {
    final token =
        await StorageService.getToken();

    return await dio.post(
      "/onboarding/submit",

      data: data,

      options: Options(
        headers: {
          "Authorization":
              "Bearer $token",
        },
      ),
    );
  }
}