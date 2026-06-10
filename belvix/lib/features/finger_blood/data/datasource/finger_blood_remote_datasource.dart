import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

class FingerBloodRemoteDatasource {
  final Dio dio = DioClient.dio;

  Future<Response> list() async {
    return await dio.get("/finger-blood/list");
  }

  Future<Response> create(Map<String, dynamic> body) async {
    return await dio.post("/finger-blood/create", data: body);
  }

  Future<Response> update(String id, Map<String, dynamic> body) async {
    return await dio.put("/finger-blood/$id", data: body);
  }

  Future<Response> delete(String id) async {
    return await dio.delete("/finger-blood/delete/$id");
  }
}
