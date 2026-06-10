import 'package:flutter/foundation.dart';

import '../../data/models/timeline_event.dart';
import '../../data/repository/timeline_repository_impl.dart';

/// Owns the unified timeline-event cache and lazily fetches additional ranges
/// as the chart scrolls.
///
/// Caching model: a single **contiguous loaded interval** `[_loadedFrom,
/// _loadedTo]`. When the chart asks for a visible range, the request is padded
/// to whole days (prefetching neighbours) and only the missing extension(s)
/// are fetched — already-loaded ranges are never refetched. Events are kept in
/// an id-keyed map for O(1) dedup and exposed as one ascending list.
class TimelineProvider extends ChangeNotifier {
  final TimelineRepository _repository = TimelineRepository();

  /// id → event, for cheap de-duplication across overlapping fetches.
  final Map<String, TimelineEvent> _byId = {};

  /// Ascending-by-timestamp snapshot used by the chart.
  List<TimelineEvent> events = const [];

  /// The contiguous interval currently cached (null until the first fetch).
  DateTime? _loadedFrom;
  DateTime? _loadedTo;

  bool isLoading = false;

  /// Range keys currently being fetched, so concurrent scrolls don't issue
  /// duplicate API calls for the same window.
  final Set<String> _inFlight = {};

  DateTime _dayFloor(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _dayCeil(DateTime d) =>
      DateTime(d.year, d.month, d.day).add(const Duration(days: 1));

  String _key(DateTime a, DateTime b) =>
      '${a.toIso8601String()}_${b.toIso8601String()}';

  /// Ensures the cache covers [from, to]. Pads ±1 day (snapped to midnight) to
  /// prefetch neighbours and absorb timezone offsets, then fetches only the
  /// portions not already loaded. Safe to call repeatedly while scrolling.
  Future<void> ensureRange(DateTime from, DateTime to) async {
    final reqFrom = _dayFloor(from.subtract(const Duration(days: 1)));
    final reqTo = _dayCeil(to.add(const Duration(days: 1)));

    // Determine the missing sub-ranges relative to the loaded interval.
    final segments = <List<DateTime>>[];
    if (_loadedFrom == null || _loadedTo == null) {
      segments.add([reqFrom, reqTo]);
    } else {
      if (reqFrom.isBefore(_loadedFrom!)) {
        segments.add([reqFrom, _loadedFrom!]);
      }
      if (reqTo.isAfter(_loadedTo!)) {
        segments.add([_loadedTo!, reqTo]);
      }
    }

    if (segments.isEmpty) return; // fully cached — no API call

    var changed = false;
    isLoading = true;
    notifyListeners();

    for (final seg in segments) {
      final key = _key(seg[0], seg[1]);
      if (_inFlight.contains(key)) continue;
      _inFlight.add(key);

      try {
        final fetched =
            await _repository.events(from: seg[0], to: seg[1]);
        for (final e in fetched) {
          _byId[e.id] = e;
        }
        if (fetched.isNotEmpty) changed = true;

        // Grow the contiguous loaded interval to include this segment.
        _loadedFrom = _loadedFrom == null
            ? reqFrom
            : (reqFrom.isBefore(_loadedFrom!) ? reqFrom : _loadedFrom!);
        _loadedTo = _loadedTo == null
            ? reqTo
            : (reqTo.isAfter(_loadedTo!) ? reqTo : _loadedTo!);
      } finally {
        _inFlight.remove(key);
      }
    }

    if (changed) _rebuild();

    isLoading = false;
    notifyListeners();
  }

  /// Drops the cache and reloads — used by pull-to-refresh.
  Future<void> reload(DateTime from, DateTime to) async {
    _byId.clear();
    _loadedFrom = null;
    _loadedTo = null;
    events = const [];
    await ensureRange(from, to);
  }

  void _rebuild() {
    events = _byId.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
}
