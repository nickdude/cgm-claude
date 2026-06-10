import mongoose from "mongoose";

import Food from "./food.model.js";

// Fields a client is allowed to change on update. userId is never updatable
// so ownership can't be reassigned.
const UPDATABLE_FIELDS = [
  "title",
  "image",
  "carbs",
  "protein",
  "fat",
  "fiber",
  "calories",
  "loggedAt",
];

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

export const updateFoodService =
  async (userId, id, payload) => {
    if (
      !mongoose.Types.ObjectId.isValid(id)
    ) {
      const error = new Error(
        "Food not found"
      );
      error.statusCode = 404;
      throw error;
    }

    const update = {};
    for (const key of UPDATABLE_FIELDS) {
      if (payload[key] !== undefined) {
        update[key] = payload[key];
      }
    }

    const food =
      await Food.findOneAndUpdate(
        { _id: id, userId },
        { $set: update },
        {
          new: true,
          runValidators: true,
        }
      );

    if (!food) {
      const error = new Error(
        "Food not found"
      );
      error.statusCode = 404;
      throw error;
    }

    return food;
  };

export const deleteFoodService =
  async (userId, id) => {
    return await Food.findOneAndDelete({
      _id: id,
      userId,
    });
  };