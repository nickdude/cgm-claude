import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

class InsulinRemoteDatasource {
  final Dio dio = DioClient.dio;

  Future<Response> list() async {
    return await dio.get("/insulin/list");
  }

  Future<Response> create(Map<String, dynamic> body) async {
    return await dio.post("/insulin/create", data: body);
  }

  Future<Response> update(String id, Map<String, dynamic> body) async {
    return await dio.put("/insulin/$id", data: body);
  }

  Future<Response> delete(String id) async {
    return await dio.delete("/insulin/delete/$id");
  }
}
