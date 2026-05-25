import Insulin from "./insulin.model.js";

export const createInsulinService =
  async (userId, payload) => {
    return await Insulin.create({
      ...payload,
      userId,
    });
  };

export const getInsulinService =
  async (userId) => {
    return await Insulin.find({
      userId,
    }).sort({
      loggedAt: -1,
    });
  };

export const deleteInsulinService =
  async (userId, id) => {
    return await Insulin.findOneAndDelete(
      {
        _id: id,
        userId,
      }
    );
  };