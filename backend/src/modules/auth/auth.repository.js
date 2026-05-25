import User from "./auth.model.js";

export const findUserByEmail = (email) =>
  User.findOne({ email });

export const createUser = (payload) =>
  User.create(payload);

export const findUserByVerificationToken = (
  token
) =>
  User.findOne({
    emailVerificationToken: token,
    emailVerificationTokenExpiry: {
      $gt: Date.now(),
    },
  });