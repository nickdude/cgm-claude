import 'package:dio/dio.dart';

import '../storage/storage_service.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl:
          "https://cgm-app.duckdns.org/api",

      headers: {
        "Content-Type":
            "application/json",
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (options, handler) async {
          final token =
              await StorageService
                  .getToken();

          if (token != null) {
            options.headers[
                    "Authorization"] =
                "Bearer $token";
          }

          return handler.next(
            options,
          );
        },
      ),
    );
}