import { Router } from "express";
import { miniTripRouter } from "./miniTrip";
import { hourlyRentalRouter } from "./hourlyRental";
import { airportRouter } from "./airport";
import { authRouter } from "./auth";
import { userRouter } from "./user";
import { locationRouter } from "./location";
import { bookingsRouter } from "./bookings";

export const mobileRouter = Router();

mobileRouter.use("/mini-trip", miniTripRouter);
mobileRouter.use("/hourly-rental", hourlyRentalRouter);
mobileRouter.use("/airport", airportRouter);
mobileRouter.use("/auth", authRouter);
mobileRouter.use("/user", userRouter);
mobileRouter.use("/location", locationRouter);
mobileRouter.use("/", bookingsRouter); // Bookings routes at root level
