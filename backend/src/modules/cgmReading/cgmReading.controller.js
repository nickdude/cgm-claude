import {
  addReadingService,
  getReadingsService,
} from "./cgmReading.service.js";

export const addReading = async (
  req,
  res,
  next
) => {
  try {
    const reading =
      await addReadingService(
        req.user.id,
        req.body
      );

    return res.status(201).json({
      success: true,
      message:
        "Reading added successfully",
      data: reading,
    });
  } catch (error) {
    next(error);
  }
};

export const getReadings = async (
  req,
  res,
  next
) => {
  try {
    const readings =
      await getReadingsService(
        req.user.id
      );

    return res.status(200).json({
      success: true,
      data: readings,
    });
  } catch (error) {
    next(error);
  }
};