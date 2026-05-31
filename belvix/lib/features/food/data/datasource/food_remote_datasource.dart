import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

class FoodRemoteDatasource {
  final Dio dio = DioClient.dio;

  Future<Response> list() async {
    return await dio.get("/food/list");
  }

  Future<Response> create(Map<String, dynamic> body) async {
    return await dio.post("/food/create", data: body);
  }

  Future<Response> delete(String id) async {
    return await dio.delete("/food/delete/$id");
  }
}
