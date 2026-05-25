import CGMDevice from "./cgmDevice.model.js";

import User from "../auth/auth.model.js";

export const connectDeviceService =
  async (userId, payload) => {
    await CGMDevice.updateMany(
      {
        userId,
        status: "ACTIVE",
      },
      {
        status: "EXPIRED",
      }
    );

    const connectedAt = new Date();

    const warmupStartedAt =
      new Date();

    const expiresAt = new Date(
      Date.now() +
        14 * 24 * 60 * 60 * 1000
    );

    const device =
      await CGMDevice.create({
        userId,

        serialNumber:
          payload.serialNumber,

        deviceName: payload.deviceName,

        manufacturer:
          payload.manufacturer,

        status: "WARMUP",

        connectedAt,

        warmupStartedAt,

        expiresAt,
      });

    await User.findByIdAndUpdate(userId, {
      activeDeviceId: device._id,
    });

    return device;
  };

export const getActiveDeviceService =
  async (userId) => {
    return await CGMDevice.findOne({
      userId,
      status: {
        $in: ["WARMUP", "ACTIVE"],
      },
    });
  };