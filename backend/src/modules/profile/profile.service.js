import User from "../auth/auth.model.js";

export const getProfileService = async (
  userId
) => {
  return await User.findById(userId)
    .select("-password")
    .populate("activeDeviceId");
};

export const updateProfileService =
  async (userId, payload) => {
    const user = await User.findByIdAndUpdate(
      userId,
      {
        fullName: payload.fullName,
        profileImage:
          payload.profileImage,

        isProfileCompleted: true,
      },
      {
        new: true,
      }
    ).select("-password");

    return user;
  };