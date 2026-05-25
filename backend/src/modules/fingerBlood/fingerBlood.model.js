import mongoose from "mongoose";

const fingerBloodSchema =
  new mongoose.Schema(
    {
      userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },

      glucoseValue: Number,

      notes: String,

      loggedAt: {
        type: Date,
        default: Date.now,
      },
    },
    {
      timestamps: true,
    }
  );

const FingerBlood = mongoose.model(
  "FingerBlood",
  fingerBloodSchema
);

export default FingerBlood;