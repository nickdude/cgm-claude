import mongoose from "mongoose";

import FingerBlood from "./fingerBlood.model.js";

// Fields a client is allowed to change on update. userId is never updatable
// so ownership can't be reassigned.
const UPDATABLE_FIELDS = [
  "glucoseValue",
  "notes",
  "loggedAt",
];

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

export const updateFingerBloodService =
  async (userId, id, payload) => {
    if (
      !mongoose.Types.ObjectId.isValid(id)
    ) {
      const error = new Error(
        "Finger blood record not found"
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

    const record =
      await FingerBlood.findOneAndUpdate(
        { _id: id, userId },
        { $set: update },
        {
          new: true,
          runValidators: true,
        }
      );

    if (!record) {
      const error = new Error(
        "Finger blood record not found"
      );
      error.statusCode = 404;
      throw error;
    }

    return record;
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