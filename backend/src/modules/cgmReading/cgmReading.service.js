import CGMReading from "./cgmReading.model.js";

import CGMDevice from "../cgmDevice/cgmDevice.model.js";

export const addReadingService =
  async (userId, payload) => {
    const activeDevice =
      await CGMDevice.findOne({
        userId,
        status: {
          $in: ["WARMUP", "ACTIVE"],
        },
      });

    if (!activeDevice) {
      throw new Error(
        "No active CGM device found"
      );
    }

    const now = new Date();

    const warmupCompleted =
      now - activeDevice.warmupStartedAt >=
      60 * 60 * 1000;

    if (
      warmupCompleted &&
      !activeDevice.isWarmupCompleted
    ) {
      activeDevice.isWarmupCompleted =
        true;

      activeDevice.status = "ACTIVE";

      activeDevice.activatedAt = now;

      await activeDevice.save();
    }

    const reading =
      await CGMReading.create({
        userId,

        deviceId: activeDevice._id,

        glucoseValue:
          payload.glucoseValue,

        trend: payload.trend,

        readingAt:
          payload.readingAt || now,
      });

    return reading;
  };

export const getReadingsService =
  async (userId) => {
    return await CGMReading.find({
      userId,
    }).sort({
      readingAt: -1,
    });
  };