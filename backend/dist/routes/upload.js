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
Object.defineProperty(exports, "__esModule", { value: true });
exports.uploadRouter = void 0;
const express_1 = require("express");
const auth_1 = require("../middleware/auth");
const upload_1 = require("../middleware/upload");
exports.uploadRouter = (0, express_1.Router)();
exports.uploadRouter.use(auth_1.authMiddleware);
// Single image upload endpoint
exports.uploadRouter.post("/upload", 
// Removed permission check - any authenticated user can upload images
// Permission checks should be done at the entity level (e.g., when creating/editing drivers)
async (req, res) => {
    (0, upload_1.uploadSingle)(req, res, async (err) => {
        if (err) {
            console.error("Upload error:", err);
            console.error("Error name:", err.name);
            console.error("Error message:", err.message);
            console.error("Error stack:", err.stack);
            return res.status(400).json({ message: err.message || "File upload failed" });
        }
        if (!req.file) {
            return res.status(400).json({ message: "No file uploaded" });
        }
        try {
            // Upload to S3 manually
            const { uploadToS3 } = await Promise.resolve().then(() => __importStar(require("../middleware/upload")));
            const { location, key } = await uploadToS3(req.file.buffer, req.file.originalname, req.file.mimetype);
            return res.json({
                message: "File uploaded successfully",
                file: {
                    filename: key,
                    originalName: req.file.originalname,
                    mimetype: req.file.mimetype,
                    size: req.file.size,
                    url: location,
                    path: key,
                },
            });
        }
        catch (s3Error) {
            console.error("S3 upload error:", s3Error);
            console.error("S3 error name:", s3Error.name);
            console.error("S3 error message:", s3Error.message);
            return res.status(500).json({ message: "Failed to upload to S3: " + s3Error.message });
        }
    });
});
// Multiple images upload endpoint
exports.uploadRouter.post("/upload/multiple", 
// Removed permission check - any authenticated user can upload images
async (req, res) => {
    (0, upload_1.uploadMultiple)(req, res, async (err) => {
        if (err) {
            console.error("Multiple upload error:", err);
            console.error("Error name:", err.name);
            console.error("Error message:", err.message);
            console.error("Error stack:", err.stack);
            return res.status(400).json({ message: err.message || "File upload failed" });
        }
        if (!req.files || (Array.isArray(req.files) && req.files.length === 0)) {
            return res.status(400).json({ message: "No files uploaded" });
        }
        try {
            const { uploadToS3 } = await Promise.resolve().then(() => __importStar(require("../middleware/upload")));
            const filesArray = Array.isArray(req.files) ? req.files : [];
            const uploadedFiles = await Promise.all(filesArray.map(async (f) => {
                const { location, key } = await uploadToS3(f.buffer, f.originalname, f.mimetype);
                return {
                    filename: key,
                    originalName: f.originalname,
                    mimetype: f.mimetype,
                    size: f.size,
                    url: location,
                    path: key,
                };
            }));
            return res.json({
                message: "Files uploaded successfully",
                files: uploadedFiles,
            });
        }
        catch (s3Error) {
            console.error("S3 upload error:", s3Error);
            return res.status(500).json({ message: "Failed to upload to S3: " + s3Error.message });
        }
    });
});
