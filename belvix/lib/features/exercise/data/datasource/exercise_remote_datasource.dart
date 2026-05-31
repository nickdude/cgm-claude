import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

class ExerciseRemoteDatasource {
  final Dio dio = DioClient.dio;

  Future<Response> list() async {
    return await dio.get("/exercise/list");
  }

  Future<Response> create(Map<String, dynamic> body) async {
    return await dio.post("/exercise/create", data: body);
  }

  Future<Response> delete(String id) async {
    return await dio.delete("/exercise/delete/$id");
  }
}
