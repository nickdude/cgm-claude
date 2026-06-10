import express from "express";

import authRoutes from "../modules/auth/auth.routes.js";

import profileRoutes from "../modules/profile/profile.routes.js";

import onboardingRoutes from "../modules/onboarding/onboarding.routes.js";

import cgmDeviceRoutes from "../modules/cgmDevice/cgmDevice.routes.js";

import cgmReadingRoutes from "../modules/cgmReading/cgmReading.routes.js";

import foodRoutes from "../modules/food/food.routes.js";

import insulinRoutes from "../modules/insulin/insulin.routes.js";

import exerciseRoutes from "../modules/exercise/exercise.routes.js";

import fingerBloodRoutes from "../modules/fingerBlood/fingerBlood.routes.js";

import uploadRoutes from "../modules/upload/upload.routes.js";

import timelineRoutes from "../modules/timeline/timeline.routes.js";

const router = express.Router();

router.use("/auth", authRoutes);

router.use("/profile", profileRoutes);

router.use(
  "/onboarding",
  onboardingRoutes
);

router.use(
  "/cgm-device",
  cgmDeviceRoutes
);

router.use(
  "/cgm-reading",
  cgmReadingRoutes
);

router.use("/food", foodRoutes);

router.use("/insulin", insulinRoutes);

router.use("/exercise", exerciseRoutes);

router.use(
  "/finger-blood",
  fingerBloodRoutes
);

router.use("/upload", uploadRoutes);

router.use("/timeline", timelineRoutes);

router.get("/", (req, res) => {
  res.json({
    success: true,
    message: "API Running",
  });
});

export default router;