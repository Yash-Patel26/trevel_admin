import { createClient } from "redis";
import { env } from "./env";

const redisClient = createClient({
    url: env.redisUrl,
});

redisClient.on("error", (err) => console.error("Redis Client Error", err));

(async () => {
    if (process.env.ENABLE_REDIS !== "false") {
        try {
            await redisClient.connect();
            console.log("Redis connection established successfully");
        } catch (e) {
            console.error("Failed to connect to Redis:", e);
        }
    }
})();

export default redisClient;
