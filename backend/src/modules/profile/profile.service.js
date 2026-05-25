import User from "../auth/auth.model.js";
import fs from "fs";
import path from "path";

const removeOldUploadIfNeeded = (
  previousPath,
  nextPath
) => {
  if (
    !previousPath ||
    previousPath === nextPath ||
    !previousPath.startsWith("/uploads/")
  ) {
    return;
  }

  const absolutePath = path.join(
    process.cwd(),
    previousPath.replace(/^\//, "")
  );

  if (fs.existsSync(absolutePath)) {
    fs.unlinkSync(absolutePath);
  }
};

export const getProfileService = async (
  userId
) => {
  return await User.findById(userId)
    .select("-password")
    .populate("activeDeviceId");
};

export const updateProfileService =
  async (userId, payload) => {
    const existingUser = await User.findById(
      userId
    ).select("profileImage");

    const updates = {
      isProfileCompleted: true,
    };

    if (payload.fullName !== undefined) {
      updates.fullName = payload.fullName;
    }

    if (payload.profileImage !== undefined) {
      updates.profileImage = payload.profileImage;
    }

    if (payload.phoneNumber !== undefined) {
      updates.phoneNumber = payload.phoneNumber;
    }

    const user = await User.findByIdAndUpdate(
      userId,
      updates,
      {
        new: true,
      }
    ).select("-password");

    if (
      existingUser &&
      updates.profileImage !== undefined
    ) {
      removeOldUploadIfNeeded(
        existingUser.profileImage,
        updates.profileImage
      );
    }

    return user;
  };