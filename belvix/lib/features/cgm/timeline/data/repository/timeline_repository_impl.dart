import 'package:flutter/foundation.dart';

import '../datasource/timeline_remote_datasource.dart';
import '../models/timeline_event.dart';

class TimelineRepository {
  final TimelineRemoteDatasource _datasource =
      TimelineRemoteDatasource();

  Future<List<TimelineEvent>> events({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final res = await _datasource.events(from: from, to: to);
      final raw = res.data?["data"];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((m) => TimelineEvent.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint("Timeline events fetch failed: $e");
      return const [];
    }
  }
}
