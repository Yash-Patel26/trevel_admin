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
exports.uploadMultiple = exports.uploadSingle = exports.upload = exports.s3Client = void 0;
exports.uploadToS3 = uploadToS3;
exports.deleteFromS3 = deleteFromS3;
exports.getSignedUrlForKey = getSignedUrlForKey;
const multer_1 = __importDefault(require("multer"));
const client_s3_1 = require("@aws-sdk/client-s3");
const s3_request_presigner_1 = require("@aws-sdk/s3-request-presigner");
const env_1 = require("../config/env");
// Configure S3 Client for Standard S3
exports.s3Client = new client_s3_1.S3Client({
    region: env_1.env.aws.region,
    credentials: {
        accessKeyId: env_1.env.aws.accessKeyId,
        secretAccessKey: env_1.env.aws.secretAccessKey,
    },
});
// Use memory storage instead of multer-s3
const storage = multer_1.default.memoryStorage();
// File filter for images only
const fileFilter = (_req, file, cb) => {
    const allowedMimes = ["image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif", "application/pdf"];
    if (allowedMimes.includes(file.mimetype)) {
        cb(null, true);
    }
    else {
        cb(new Error("Invalid file type. Only images (JPEG, PNG, WEBP, GIF) and PDFs are allowed."));
    }
};
// Configure multer
exports.upload = (0, multer_1.default)({
    storage,
    fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024, // 5MB limit
    },
});
// Single file upload middleware
exports.uploadSingle = exports.upload.single("image");
// Multiple files upload middleware
exports.uploadMultiple = exports.upload.array("images", 10);
// Helper function to upload buffer to S3 with entity-based folder organization
// Structure: {entityType}/{entityId}/{documentType}/file.ext
// Example: drivers/9876543210/PAN_Card/pan_image.jpg
async function uploadToS3(buffer, filename, mimetype, entityType, // e.g., "drivers", "vehicles"
entityId, // e.g., mobile number or vehicle ID
documentType // e.g., "PAN_Card", "Aadhar_Card", "Driving_License", "Police_Verification"
) {
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    const safeName = filename.replace(/[^a-zA-Z0-9.-]/g, "_");
    // Organize files by entity type, ID, and document type if provided
    // Example: drivers/9876543210/PAN_Card/1234567890-pan.jpg
    let key;
    if (entityType && entityId && documentType) {
        key = `${entityType}/${entityId}/${documentType}/${uniqueSuffix}-${safeName}`;
    }
    else if (entityType && entityId) {
        key = `${entityType}/${entityId}/${uniqueSuffix}-${safeName}`;
    }
    else {
        key = `uploads/${uniqueSuffix}-${safeName}`;
    }
    await exports.s3Client.send(new client_s3_1.PutObjectCommand({
        Bucket: env_1.env.aws.bucketName,
        Key: key,
        Body: buffer,
        ContentType: mimetype,
    }));
    // Construct the S3 URL
    const location = `https://${env_1.env.aws.bucketName}.s3.${env_1.env.aws.region}.amazonaws.com/${key}`;
    // Generate short-lived signed URL for client access
    const signedUrl = await (0, s3_request_presigner_1.getSignedUrl)(exports.s3Client, new client_s3_1.GetObjectCommand({
        Bucket: env_1.env.aws.bucketName,
        Key: key,
    }), { expiresIn: 900 } // 15 minutes
    );
    return { location, key, signedUrl };
}
/**
 * Delete a file from S3
 */
async function deleteFromS3(key) {
    const { DeleteObjectCommand } = await Promise.resolve().then(() => __importStar(require("@aws-sdk/client-s3")));
    await exports.s3Client.send(new DeleteObjectCommand({
        Bucket: env_1.env.aws.bucketName,
        Key: key,
    }));
}
// Helper to create a signed URL for an existing key
async function getSignedUrlForKey(key, expiresInSeconds = 900) {
    return (0, s3_request_presigner_1.getSignedUrl)(exports.s3Client, new client_s3_1.GetObjectCommand({
        Bucket: env_1.env.aws.bucketName,
        Key: key,
    }), { expiresIn: expiresInSeconds });
}
