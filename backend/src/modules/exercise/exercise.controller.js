import {
  createExerciseService,
  getExerciseService,
  updateExerciseService,
  deleteExerciseService,
} from "./exercise.service.js";

export const createExercise =
  async (req, res, next) => {
    try {
      const exercise =
        await createExerciseService(
          req.user.id,
          req.body
        );

      return res.status(201).json({
        success: true,
        data: exercise,
      });
    } catch (error) {
      next(error);
    }
  };

export const getExercise = async (
  req,
  res,
  next
) => {
  try {
    const exercise =
      await getExerciseService(
        req.user.id
      );

    return res.status(200).json({
      success: true,
      data: exercise,
    });
  } catch (error) {
    next(error);
  }
};

export const updateExercise =
  async (req, res, next) => {
    try {
      const exercise =
        await updateExerciseService(
          req.user.id,
          req.params.id,
          req.body
        );

      return res.status(200).json({
        success: true,
        data: exercise,
      });
    } catch (error) {
      next(error);
    }
  };

export const deleteExercise =
  async (req, res, next) => {
    try {
      await deleteExerciseService(
        req.user.id,
        req.params.id
      );

      return res.status(200).json({
        success: true,
      });
    } catch (error) {
      next(error);
    }
  };