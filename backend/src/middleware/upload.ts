import multer from "multer";
import { S3Client, PutObjectCommand, GetObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { Request } from "express";
import { env } from "../config/env";

// Configure S3 Client for Standard S3
export const s3Client = new S3Client({
  region: env.aws.region,
  credentials: {
    accessKeyId: env.aws.accessKeyId,
    secretAccessKey: env.aws.secretAccessKey,
  },
});

// Use memory storage instead of multer-s3
const storage = multer.memoryStorage();

// File filter for images only
const fileFilter = (_req: Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
  const allowedMimes = ["image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif", "application/pdf"];
  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error("Invalid file type. Only images (JPEG, PNG, WEBP, GIF) and PDFs are allowed."));
  }
};

// Configure multer
export const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
});

// Single file upload middleware
export const uploadSingle = upload.single("image");

// Multiple files upload middleware
export const uploadMultiple = upload.array("images", 10);

// Helper function to upload buffer to S3 with entity-based folder organization
export async function uploadToS3(
  buffer: Buffer,
  filename: string,
  mimetype: string,
  entityType?: string,  // e.g., "drivers", "vehicles"
  entityId?: string     // e.g., driver ID or vehicle ID
): Promise<{ location: string; key: string; signedUrl: string }> {
  const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
  const safeName = filename.replace(/[^a-zA-Z0-9.-]/g, "_");

  // Organize files by entity type and ID if provided
  // Example: drivers/123/1234567890-profile.jpg
  let key: string;
  if (entityType && entityId) {
    key = `${entityType}/${entityId}/${uniqueSuffix}-${safeName}`;
  } else {
    key = `uploads/${uniqueSuffix}-${safeName}`;
  }

  await s3Client.send(new PutObjectCommand({
    Bucket: env.aws.bucketName,
    Key: key,
    Body: buffer,
    ContentType: mimetype,
  }));

  // Construct the S3 URL
  const location = `https://${env.aws.bucketName}.s3.${env.aws.region}.amazonaws.com/${key}`;

  // Generate short-lived signed URL for client access
  const signedUrl = await getSignedUrl(
    s3Client,
    new GetObjectCommand({
      Bucket: env.aws.bucketName,
      Key: key,
    }),
    { expiresIn: 900 } // 15 minutes
  );

  return { location, key, signedUrl };
}

// Helper to create a signed URL for an existing key
export async function getSignedUrlForKey(key: string, expiresInSeconds = 900): Promise<string> {
  return getSignedUrl(
    s3Client,
    new GetObjectCommand({
      Bucket: env.aws.bucketName,
      Key: key,
    }),
    { expiresIn: expiresInSeconds }
  );
}
