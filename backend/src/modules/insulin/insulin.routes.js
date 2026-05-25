import express from "express";

import authMiddleware from "../../middleware/auth.middleware.js";

import {
  createInsulin,
  getInsulin,
  deleteInsulin,
} from "./insulin.controller.js";

const router = express.Router();

router.post(
  "/create",
  authMiddleware,
  createInsulin
);

router.get(
  "/list",
  authMiddleware,
  getInsulin
);

router.delete(
  "/delete/:id",
  authMiddleware,
  deleteInsulin
);

export default router;