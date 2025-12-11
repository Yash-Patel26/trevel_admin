import express from "express";
import cors from "cors";
import pino from "pino";
import path from "path";
import fs from "fs";
import { apiRouter } from "./routes";
import { env } from "./config/env";

export const app = express();
const logger = pino();

// CORS configuration - handle wildcard properly
const corsOptions = {
  origin: env.corsOrigins.includes('*') ? true : env.corsOrigins,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
};
app.use(cors(corsOptions));
app.use(express.json());

// Ensure uploads directory exists and serve static files
const uploadsPath = path.join(process.cwd(), "uploads");
if (!fs.existsSync(uploadsPath)) {
  fs.mkdirSync(uploadsPath, { recursive: true });
}
app.use("/uploads", express.static(uploadsPath));

// Mount admin API routes
app.use(apiRouter);

app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  logger.error({ err }, "Unhandled error");
  res.status(500).json({ message: "Internal server error" });
});

if (process.env.JEST_WORKER_ID === undefined) {
  app.listen(env.port, async () => {
    logger.info(`API running on port ${env.port}`);

    try {
      // Import dynamically to avoid top-level await issues if any, 
      // though static import is fine here given the structure.
      // Better to use the one we'll import at top
      const { default: prisma } = await import("./prisma/client");
      await prisma.$connect();
      logger.info("Database connection established successfully");

      // Start scheduled jobs
      const { startScheduledJobs, startTodayBookingsUpdater } = await import("./services/scheduler");
      startScheduledJobs();
      startTodayBookingsUpdater();
      logger.info("Scheduled jobs initialized");
    } catch (err) {
      logger.error({ err }, "Failed to connect to database or start scheduled jobs");
      // Don't exit process strictly, let it retry or fail on request, 
      // but logging is crucial.
    }
  });
}

