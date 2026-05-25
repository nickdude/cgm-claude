const errorMiddleware = (
  err,
  req,
  res,
  next
) => {
  const statusCode =
    err.statusCode ||
    (err.name === "MulterError" ? 400 : 500);

  const message =
    err.name === "MulterError" &&
    err.code === "LIMIT_FILE_SIZE"
      ? "Image size must be 5MB or less"
      : err.message;

  return res.status(statusCode).json({
    success: false,
    message,
  });
};

export default errorMiddleware;