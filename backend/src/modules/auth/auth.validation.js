import Joi from "joi";

export const registerValidation = (data) => {
  return Joi.object({
    fullName: Joi.string().required(),

    email: Joi.string().email().required(),

    password: Joi.string().min(6).required(),
  }).validate(data);
};

export const loginValidation = (data) => {
  return Joi.object({
    email: Joi.string().email().required(),

    password: Joi.string().required(),
  }).validate(data);
};