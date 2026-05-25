import Exercise from "./exercise.model.js";

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

export const deleteExerciseService =
  async (userId, id) => {
    return await Exercise.findOneAndDelete(
      {
        _id: id,
        userId,
      }
    );
  };