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

    const filePath = `/uploads/${req.file.filename}`;

    return res.status(200).json({
      success: true,
      data: {
        path: filePath,
        url: `${req.protocol}://${req.get(
          "host"
        )}${filePath}`,
      },
    });
  } catch (error) {
    next(error);
  }
};