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

    // Sensor serial number + the sensor's own monotonic record id (the SDK's
    // `timeOffset`). Together they uniquely identify a physical reading no
    // matter how many times it is re-synced — this is the basis for the
    // idempotent backfill. Optional so pre-existing rows (which carry no
    // sequence) remain valid and untouched.
    sensorSerial: {
      type: String,
    },

    sequenceNumber: {
      type: Number,
    },

    glucoseValue: Number,

    trend: String,

    readingAt: Date,
  },
  {
    timestamps: true,
  }
);

// Primary idempotency key: one row per (sensor, sequence). Partial so it only
// constrains rows that actually carry a sequence number — legacy rows
// (sequenceNumber absent) are excluded from the index and left alone.
// Re-syncing the same reading across reconnects/restarts updates in place
// instead of duplicating.
cgmReadingSchema.index(
  { sensorSerial: 1, sequenceNumber: 1 },
  {
    unique: true,
    partialFilterExpression: {
      sequenceNumber: { $exists: true },
    },
  }
);

// Query index for the dashboard/graph: time-ordered readings per user.
cgmReadingSchema.index({ userId: 1, readingAt: 1 });

const CGMReading = mongoose.model(
  "CGMReading",
  cgmReadingSchema
);

export default CGMReading;
