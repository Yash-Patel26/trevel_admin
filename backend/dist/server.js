"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.app = void 0;
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const pino_1 = __importDefault(require("pino"));
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
const routes_1 = require("./routes");
const env_1 = require("./config/env");
exports.app = (0, express_1.default)();
const logger = (0, pino_1.default)();
// CORS configuration - handle wildcard properly
const corsOptions = {
    origin: env_1.env.corsOrigins.includes('*') ? true : env_1.env.corsOrigins,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
};
exports.app.use((0, cors_1.default)(corsOptions));
exports.app.use(express_1.default.json());
// Ensure uploads directory exists and serve static files
const uploadsPath = path_1.default.join(process.cwd(), "uploads");
if (!fs_1.default.existsSync(uploadsPath)) {
    fs_1.default.mkdirSync(uploadsPath, { recursive: true });
}
exports.app.use("/uploads", express_1.default.static(uploadsPath));
// Mount admin API routes
exports.app.use(routes_1.apiRouter);
exports.app.use((err, _req, res, _next) => {
    logger.error({ err }, "Unhandled error");
    res.status(500).json({ message: "Internal server error" });
});
if (process.env.JEST_WORKER_ID === undefined) {
    exports.app.listen(env_1.env.port, async () => {
        logger.info(`API running on port ${env_1.env.port}`);
        try {
            // Import dynamically to avoid top-level await issues if any, 
            // though static import is fine here given the structure.
            // Better to use the one we'll import at top
            const { default: prisma } = await Promise.resolve().then(() => __importStar(require("./prisma/client")));
            await prisma.$connect();
            logger.info("Database connection established successfully");
            // Start scheduled jobs
            const { startScheduledJobs, startTodayBookingsUpdater } = await Promise.resolve().then(() => __importStar(require("./services/scheduler")));
            startScheduledJobs();
            startTodayBookingsUpdater();
            logger.info("Scheduled jobs initialized");
        }
        catch (err) {
            logger.error({ err }, "Failed to connect to database or start scheduled jobs");
            // Don't exit process strictly, let it retry or fail on request, 
            // but logging is crucial.
        }
    });
}
