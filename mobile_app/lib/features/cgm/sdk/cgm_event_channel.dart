import 'dart:async';

import 'package:flutter/services.dart';

class CgmEventChannel {
  static const EventChannel _eventChannel =
      EventChannel("cgm_sdk/events");

  static Stream<Map<String, dynamic>>?
      _stream;

  /// Broadcast stream of normalised CGM SDK events.
  ///
  /// Each event is a Map with at least a `type` key.
  static Stream<Map<String, dynamic>>
      get events {
    return _stream ??= _eventChannel
        .receiveBroadcastStream()
        .map(_normalise)
        .asBroadcastStream();
  }

  static Map<String, dynamic>
      _normalise(dynamic raw) {
    if (raw is Map) {
      return raw.map(
        (k, v) => MapEntry(
          k.toString(),
          _deepNormalise(v),
        ),
      );
    }

    return {
      "type": "unknown",
      "raw": raw?.toString() ?? "null",
    };
  }

  static dynamic _deepNormalise(
    dynamic v,
  ) {
    if (v is Map) {
      return v.map(
        (k, val) => MapEntry(
          k.toString(),
          _deepNormalise(val),
        ),
      );
    }

    if (v is List) {
      return v
          .map(_deepNormalise)
          .toList();
    }

    return v;
  }
}
