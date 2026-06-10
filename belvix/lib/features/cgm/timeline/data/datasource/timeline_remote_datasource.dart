import 'package:dio/dio.dart';

import '../../../../../core/network/dio_client.dart';

class TimelineRemoteDatasource {
  final Dio dio = DioClient.dio;

  /// GET /timeline/events?from=<ISO>&to=<ISO>
  Future<Response> events({
    required DateTime from,
    required DateTime to,
  }) async {
    return await dio.get(
      "/timeline/events",
      queryParameters: {
        "from": from.toUtc().toIso8601String(),
        "to": to.toUtc().toIso8601String(),
      },
    );
  }
}
