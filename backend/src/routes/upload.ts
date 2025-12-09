import { Router, Request, Response } from "express";
import { authMiddleware } from "../middleware/auth";
import { requirePermissions } from "../middleware/permissions";
import { uploadSingle, uploadMultiple } from "../middleware/upload";

export const uploadRouter = Router();

uploadRouter.use(authMiddleware);

// Single image upload endpoint
uploadRouter.post(
  "/upload",
  requirePermissions(["driver:create", "driver:edit"]),
  async (req: Request, res: Response) => {
    uploadSingle(req, res, async (err) => {
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
        const { uploadToS3 } = await import("../middleware/upload");
        const { location, key } = await uploadToS3(
          req.file.buffer,
          req.file.originalname,
          req.file.mimetype
        );

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
      } catch (s3Error: any) {
        console.error("S3 upload error:", s3Error);
        console.error("S3 error name:", s3Error.name);
        console.error("S3 error message:", s3Error.message);
        return res.status(500).json({ message: "Failed to upload to S3: " + s3Error.message });
      }
    });
  }
);

// Multiple images upload endpoint
uploadRouter.post(
  "/upload/multiple",
  requirePermissions(["driver:create", "driver:edit"]),
  async (req: Request, res: Response) => {
    uploadMultiple(req, res, async (err) => {
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
        const { uploadToS3 } = await import("../middleware/upload");
        const filesArray = Array.isArray(req.files) ? req.files : [];
        
        const uploadedFiles = await Promise.all(
          filesArray.map(async (f: Express.Multer.File) => {
            const { location, key } = await uploadToS3(
              f.buffer,
              f.originalname,
              f.mimetype
            );
            return {
              filename: key,
              originalName: f.originalname,
              mimetype: f.mimetype,
              size: f.size,
              url: location,
              path: key,
            };
          })
        );

        return res.json({
          message: "Files uploaded successfully",
          files: uploadedFiles,
        });
      } catch (s3Error: any) {
        console.error("S3 upload error:", s3Error);
        return res.status(500).json({ message: "Failed to upload to S3: " + s3Error.message });
      }
    });
  }
);
