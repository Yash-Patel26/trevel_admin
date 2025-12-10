import { Router } from "express";
import { s3Client } from "../middleware/upload";
import { PutObjectCommand } from "@aws-sdk/client-s3";
import { env } from "../config/env";

const router = Router();

// Create S3 folder for driver
router.post("/s3/create-folder", async (req, res) => {
    try {
        const { mobile } = req.body;
        console.log("Received request to create S3 folder for mobile:", mobile);


        if (!mobile) {
            return res.status(400).json({ message: "Mobile number is required" });
        }

        // Create a folder by uploading an empty object with a trailing slash
        // S3 doesn't have real folders, but this creates the appearance of one
        const folderKey = `drivers/${mobile}/`;

        await s3Client.send(new PutObjectCommand({
            Bucket: env.aws.bucketName,
            Key: folderKey,
            Body: Buffer.from(''),
            ContentType: 'application/x-directory',
        }));

        return res.json({
            message: "Folder created successfully",
            folderPath: folderKey
        });
    } catch (error) {
        console.error("Error creating S3 folder:", error);
        return res.status(500).json({
            message: "Failed to create folder",
            error: String(error)
        });
    }
});

export default router;
