import mongoose from "mongoose";

const foodSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    title: String,

    image: {
      type: String,
      default: "",
    },

    carbs: Number,

    protein: Number,

    fat: Number,

    fiber: Number,

    calories: Number,

    loggedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

const Food = mongoose.model(
  "Food",
  foodSchema
);

export default Food;