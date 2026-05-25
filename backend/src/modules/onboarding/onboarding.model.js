import mongoose from "mongoose";

const onboardingSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    age: Number,

    gender: String,

    diabetesType: String,

    height: Number,

    weight: Number,

    insulinUsage: Boolean,

    diagnosedYear: Number,

    activityLevel: String,
  },
  {
    timestamps: true,
  }
);

const Onboarding = mongoose.model(
  "Onboarding",
  onboardingSchema
);

export default Onboarding;