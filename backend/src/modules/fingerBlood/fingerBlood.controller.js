import {
  createFingerBloodService,
  getFingerBloodService,
  updateFingerBloodService,
  deleteFingerBloodService,
} from "./fingerBlood.service.js";

export const createFingerBlood =
  async (req, res, next) => {
    try {
      const data =
        await createFingerBloodService(
          req.user.id,
          req.body
        );

      return res.status(201).json({
        success: true,
        data,
      });
    } catch (error) {
      next(error);
    }
  };

export const getFingerBlood =
  async (req, res, next) => {
    try {
      const data =
        await getFingerBloodService(
          req.user.id
        );

      return res.status(200).json({
        success: true,
        data,
      });
    } catch (error) {
      next(error);
    }
  };

export const updateFingerBlood =
  async (req, res, next) => {
    try {
      const data =
        await updateFingerBloodService(
          req.user.id,
          req.params.id,
          req.body
        );

      return res.status(200).json({
        success: true,
        data,
      });
    } catch (error) {
      next(error);
    }
  };

export const deleteFingerBlood =
  async (req, res, next) => {
    try {
      await deleteFingerBloodService(
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