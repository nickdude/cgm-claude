import express from "express";

import authMiddleware from "../../middleware/auth.middleware.js";

import {
  connectDevice,
  getActiveDevice,
} from "./cgmDevice.controller.js";

const router = express.Router();

router.post(
  "/connect",
  authMiddleware,
  connectDevice
);

router.get(
  "/active",
  authMiddleware,
  getActiveDevice
);

export default router;