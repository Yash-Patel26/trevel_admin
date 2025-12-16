const CLIENT_USER_MAP = new Map();
let GLOBAL_USER_ID = null;
const resolveClientKey = (req) => {
if (!req) return null;
const forwarded = req.headers?.['x-forwarded-for'];
if (forwarded) {
return forwarded.split(',')[0].trim();
}
return req.ip || req.connection?.remoteAddress || null;
};
const setUserForRequest = (req, userId) => {
if (!userId) return;
GLOBAL_USER_ID = userId;
const key = resolveClientKey(req);
if (!key) return;
CLIENT_USER_MAP.set(key, userId);
};
const getUserForRequest = (req) => {
const key = resolveClientKey(req);
if (!key) return null;
return CLIENT_USER_MAP.get(key) || null;
};
const getGlobalUserId = () => GLOBAL_USER_ID;
module.exports = {
setUserForRequest,
getUserForRequest,
getGlobalUserId
};
