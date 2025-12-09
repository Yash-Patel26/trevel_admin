"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.usersRouter = void 0;
const express_1 = require("express");
const client_1 = require("@prisma/client");
const bcrypt_1 = __importDefault(require("bcrypt"));
const client_2 = __importDefault(require("../prisma/client"));
const auth_1 = require("../middleware/auth");
const permissions_1 = require("../middleware/permissions");
const audit_1 = require("../utils/audit");
const validate_1 = require("../validation/validate");
const zod_1 = require("zod");
const pagination_1 = require("../utils/pagination");
exports.usersRouter = (0, express_1.Router)();
exports.usersRouter.use(auth_1.authMiddleware);
const userCreateSchema = zod_1.z.object({
    email: zod_1.z.string().email(),
    fullName: zod_1.z.string().min(1),
    password: zod_1.z.string().min(6),
    roleId: zod_1.z.number(),
    isActive: zod_1.z.boolean().optional().default(true),
});
const userUpdateSchema = zod_1.z.object({
    email: zod_1.z.string().email().optional(),
    fullName: zod_1.z.string().min(1).optional(),
    password: zod_1.z.string().min(6).optional(),
    roleId: zod_1.z.number().optional(),
    isActive: zod_1.z.boolean().optional(),
});
exports.usersRouter.post("/users", (0, permissions_1.requirePermissions)(["user:create"]), (0, validate_1.validateBody)(userCreateSchema), async (req, res) => {
    const { email, fullName, password, roleId, isActive } = req.body;
    try {
        const passwordHash = await bcrypt_1.default.hash(password, 10);
        const user = await client_2.default.user.create({
            data: {
                email,
                fullName,
                passwordHash,
                roleId,
                isActive: isActive ?? true,
            },
            include: { role: true },
        });
        await (0, audit_1.logAudit)({
            actorId: req.user?.id,
            action: "user:create",
            entityType: "user",
            entityId: String(user.id),
            after: { ...user, passwordHash: undefined },
        });
        const { passwordHash: _, ...userWithoutPassword } = user;
        return res.json(userWithoutPassword);
    }
    catch (err) { // eslint-disable-line @typescript-eslint/no-explicit-any
        if (err.code === "P2002") {
            return res.status(400).json({ message: "Email already exists" });
        }
        return res.status(400).json({ message: "Unable to create user" });
    }
});
exports.usersRouter.get("/users", (0, permissions_1.requirePermissions)(["user:view"]), async (req, res) => {
    const { skip, take, page, pageSize } = (0, pagination_1.getPagination)(req.query);
    const { search, roleId, isActive } = req.query;
    const where = {
        roleId: roleId ? Number(roleId) : undefined,
        isActive: isActive !== undefined ? isActive === "true" : undefined,
        OR: search
            ? [
                { email: { contains: String(search), mode: client_1.Prisma.QueryMode.insensitive } },
                { fullName: { contains: String(search), mode: client_1.Prisma.QueryMode.insensitive } },
            ]
            : undefined,
    };
    const [users, total] = await Promise.all([
        client_2.default.user.findMany({
            where,
            skip,
            take,
            select: {
                id: true,
                email: true,
                fullName: true,
                isActive: true,
                roleId: true,
                role: true,
            },
            orderBy: { id: "desc" },
        }),
        client_2.default.user.count({ where }),
    ]);
    return res.json({ data: users, page, pageSize, total });
});
exports.usersRouter.get("/users/:id", (0, permissions_1.requirePermissions)(["user:view"]), async (req, res) => {
    const id = Number(req.params.id);
    const user = await client_2.default.user.findUnique({
        where: { id },
        select: {
            id: true,
            email: true,
            fullName: true,
            isActive: true,
            roleId: true,
            role: true,
        },
    });
    if (!user)
        return res.status(404).json({ message: "Not found" });
    return res.json(user);
});
exports.usersRouter.patch("/users/:id", (0, permissions_1.requirePermissions)(["user:update"]), (0, validate_1.validateBody)(userUpdateSchema), async (req, res) => {
    const id = Number(req.params.id);
    const { email, fullName, password, roleId, isActive } = req.body;
    const existing = await client_2.default.user.findUnique({ where: { id } });
    if (!existing)
        return res.status(404).json({ message: "Not found" });
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const updateData = {};
    if (email !== undefined)
        updateData.email = email;
    if (fullName !== undefined)
        updateData.fullName = fullName;
    if (roleId !== undefined)
        updateData.roleId = roleId;
    if (isActive !== undefined)
        updateData.isActive = isActive;
    if (password !== undefined) {
        updateData.passwordHash = await bcrypt_1.default.hash(password, 10);
    }
    const updated = await client_2.default.user.update({
        where: { id },
        data: updateData,
        include: { role: true },
    });
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "user:update",
        entityType: "user",
        entityId: String(id),
        before: { ...existing, passwordHash: undefined },
        after: { ...updated, passwordHash: undefined },
    });
    const { passwordHash: _, ...userWithoutPassword } = updated;
    return res.json(userWithoutPassword);
});
exports.usersRouter.delete("/users/:id", (0, permissions_1.requirePermissions)(["user:delete"]), async (req, res) => {
    const id = Number(req.params.id);
    const user = await client_2.default.user.findUnique({ where: { id } });
    if (!user)
        return res.status(404).json({ message: "Not found" });
    if (id === req.user?.id) {
        return res.status(400).json({ message: "Cannot delete yourself" });
    }
    await client_2.default.user.delete({ where: { id } });
    await (0, audit_1.logAudit)({
        actorId: req.user?.id,
        action: "user:delete",
        entityType: "user",
        entityId: String(id),
        before: { ...user, passwordHash: undefined },
    });
    return res.json({ message: "User deleted" });
});
