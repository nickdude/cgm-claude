import express from "express";

import authMiddleware from "../../middleware/auth.middleware.js";

import {
  createExercise,
  getExercise,
  updateExercise,
  deleteExercise,
} from "./exercise.controller.js";

const router = express.Router();

router.post(
  "/create",
  authMiddleware,
  createExercise
);

router.get(
  "/list",
  authMiddleware,
  getExercise
);

router.put(
  "/:id",
  authMiddleware,
  updateExercise
);

router.delete(
  "/delete/:id",
  authMiddleware,
  deleteExercise
);

export default router;