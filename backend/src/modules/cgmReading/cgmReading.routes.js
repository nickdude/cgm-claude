import express from "express";

import authMiddleware from "../../middleware/auth.middleware.js";

import {
  addReading,
  getReadings,
} from "./cgmReading.controller.js";

const router = express.Router();

router.post(
  "/add",
  authMiddleware,
  addReading
);

router.get(
  "/list",
  authMiddleware,
  getReadings
);

export default router;