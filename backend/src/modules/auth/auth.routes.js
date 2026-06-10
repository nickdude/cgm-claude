import express from "express";

import {
  register,
  verifyEmail,
  login,
  forgotPassword,
  resetPassword,
  resetPasswordPage,
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

// GET renders the password-reset web page (opened from the email link);
// POST performs the actual reset. Same path, different methods.
router.get(
  "/reset-password/:token",
  resetPasswordPage
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