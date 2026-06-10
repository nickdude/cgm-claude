import path from "path";
import { fileURLToPath } from "url";
import { readFile } from "fs/promises";

import {
  registerValidation,
  loginValidation,
} from "./auth.validation.js";

import {
  registerService,
  verifyEmailService,
  loginService,
  forgotPasswordService,
  resetPasswordService,
} from "./auth.service.js";

const __dirname = path.dirname(
  fileURLToPath(import.meta.url)
);

const RESET_PASSWORD_VIEW = path.join(
  __dirname,
  "views",
  "reset-password.html"
);

export const register = async (
  req,
  res,
  next
) => {
  try {
    const { error } = registerValidation(
      req.body
    );

    if (error) {
      return res.status(400).json({
        success: false,
        message: error.details[0].message,
      });
    }

    await registerService(req.body);

    return res.status(201).json({
      success: true,
      message:
        "Registration successful. Please verify email.",
    });
  } catch (error) {
    next(error);
  }
};

export const verifyEmail = async (
  req,
  res,
  next
) => {
  try {
    await verifyEmailService(req.params.token);

    return res.status(200).json({
      success: true,
      message: "Email verified successfully",
    });
  } catch (error) {
    next(error);
  }
};

export const login = async (
  req,
  res,
  next
) => {
  try {
    const { error } = loginValidation(
      req.body
    );

    if (error) {
      return res.status(400).json({
        success: false,
        message: error.details[0].message,
      });
    }

    const response = await loginService(
      req.body.email,
      req.body.password
    );

    return res.status(200).json({
      success: true,
      data: response,
    });
  } catch (error) {
    next(error);
  }
};

export const forgotPassword = async (req, res, next) => {
    try {
      await forgotPasswordService(
        req.body.email
      );

      return res.status(200).json({
        success: true,
        message:
          "Reset email sent successfully",
      });
    } catch (error) {
      next(error);
    }
};

export const resetPassword = async (req, res, next) => {
    try {
      await resetPasswordService(
        req.params.token,
        req.body.password
      );

      return res.status(200).json({
        success: true,
        message:
          "Password reset successful",
      });
    } catch (error) {
      next(error);
    }
};

// Serves the self-contained reset-password HTML page when the user opens the
// link from the email (a GET request). The page reads the token from the URL
// and submits to the existing POST /api/auth/reset-password/:token endpoint —
// the reset business logic is NOT duplicated here.
export const resetPasswordPage = async (
  req,
  res,
  next
) => {
  try {
    const loginUrl =
      process.env.CLIENT_URL ||
      "https://belvixdiagnosticindia.com";

    let html = await readFile(
      RESET_PASSWORD_VIEW,
      "utf-8"
    );

    html = html.replaceAll(
      "{{LOGIN_URL}}",
      loginUrl
    );

    res.set(
      "Content-Type",
      "text/html; charset=utf-8"
    );

    return res.status(200).send(html);
  } catch (error) {
    next(error);
  }
};