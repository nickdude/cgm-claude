import express from "express";

import authMiddleware from "../../middleware/auth.middleware.js";

import {
  createFingerBlood,
  getFingerBlood,
  deleteFingerBlood,
} from "./fingerBlood.controller.js";

const router = express.Router();

router.post(
  "/create",
  authMiddleware,
  createFingerBlood
);

router.get(
  "/list",
  authMiddleware,
  getFingerBlood
);

router.delete(
  "/delete/:id",
  authMiddleware,
  deleteFingerBlood
);

export default router;