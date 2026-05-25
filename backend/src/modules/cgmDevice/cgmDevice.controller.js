import {
  connectDeviceService,
  getActiveDeviceService,
} from "./cgmDevice.service.js";

export const connectDevice = async (
  req,
  res,
  next
) => {
  try {
    const device =
      await connectDeviceService(
        req.user.id,
        req.body
      );

    return res.status(201).json({
      success: true,
      message:
        "CGM connected successfully",
      data: device,
    });
  } catch (error) {
    next(error);
  }
};

export const getActiveDevice =
  async (req, res, next) => {
    try {
      const device =
        await getActiveDeviceService(
          req.user.id
        );

      return res.status(200).json({
        success: true,
        data: device,
      });
    } catch (error) {
      next(error);
    }
  };