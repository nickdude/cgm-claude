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

    const readingAt =
      payload.readingAt || now;

    // Idempotent insert: keyed on (userId, deviceId, readingAt) so the same
    // reading arriving twice (live stream + history backfill, or a retry)
    // updates in place instead of creating a duplicate row.
    const reading =
      await CGMReading.findOneAndUpdate(
        {
          userId,
          deviceId: activeDevice._id,
          readingAt,
        },
        {
          $set: {
            glucoseValue:
              payload.glucoseValue,
            trend: payload.trend,
          },
        },
        {
          upsert: true,
          new: true,
          setDefaultsOnInsert: true,
        }
      );

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