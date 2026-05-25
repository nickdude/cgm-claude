import express from "express";

import upload from "../../middleware/upload.middleware.js";

import authMiddleware from "../../middleware/auth.middleware.js";

import { uploadFile } from "./upload.controller.js";

const router = express.Router();

router.post(
  "/single",
  authMiddleware,
  upload.single("file"),
  uploadFile
);

export default router;