import {
  getProfileService,
  updateProfileService,
} from "./profile.service.js";

export const getProfile = async (
  req,
  res,
  next
) => {
  try {
    const user = await getProfileService(
      req.user.id
    );

    return res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    next(error);
  }
};

export const updateProfile = async (
  req,
  res,
  next
) => {
  try {
    const user =
      await updateProfileService(
        req.user.id,
        req.body
      );

    return res.status(200).json({
      success: true,
      message:
        "Profile updated successfully",
      data: user,
    });
  } catch (error) {
    next(error);
  }
};