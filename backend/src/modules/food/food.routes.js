import express from "express";

import authMiddleware from "../../middleware/auth.middleware.js";

import {
  createFood,
  getFoods,
  updateFood,
  deleteFood,
} from "./food.controller.js";

const router = express.Router();

router.post(
  "/create",
  authMiddleware,
  createFood
);

router.get(
  "/list",
  authMiddleware,
  getFoods
);

router.put(
  "/:id",
  authMiddleware,
  updateFood
);

router.delete(
  "/delete/:id",
  authMiddleware,
  deleteFood
);

export default router;