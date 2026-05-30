import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      default: "",
    },

    phoneNumber: {
      type: String,
      trim: true,
      default: "",
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
    },

    password: {
      type: String,
      default: "",
    },

    profileImage: {
      type: String,
      default: "",
    },

    provider: {
      type: String,
      enum: [
        "email",
        "google",
        "facebook",
        "apple",
      ],
      default: "email",
    },

    providerId: {
      type: String,
      default: "",
    },

    isEmailVerified: {
      type: Boolean,
      default: false,
    },

    emailVerificationToken: {
      type: String,
      default: null,
    },

    emailVerificationTokenExpiry: {
      type: Date,
      default: null,
    },

    forgotPasswordToken: {
      type: String,
      default: null,
    },

    forgotPasswordTokenExpiry: {
      type: Date,
      default: null,
    },

    isProfileCompleted: {
      type: Boolean,
      default: false,
    },

    isOnboardingCompleted: {
      type: Boolean,
      default: false,
    },

    activeDeviceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "CGMDevice",
      default: null,
    },

    lastLoginAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

const User = mongoose.model("User", userSchema);

export default User;