import mongoose from "mongoose";

const cgmDeviceSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    serialNumber: String,

    deviceName: String,

    manufacturer: String,

    status: {
      type: String,
      enum: [
        "CONNECTING",
        "WARMUP",
        "ACTIVE",
        "EXPIRED",
        "DISCONNECTED",
      ],
      default: "CONNECTING",
    },

    connectedAt: Date,

    activatedAt: Date,

    expiresAt: Date,

    warmupStartedAt: Date,

    isWarmupCompleted: {
      type: Boolean,
      default: false,
    },

    lastSyncedAt: Date,
  },
  {
    timestamps: true,
  }
);

const CGMDevice = mongoose.model(
  "CGMDevice",
  cgmDeviceSchema
);

export default CGMDevice;