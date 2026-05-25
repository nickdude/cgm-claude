import 'package:flutter/services.dart';

class CgmEventChannel {
  static const EventChannel
      _eventChannel = EventChannel(
    'cgm_sdk/events',
  );

  static Stream<dynamic>
      get events =>
          _eventChannel
              .receiveBroadcastStream();
}