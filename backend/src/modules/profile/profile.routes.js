import express from "express";

import authMiddleware from "../../middleware/auth.middleware.js";

import {
  getProfile,
  updateProfile,
} from "./profile.controller.js";

const router = express.Router();

router.get(
  "/me",
  authMiddleware,
  getProfile
);

router.put(
  "/update",
  authMiddleware,
  updateProfile
);

export default router;