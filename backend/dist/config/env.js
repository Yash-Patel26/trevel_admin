"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.env = void 0;
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
exports.env = {
    port: parseInt(process.env.PORT || "4000", 10),
    jwtSecret: process.env.JWT_SECRET || "change-me",
    databaseUrl: process.env.DATABASE_URL || "postgres://user:pass@localhost:5432/trevel_admin",
    environment: process.env.NODE_ENV || "development",
    corsOrigins: (process.env.CORS_ORIGINS || "*").split(","),
    aws: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
        region: process.env.AWS_REGION || "ap-south-1",
        bucketName: process.env.AWS_BUCKET_NAME || "",
    },
};
