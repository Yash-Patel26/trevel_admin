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
const client_s3_1 = require("@aws-sdk/client-s3");
const path = __importStar(require("path"));
const dotenv = __importStar(require("dotenv"));
// Use same env config logic as app
dotenv.config({ path: path.resolve(__dirname, '../../.env') });
const s3 = new client_s3_1.S3Client({
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
        await s3.send(new client_s3_1.PutObjectCommand({
            Bucket: bucket,
            Key: key,
            Body: "Hello S3 Express!",
            ContentType: "text/plain",
        }));
        console.log(`Success! Upload took ${Date.now() - start}ms`);
        console.log(`File URL (approx): https://${bucket}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`);
    }
    catch (err) {
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
