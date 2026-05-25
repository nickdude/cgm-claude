import {
  submitOnboardingService,
  getOnboardingService,
} from "./onboarding.service.js";

export const submitOnboarding =
  async (req, res, next) => {
    try {
      const data =
        await submitOnboardingService(
          req.user.id,
          req.body
        );

      return res.status(200).json({
        success: true,
        message:
          "Onboarding completed",
        data,
      });
    } catch (error) {
      next(error);
    }
  };

export const getOnboarding = async (
  req,
  res,
  next
) => {
  try {
    const data =
      await getOnboardingService(
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