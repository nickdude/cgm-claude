import { OAuth2Client } from "google-auth-library";

import axios from "axios";

import appleSigninAuth from "apple-signin-auth";

import User from "./auth.model.js";

import generateToken from "../../utils/generateToken.js";

const googleClient = new OAuth2Client(
  process.env.GOOGLE_CLIENT_ID
);

export const googleLoginService =
  async (idToken) => {
    const ticket =
      await googleClient.verifyIdToken({
        idToken,
        audience:
          process.env.GOOGLE_CLIENT_ID,
      });

    const payload = ticket.getPayload();

    let user = await User.findOne({
      email: payload.email,
    });

    if (!user) {
      user = await User.create({
        fullName: payload.name,
        email: payload.email,
        profileImage: payload.picture,
        provider: "google",
        providerId: payload.sub,
        isEmailVerified: true,
      });
    }

    const token = generateToken({
      id: user._id,
    });

    return {
      token,
      user,
    };
  };

export const facebookLoginService =
  async (accessToken) => {
    const response = await axios.get(
      `https://graph.facebook.com/me?fields=id,name,email,picture&access_token=${accessToken}`
    );

    const data = response.data;

    let user = await User.findOne({
      email: data.email,
    });

    if (!user) {
      user = await User.create({
        fullName: data.name,
        email: data.email,
        profileImage:
          data.picture?.data?.url || "",
        provider: "facebook",
        providerId: data.id,
        isEmailVerified: true,
      });
    }

    const token = generateToken({
      id: user._id,
    });

    return {
      token,
      user,
    };
  };

export const appleLoginService =
  async (identityToken) => {
    const appleUser =
      await appleSigninAuth.verifyIdToken(
        identityToken,
        {
          audience:
            process.env.APPLE_CLIENT_ID,
          ignoreExpiration: false,
        }
      );

    let user = await User.findOne({
      email: appleUser.email,
    });

    if (!user) {
      user = await User.create({
        fullName: "Apple User",
        email: appleUser.email,
        provider: "apple",
        providerId: appleUser.sub,
        isEmailVerified: true,
      });
    }

    const token = generateToken({
      id: user._id,
    });

    return {
      token,
      user,
    };
  };