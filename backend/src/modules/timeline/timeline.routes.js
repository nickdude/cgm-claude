import express from "express";

import authMiddleware from "../../middleware/auth.middleware.js";

import { getTimelineEvents } from "./timeline.controller.js";

const router = express.Router();

router.get(
  "/events",
  authMiddleware,
  getTimelineEvents
);

export default router;
