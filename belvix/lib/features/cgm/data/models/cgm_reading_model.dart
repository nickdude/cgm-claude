class CgmReadingModel {
  final String? id;

  final String? deviceId;

  /// Glucose value in mg/dL.
  final double glucoseValue;

  final String trend;

  final DateTime readingAt;

  /// Sensor serial number this reading came from. Paired with
  /// [sequenceNumber] it forms the sensor's native, reconnect-stable id used
  /// for idempotent backfill. Null for readings not sourced from the SDK.
  final String? sensorSerial;

  /// The sensor's own monotonic record id for this reading (SDK `timeOffset`,
  /// 1-based). The canonical dedup key — immune to timestamp collapse.
  final int? sequenceNumber;

  CgmReadingModel({
    this.id,
    this.deviceId,
    required this.glucoseValue,
    required this.trend,
    required this.readingAt,
    this.sensorSerial,
    this.sequenceNumber,
  });

  factory CgmReadingModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw =
        json["readingAt"] ??
            json["createdAt"];

    final parsed = raw is String
        ? DateTime.tryParse(raw) ??
            DateTime.now()
        : DateTime.now();

    return CgmReadingModel(
      id: (json["_id"] ??
              json["id"])
          ?.toString(),
      deviceId: json["deviceId"]
          ?.toString(),
      glucoseValue:
          (json["glucoseValue"] as num? ??
                  0)
              .toDouble(),
      trend: (json["trend"] ?? "Stable")
          .toString(),
      readingAt: parsed,
      sensorSerial:
          json["sensorSerial"]?.toString(),
      sequenceNumber:
          (json["sequenceNumber"] as num?)
              ?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "glucoseValue": glucoseValue,
      "trend": trend,
      "readingAt":
          readingAt.toIso8601String(),
      if (sensorSerial != null)
        "sensorSerial": sensorSerial,
      if (sequenceNumber != null)
        "sequenceNumber": sequenceNumber,
    };
  }
}
