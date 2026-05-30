import {
  googleLoginService,
  facebookLoginService,
  appleLoginService,
} from "./socialAuth.service.js";

export const googleLogin = async (
  req,
  res,
  next
) => {
  try {
    const response =
      await googleLoginService(
        req.body.idToken
      );

    return res.status(200).json({
      success: true,
      data: response,
    });
  } catch (error) {
    next(error);
  }
};

export const facebookLogin = async (
  req,
  res,
  next
) => {
  try {
    const response =
      await facebookLoginService(
        req.body.accessToken
      );

    return res.status(200).json({
      success: true,
      data: response,
    });
  } catch (error) {
    next(error);
  }
};

export const appleLogin = async (
  req,
  res,
  next
) => {
  try {
    const response =
      await appleLoginService(
        req.body.identityToken
      );

    return res.status(200).json({
      success: true,
      data: response,
    });
  } catch (error) {
    next(error);
  }
};