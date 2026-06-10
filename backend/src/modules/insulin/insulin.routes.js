import express from "express";

import authMiddleware from "../../middleware/auth.middleware.js";

import {
  createInsulin,
  getInsulin,
  updateInsulin,
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

router.put(
  "/:id",
  authMiddleware,
  updateInsulin
);

router.delete(
  "/delete/:id",
  authMiddleware,
  deleteInsulin
);

export default router;