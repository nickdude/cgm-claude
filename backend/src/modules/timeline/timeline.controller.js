import { getTimelineEventsService } from "./timeline.service.js";

// GET /api/timeline/events?from=<ISO>&to=<ISO>
// Returns every logged health event (exercise / finger blood / food / insulin)
// in the range as one unified, time-sorted list.
export const getTimelineEvents = async (
  req,
  res,
  next
) => {
  try {
    const now = Date.now();

    // Defaults: last 7 days → now when params are missing.
    const to = req.query.to
      ? new Date(req.query.to)
      : new Date(now);

    const from = req.query.from
      ? new Date(req.query.from)
      : new Date(now - 7 * 24 * 60 * 60 * 1000);

    if (
      isNaN(from.getTime()) ||
      isNaN(to.getTime())
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Invalid 'from'/'to' query parameters",
      });
    }

    const events =
      await getTimelineEventsService(
        req.user.id,
        from,
        to
      );

    return res.status(200).json({
      success: true,
      data: events,
    });
  } catch (error) {
    next(error);
  }
};
