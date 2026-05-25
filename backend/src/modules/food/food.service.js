import Food from "./food.model.js";

export const createFoodService =
  async (userId, payload) => {
    return await Food.create({
      ...payload,
      userId,
    });
  };

export const getFoodsService =
  async (userId) => {
    return await Food.find({
      userId,
    }).sort({
      loggedAt: -1,
    });
  };

export const deleteFoodService =
  async (userId, id) => {
    return await Food.findOneAndDelete({
      _id: id,
      userId,
    });
  };