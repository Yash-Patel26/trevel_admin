
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { env } from "../config/env";
import * as path from 'path';
import * as dotenv from 'dotenv';

// Use same env config logic as app
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const s3 = new S3Client({
    region: process.env.AWS_REGION || "ap-south-1",
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
    },
});

async function testUpload() {
    const bucket = process.env.AWS_BUCKET_NAME;
    const key = `test-upload-${Date.now()}.txt`;

    console.log(`Attempting upload to Bucket: ${bucket}, Key: ${key}, Region: ${process.env.AWS_REGION}`);

    try {
        const start = Date.now();
        await s3.send(new PutObjectCommand({
            Bucket: bucket,
            Key: key,
            Body: "Hello S3 Express!",
            ContentType: "text/plain",
        }));
        console.log(`Success! Upload took ${Date.now() - start}ms`);
        console.log(`File URL (approx): https://${bucket}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`);
    } catch (err: any) {
        console.error("Upload Failed!");
        console.error("Error Name:", err.name);
        console.error("Error Code:", err.code);
        console.error("Error Message:", err.message);
        if (err.$metadata) {
            console.error("Metadata:", JSON.stringify(err.$metadata, null, 2));
        }
    }
}

testUpload();
