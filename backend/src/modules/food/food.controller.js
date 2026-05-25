import {
  createFoodService,
  getFoodsService,
  deleteFoodService,
} from "./food.service.js";

export const createFood = async (
  req,
  res,
  next
) => {
  try {
    const food =
      await createFoodService(
        req.user.id,
        req.body
      );

    return res.status(201).json({
      success: true,
      message: "Food added",
      data: food,
    });
  } catch (error) {
    next(error);
  }
};

export const getFoods = async (
  req,
  res,
  next
) => {
  try {
    const foods =
      await getFoodsService(req.user.id);

    return res.status(200).json({
      success: true,
      data: foods,
    });
  } catch (error) {
    next(error);
  }
};

export const deleteFood = async (
  req,
  res,
  next
) => {
  try {
    await deleteFoodService(
      req.user.id,
      req.params.id
    );

    return res.status(200).json({
      success: true,
      message: "Food deleted",
    });
  } catch (error) {
    next(error);
  }
};