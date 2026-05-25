import express from "express";

import cors from "cors";

import path from "path";

import routes from "./routes/index.js";

import errorMiddleware from "./middleware/error.middleware.js";

const app = express();

app.use(cors());

app.use(express.json());

app.use(express.urlencoded({ extended: true }));

app.use(
  "/uploads",
  express.static(
    path.join(process.cwd(), "uploads")
  )
);

app.use("/api", routes);

app.use(errorMiddleware);

export default app;