import express from "express";

import authMiddleware from "../../middleware/auth.middleware.js";

import {
  createFingerBlood,
  getFingerBlood,
  updateFingerBlood,
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

router.put(
  "/:id",
  authMiddleware,
  updateFingerBlood
);

router.delete(
  "/delete/:id",
  authMiddleware,
  deleteFingerBlood
);

export default router;