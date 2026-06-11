import '../../../../exercise/data/models/exercise_model.dart';
import '../../../../finger_blood/data/models/finger_blood_model.dart';
import '../../../../food/data/models/food_model.dart';
import '../../../../insulin/data/models/insulin_model.dart';

/// The kinds of health events that share the unified timeline.
enum TimelineEventType { food, insulin, exercise, fingerBlood, unknown }

/// Centralised mapping between an event type and its assets/keys.
extension TimelineEventTypeX on TimelineEventType {
  /// Backend discriminator string.
  String get key {
    switch (this) {
      case TimelineEventType.food:
        return 'food';
      case TimelineEventType.insulin:
        return 'insulin';
      case TimelineEventType.exercise:
        return 'exercise';
      case TimelineEventType.fingerBlood:
        return 'finger_blood';
      case TimelineEventType.unknown:
        return 'unknown';
    }
  }

  /// The SVG badge rendered in the event lane.
  String get asset {
    switch (this) {
      case TimelineEventType.food:
        return 'assets/icons/food.svg';
      case TimelineEventType.insulin:
        return 'assets/icons/insulin.svg';
      case TimelineEventType.exercise:
        return 'assets/icons/exercise.svg';
      case TimelineEventType.fingerBlood:
        return 'assets/icons/finger_blood.svg';
      case TimelineEventType.unknown:
        return 'assets/icons/food.svg';
    }
  }

  static TimelineEventType fromKey(String key) {
    switch (key) {
      case 'food':
        return TimelineEventType.food;
      case 'insulin':
        return TimelineEventType.insulin;
      case 'exercise':
        return TimelineEventType.exercise;
      case 'finger_blood':
        return TimelineEventType.fingerBlood;
      default:
        return TimelineEventType.unknown;
    }
  }
}

/// A single health event on the unified timeline, returned by
/// `GET /api/timeline/events` and rendered in the chart's event lane.
class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.title,
    required this.subtitle,
    required this.metadata,
  });

  final String id;

  final TimelineEventType type;

  /// Event time in the device's local wall-clock — matches how the feature
  /// history screens display these records, and aligns with the glucose
  /// curve's wall-clock axis.
  final DateTime timestamp;

  final String title;

  final String subtitle;

  /// Type-specific values for the detail bottom sheet.
  final Map<String, dynamic> metadata;

  String get asset => type.asset;

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    final raw = json['timestamp']?.toString() ?? '';
    final parsed = DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();

    return TimelineEvent(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      type: TimelineEventTypeX.fromKey(
        json['type']?.toString() ?? '',
      ),
      timestamp: parsed,
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }

  /// Reads a metadata value as a display string (empty when absent).
  String meta(String k) {
    final v = metadata[k];
    if (v == null) return '';
    return v.toString();
  }

  // --- Adapters from the per-feature models already loaded in the app, so the
  // event lane works from local data without depending on the timeline API.
  // Same id + metadata keys as the backend, so the two sources de-dupe cleanly.

  factory TimelineEvent.fromFood(FoodModel f) => TimelineEvent(
        id: f.id,
        type: TimelineEventType.food,
        timestamp: f.loggedAt.toLocal(),
        title: f.title.isNotEmpty ? f.title : 'Food',
        subtitle: '${f.calories} cal',
        metadata: {
          'title': f.title,
          'calories': f.calories,
          'carbs': f.carbs,
          'protein': f.protein,
          'fat': f.fat,
          'fiber': f.fiber,
        },
      );

  factory TimelineEvent.fromExercise(ExerciseModel e) => TimelineEvent(
        id: e.id,
        type: TimelineEventType.exercise,
        timestamp: e.loggedAt.toLocal(),
        title: e.title.isNotEmpty ? e.title : 'Exercise',
        subtitle: '${e.duration} min',
        metadata: {
          'activity': e.title,
          'duration': e.duration,
          'caloriesBurned': e.caloriesBurned,
        },
      );

  factory TimelineEvent.fromInsulin(InsulinModel i) => TimelineEvent(
        id: i.id,
        type: TimelineEventType.insulin,
        timestamp: i.loggedAt.toLocal(),
        title: 'Insulin',
        subtitle: '${i.dosage} units',
        metadata: {
          'insulinType': i.insulinType,
          'dosage': i.dosage,
        },
      );

  factory TimelineEvent.fromFingerBlood(FingerBloodModel f) => TimelineEvent(
        id: f.id,
        type: TimelineEventType.fingerBlood,
        timestamp: f.loggedAt.toLocal(),
        title: 'Finger Blood',
        subtitle: '${f.glucoseValue} mg/dL',
        metadata: {
          'glucoseValue': f.glucoseValue,
          'notes': f.notes,
        },
      );
}
