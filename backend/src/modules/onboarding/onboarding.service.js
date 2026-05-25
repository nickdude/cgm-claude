import Onboarding from "./onboarding.model.js";

import User from "../auth/auth.model.js";

export const submitOnboardingService =
  async (userId, payload) => {
    const onboarding =
      await Onboarding.findOneAndUpdate(
        {
          userId,
        },
        {
          ...payload,
          userId,
        },
        {
          upsert: true,
          new: true,
        }
      );

    await User.findByIdAndUpdate(userId, {
      isOnboardingCompleted: true,
    });

    return onboarding;
  };

export const getOnboardingService =
  async (userId) => {
    return await Onboarding.findOne({
      userId,
    });
  };