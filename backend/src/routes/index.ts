
import { Router } from "express";
import { healthRouter } from "./health";
import { authRouter } from "./auth";
import { vehiclesRouter } from "./vehicles";
import { driversRouter } from "./drivers";
import { ticketsRouter } from "./tickets";
import { dashboardsRouter } from "./dashboards";
import { auditRouter } from "./audit";
import { customersRouter } from "./customers";
import { usersRouter } from "./users";
import { rolesRouter } from "./roles";
import { ridesRouter } from "./rides";
import { uploadRouter } from "./upload";
import deleteRouter from "./delete";
import s3Router from "./s3";

export const apiRouter = Router();

apiRouter.use(healthRouter);
apiRouter.use(authRouter);
apiRouter.use(uploadRouter);
apiRouter.use(vehiclesRouter);
apiRouter.use(driversRouter);
apiRouter.use(ticketsRouter);
apiRouter.use(dashboardsRouter);
apiRouter.use(auditRouter);
apiRouter.use(customersRouter);
apiRouter.use(usersRouter);
apiRouter.use(rolesRouter);
apiRouter.use(ridesRouter);
apiRouter.use(deleteRouter);
apiRouter.use(s3Router);