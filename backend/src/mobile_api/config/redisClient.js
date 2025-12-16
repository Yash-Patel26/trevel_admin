const redis = require('redis');
require('dotenv').config();
let client = null;
let isRedisAvailable = false;
if (process.env.REDIS_HOST) {
try {
client = redis.createClient({
host: process.env.REDIS_HOST || 'localhost',
port: parseInt(process.env.REDIS_PORT) || 6379,
password: process.env.REDIS_PASSWORD || undefined,
socket: {
connectTimeout: 5000,
reconnectStrategy: (retries) => {
if (retries > 10) {
return new Error('Max reconnection attempts reached');
}
return Math.min(retries * 100, 3000);
}
}
});
client.on('error', (err) => {
isRedisAvailable = false;
});
client.on('connect', () => {
isRedisAvailable = true;
});
client.on('ready', () => {
isRedisAvailable = true;
});
client.on('reconnecting', () => {
isRedisAvailable = false;
});
if (!client.isOpen) {
client.connect().catch((err) => {
isRedisAvailable = false;
});
}
} catch (error) {
isRedisAvailable = false;
}
}
const isAvailable = () => {
return isRedisAvailable && client && client.isOpen;
};
const getClient = () => {
return isAvailable() ? client : null;
};
const set = async (key, value, ttlSeconds = null) => {
if (!isAvailable()) {
return false;
}
try {
if (ttlSeconds) {
await client.setEx(key, ttlSeconds, value);
} else {
await client.set(key, value);
}
return true;
} catch (error) {
return false;
}
};
const get = async (key) => {
if (!isAvailable()) {
return null;
}
try {
const value = await client.get(key);
return value;
} catch (error) {
return null;
}
};
const del = async (key) => {
if (!isAvailable()) {
return false;
}
try {
await client.del(key);
return true;
} catch (error) {
return false;
}
};
const exists = async (key) => {
if (!isAvailable()) {
return false;
}
try {
const result = await client.exists(key);
return result === 1;
} catch (error) {
return false;
}
};
const close = async () => {
if (client && client.isOpen) {
await client.quit();
isRedisAvailable = false;
}
};
module.exports = {
getClient,
isAvailable,
set,
get,
del,
exists,
close
};
