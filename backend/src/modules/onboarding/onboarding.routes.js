import express from "express";

import authMiddleware from "../../middleware/auth.middleware.js";

import {
  submitOnboarding,
  getOnboarding,
} from "./onboarding.controller.js";

const router = express.Router();

router.post(
  "/submit",
  authMiddleware,
  submitOnboarding
);

router.get(
  "/me",
  authMiddleware,
  getOnboarding
);

export default router;