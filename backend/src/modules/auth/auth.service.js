import bcrypt from "bcryptjs";
import crypto from "crypto";

import User from "./auth.model.js";

import generateToken from "../../utils/generateToken.js";
import hashToken from "../../utils/hashToken.js";

import { sendEmail } from "../../services/email.service.js";

export const registerService = async (
  payload
) => {
  const existingUser = await User.findOne({
    email: payload.email,
  });

  if (existingUser) {
    throw new Error("Email already exists");
  }

  const hashedPassword = await bcrypt.hash(
    payload.password,
    10
  );

  const rawToken = crypto
    .randomBytes(32)
    .toString("hex");

  const hashedToken = hashToken(rawToken);

  const user = await User.create({
    ...payload,
    password: hashedPassword,
    emailVerificationToken: hashedToken,
    emailVerificationTokenExpiry:
      Date.now() + 1000 * 60 * 60,
  });

  const verifyUrl = `${process.env.CLIENT_URL}/verify-email/${rawToken}`;

  await sendEmail(
    user.email,
    "Verify Email",
    `
      <h2>Verify Email</h2>
      <a href="${verifyUrl}">
        Verify Email
      </a>
    `
  );

  return user;
};

export const verifyEmailService = async (
  token
) => {
  const hashedToken = hashToken(token);

  const user = await User.findOne({
    emailVerificationToken: hashedToken,
    emailVerificationTokenExpiry: {
      $gt: Date.now(),
    },
  });

  if (!user) {
    throw new Error("Invalid or expired token");
  }

  user.isEmailVerified = true;

  user.emailVerificationToken = null;

  user.emailVerificationTokenExpiry = null;

  await user.save();

  return true;
};

export const loginService = async (
  email,
  password
) => {
  const user = await User.findOne({ email });

  if (!user) {
    throw new Error("Invalid credentials");
  }

  if (!user.isEmailVerified) {
    throw new Error("Please verify email");
  }

  const isPasswordMatched =
    await bcrypt.compare(
      password,
      user.password
    );

  if (!isPasswordMatched) {
    throw new Error("Invalid credentials");
  }

  const token = generateToken({
    id: user._id,
  });

  user.lastLoginAt = new Date();

  await user.save();

  return {
    token,
    user,
  };
};

export const forgotPasswordService = async (email) => {
    const user = await User.findOne({
      email,
    });

    if (!user) {
      throw new Error("User not found");
    }

    const rawToken = crypto
      .randomBytes(32)
      .toString("hex");

    const hashedToken =
      hashToken(rawToken);

    user.forgotPasswordToken =
      hashedToken;

    user.forgotPasswordTokenExpiry =
      Date.now() + 1000 * 60 * 30;

    await user.save();

    const resetUrl = `${process.env.CLIENT_URL}/reset-password/${rawToken}`;

    await sendEmail(
      user.email,
      "Reset Password",
      `
        <h2>Reset Password</h2>

        <a href="${resetUrl}">
          Reset Password
        </a>
      `
    );

    return true;
  };

export const resetPasswordService = async (token, password) => {
    const hashedToken =
      hashToken(token);

    const user = await User.findOne({
      forgotPasswordToken:
        hashedToken,

      forgotPasswordTokenExpiry: {
        $gt: Date.now(),
      },
    });

    if (!user) {
      throw new Error(
        "Invalid or expired token"
      );
    }

    const hashedPassword =
      await bcrypt.hash(password, 10);

    user.password = hashedPassword;

    user.forgotPasswordToken = null;

    user.forgotPasswordTokenExpiry =
      null;

    await user.save();

    return true;
  };