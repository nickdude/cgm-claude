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

// Dedup constraint: one reading per device per timestamp. Prevents the same
// reading being inserted twice (e.g. live stream + history backfill, or a
// retry). Run the cleanup script before deploying so the index can build.
cgmReadingSchema.index(
  { userId: 1, deviceId: 1, readingAt: 1 },
  { unique: true }
);

const CGMReading = mongoose.model(
  "CGMReading",
  cgmReadingSchema
);

export default CGMReading;