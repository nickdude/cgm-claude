import mongoose from "mongoose";

const exerciseSchema =
  new mongoose.Schema(
    {
      userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },

      activityType: String,

      duration: Number,

      caloriesBurned: Number,

      image: {
        type: String,
        default: "",
      },

      loggedAt: {
        type: Date,
        default: Date.now,
      },
    },
    {
      timestamps: true,
    }
  );

const Exercise = mongoose.model(
  "Exercise",
  exerciseSchema
);

export default Exercise;