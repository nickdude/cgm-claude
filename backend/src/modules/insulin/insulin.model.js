import mongoose from "mongoose";

const insulinSchema =
  new mongoose.Schema(
    {
      userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },

      insulinType: String,

      dosage: Number,

      loggedAt: {
        type: Date,
        default: Date.now,
      },
    },
    {
      timestamps: true,
    }
  );

const Insulin = mongoose.model(
  "Insulin",
  insulinSchema
);

export default Insulin;