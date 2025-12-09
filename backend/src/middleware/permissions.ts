import { NextFunction, Request, Response } from "express";

export function requirePermissions(perms: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
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

