import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

import '../../../../core/storage/storage_service.dart';

class ProfileRemoteDatasource {
  final Dio dio = DioClient.dio;

  Future<String> uploadProfileImage({
    required List<int> bytes,
    required String filename,
  }) async {
    final token = await StorageService.getToken();

    // fromBytes works on web and mobile; MultipartFile.fromFile (dart:io)
    // throws on web.
    final formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(bytes, filename: filename),
    });

    final response = await dio.post(
      "/upload/single",
      data: formData,
      // Don't set Content-Type manually — dio adds the correct
      // `multipart/form-data; boundary=...` for FormData. A manual value
      // without a boundary breaks server-side multipart parsing.
      options: Options(
        headers: {"Authorization": "Bearer $token"},
      ),
    );

    // Server returns { data: { path: "/uploads/..", url: "http://.." } }.
    // Prefer the relative path (resolved to https on display); fall back
    // to url so we never silently persist an empty image.
    final data = response.data["data"];

    return (data?["path"] ?? data?["url"] ?? "").toString();
  }

  Future<Response> getProfile() async {
    final token = await StorageService.getToken();

    return await dio.get(
      "/profile/me",

      options: Options(headers: {"Authorization": "Bearer $token"}),
    );
  }

  Future<Response> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String profileImage,
  }) async {
    final token = await StorageService.getToken();

    return await dio.put(
      "/profile/update",

      data: {
        "fullName": fullName,
        "phoneNumber": phoneNumber,
        "profileImage": profileImage,
      },

      options: Options(headers: {"Authorization": "Bearer $token"}),
    );
  }
}
