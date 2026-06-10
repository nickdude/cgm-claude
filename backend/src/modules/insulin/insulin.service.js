import mongoose from "mongoose";

import Insulin from "./insulin.model.js";

// Fields a client is allowed to change on update. userId is never updatable
// so ownership can't be reassigned.
const UPDATABLE_FIELDS = [
  "insulinType",
  "dosage",
  "loggedAt",
];

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

export const updateInsulinService =
  async (userId, id, payload) => {
    if (
      !mongoose.Types.ObjectId.isValid(id)
    ) {
      const error = new Error(
        "Insulin not found"
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

    const insulin =
      await Insulin.findOneAndUpdate(
        { _id: id, userId },
        { $set: update },
        {
          new: true,
          runValidators: true,
        }
      );

    if (!insulin) {
      const error = new Error(
        "Insulin not found"
      );
      error.statusCode = 404;
      throw error;
    }

    return insulin;
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