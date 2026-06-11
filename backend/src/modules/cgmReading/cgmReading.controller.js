import {
  addReadingService,
  addReadingsBulkService,
  getCheckpointService,
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

// Bulk idempotent upsert for the reconnect backfill. Body: { readings: [...] }.
export const addReadingsBulk = async (
  req,
  res,
  next
) => {
  try {
    const stored =
      await addReadingsBulkService(
        req.user.id,
        req.body?.readings
      );

    return res.status(201).json({
      success: true,
      message: "Readings synced",
      data: stored,
    });
  } catch (error) {
    next(error);
  }
};

// Restart-safe sync checkpoint: highest stored sequence for ?sn=<serial>.
export const getCheckpoint = async (
  req,
  res,
  next
) => {
  try {
    const checkpoint =
      await getCheckpointService(
        req.user.id,
        req.query?.sn
      );

    return res.status(200).json({
      success: true,
      data: checkpoint,
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
