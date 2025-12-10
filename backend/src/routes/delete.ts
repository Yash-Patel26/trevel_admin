import { Router } from "express";
import { deleteFromS3 } from "../middleware/upload";

const router = Router();

// Delete file from S3
router.delete("/upload/delete", async (req, res) => {
    try {
        const { key } = req.body;

        if (!key) {
            return res.status(400).json({ message: "S3 key is required" });
        }

        await deleteFromS3(key);

        return res.json({ message: "File deleted successfully" });
    } catch (error) {
        console.error("Error deleting file from S3:", error);
        return res.status(500).json({
            message: "Failed to delete file",
            error: String(error)
        });
    }
});

export default router;
