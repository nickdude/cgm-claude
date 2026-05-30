import express from "express";

import {
  register,
  verifyEmail,
  login,
  forgotPassword,
  resetPassword,
} from "./auth.controller.js";

import {
  googleLogin,
  facebookLogin,
  appleLogin,
} from "./socialAuth.controller.js";

const router = express.Router();

router.post("/register", register);

router.get(
  "/verify-email/:token",
  verifyEmail
);

router.post("/login", login);

router.post(
  "/forgot-password",
  forgotPassword
);

router.post(
  "/reset-password/:token",
  resetPassword
);

router.post(
  "/google-login",
  googleLogin
);

router.post(
  "/facebook-login",
  facebookLogin
);

router.post(
  "/apple-login",
  appleLogin
);

export default router;