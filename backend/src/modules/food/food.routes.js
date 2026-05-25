import express from "express";

import authMiddleware from "../../middleware/auth.middleware.js";

import {
  createFood,
  getFoods,
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

router.delete(
  "/delete/:id",
  authMiddleware,
  deleteFood
);

export default router;