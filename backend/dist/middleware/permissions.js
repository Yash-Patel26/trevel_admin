"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requirePermissions = requirePermissions;
function requirePermissions(perms) {
    return (req, res, next) => {
        const user = req.user;
        if (!user?.permissions) {
            return res.status(403).json({ message: "Forbidden" });
        }
        const missing = perms.filter((p) => !user.permissions.includes(p));
        if (missing.length) {
            return res.status(403).json({ message: `Missing permissions: ${missing.join(", ")}` });
        }
        return next();
    };
}
