export const uploadFile = async (
  req,
  res,
  next
) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "File required",
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        url: `${req.protocol}://${req.get(
          "host"
        )}/uploads/${req.file.filename}`,
      },
    });
  } catch (error) {
    next(error);
  }
};