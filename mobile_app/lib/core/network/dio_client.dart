import 'package:dio/dio.dart';

import '../storage/storage_service.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl:
          // "http://192.168.1.6:5001/api",
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