import {
  createInsulinService,
  getInsulinService,
  deleteInsulinService,
} from "./insulin.service.js";

export const createInsulin =
  async (req, res, next) => {
    try {
      const insulin =
        await createInsulinService(
          req.user.id,
          req.body
        );

      return res.status(201).json({
        success: true,
        data: insulin,
      });
    } catch (error) {
      next(error);
    }
  };

export const getInsulin = async (
  req,
  res,
  next
) => {
  try {
    const insulin =
      await getInsulinService(
        req.user.id
      );

    return res.status(200).json({
      success: true,
      data: insulin,
    });
  } catch (error) {
    next(error);
  }
};

export const deleteInsulin =
  async (req, res, next) => {
    try {
      await deleteInsulinService(
        req.user.id,
        req.params.id
      );

      return res.status(200).json({
        success: true,
      });
    } catch (error) {
      next(error);
    }
  };