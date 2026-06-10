import Exercise from "../exercise/exercise.model.js";
import FingerBlood from "../fingerBlood/fingerBlood.model.js";
import Food from "../food/food.model.js";
import Insulin from "../insulin/insulin.model.js";

// --- Per-type mappers into the unified timeline shape ---

const mapExercise = (e) => ({
  id: e._id.toString(),
  type: "exercise",
  timestamp: e.loggedAt,
  title: e.activityType || "Exercise",
  subtitle: `${e.duration || 0} min`,
  metadata: {
    activity: e.activityType || "",
    duration: e.duration || 0,
    caloriesBurned: e.caloriesBurned || 0,
  },
});

const mapFingerBlood = (f) => ({
  id: f._id.toString(),
  type: "finger_blood",
  timestamp: f.loggedAt,
  title: "Finger Blood",
  subtitle: `${f.glucoseValue || 0} mg/dL`,
  metadata: {
    glucoseValue: f.glucoseValue || 0,
    notes: f.notes || "",
  },
});

const mapFood = (f) => ({
  id: f._id.toString(),
  type: "food",
  timestamp: f.loggedAt,
  title: f.title || "Food",
  subtitle: `${f.calories || 0} cal`,
  metadata: {
    title: f.title || "",
    calories: f.calories || 0,
    carbs: f.carbs || 0,
    protein: f.protein || 0,
    fat: f.fat || 0,
    fiber: f.fiber || 0,
  },
});

const mapInsulin = (i) => ({
  id: i._id.toString(),
  type: "insulin",
  timestamp: i.loggedAt,
  title: "Insulin",
  subtitle: `${i.dosage || 0} units`,
  metadata: {
    insulinType: i.insulinType || "",
    dosage: i.dosage || 0,
  },
});

/// Queries all four health-event collections for [userId] within
/// [from, to] (on `loggedAt`), maps them into a single unified shape, and
/// returns them merged and sorted ascending by timestamp.
export const getTimelineEventsService = async (
  userId,
  from,
  to
) => {
  const query = {
    userId,
    loggedAt: { $gte: from, $lte: to },
  };

  const [exercises, fingerBloods, foods, insulins] =
    await Promise.all([
      Exercise.find(query),
      FingerBlood.find(query),
      Food.find(query),
      Insulin.find(query),
    ]);

  const events = [
    ...exercises.map(mapExercise),
    ...fingerBloods.map(mapFingerBlood),
    ...foods.map(mapFood),
    ...insulins.map(mapInsulin),
  ];

  events.sort(
    (a, b) =>
      new Date(a.timestamp).getTime() -
      new Date(b.timestamp).getTime()
  );

  return events;
};
