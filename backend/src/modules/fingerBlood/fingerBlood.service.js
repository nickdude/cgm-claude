import FingerBlood from "./fingerBlood.model.js";

export const createFingerBloodService =
  async (userId, payload) => {
    return await FingerBlood.create({
      ...payload,
      userId,
    });
  };

export const getFingerBloodService =
  async (userId) => {
    return await FingerBlood.find({
      userId,
    }).sort({
      loggedAt: -1,
    });
  };

export const deleteFingerBloodService =
  async (userId, id) => {
    return await FingerBlood.findOneAndDelete(
      {
        _id: id,
        userId,
      }
    );
  };