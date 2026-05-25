import mongoose from "mongoose";

const cgmReadingSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    deviceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "CGMDevice",
    },

    glucoseValue: Number,

    trend: String,

    readingAt: Date,
  },
  {
    timestamps: true,
  }
);

const CGMReading = mongoose.model(
  "CGMReading",
  cgmReadingSchema
);

export default CGMReading;