import express from "express";

import authMiddleware from "../../middleware/auth.middleware.js";

import {
  addReading,
  addReadingsBulk,
  getCheckpoint,
  getReadings,
} from "./cgmReading.controller.js";

const router = express.Router();

router.post(
  "/add",
  authMiddleware,
  addReading
);

router.post(
  "/bulk",
  authMiddleware,
  addReadingsBulk
);

router.get(
  "/checkpoint",
  authMiddleware,
  getCheckpoint
);

router.get(
  "/list",
  authMiddleware,
  getReadings
);

export default router;
