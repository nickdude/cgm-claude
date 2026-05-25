import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      trim: true,
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
    },

    password: {
      type: String,
      required: true,
    },

    profileImage: {
      type: String,
      default: "",
    },

    age: Number,

    gender: String,

    diabetesType: String,

    cgmDeviceSN: {
      type: String,
      default: "",
    },

    isProfileCompleted: {
      type: Boolean,
      default: false,
    },

    isOnboardingCompleted: {
      type: Boolean,
      default: false,
    },

    isCGMConnected: {
      type: Boolean,
      default: false,
    },

    isCGMWarmupCompleted: {
      type: Boolean,
      default: false,
    },

    warmupStartedAt: {
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