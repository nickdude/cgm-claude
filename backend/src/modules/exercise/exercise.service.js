import mongoose from "mongoose";

import Exercise from "./exercise.model.js";

// Fields a client is allowed to change on update. userId is never updatable
// so ownership can't be reassigned.
const UPDATABLE_FIELDS = [
  "activityType",
  "duration",
  "caloriesBurned",
  "image",
  "loggedAt",
];

export const createExerciseService =
  async (userId, payload) => {
    return await Exercise.create({
      ...payload,
      userId,
    });
  };

export const getExerciseService =
  async (userId) => {
    return await Exercise.find({
      userId,
    }).sort({
      loggedAt: -1,
    });
  };

export const updateExerciseService =
  async (userId, id, payload) => {
    if (
      !mongoose.Types.ObjectId.isValid(id)
    ) {
      const error = new Error(
        "Exercise not found"
      );
      error.statusCode = 404;
      throw error;
    }

    const update = {};
    for (const key of UPDATABLE_FIELDS) {
      if (payload[key] !== undefined) {
        update[key] = payload[key];
      }
    }

    const exercise =
      await Exercise.findOneAndUpdate(
        { _id: id, userId },
        { $set: update },
        {
          new: true,
          runValidators: true,
        }
      );

    if (!exercise) {
      const error = new Error(
        "Exercise not found"
      );
      error.statusCode = 404;
      throw error;
    }

    return exercise;
  };

export const deleteExerciseService =
  async (userId, id) => {
    return await Exercise.findOneAndDelete(
      {
        _id: id,
        userId,
      }
    );
  };