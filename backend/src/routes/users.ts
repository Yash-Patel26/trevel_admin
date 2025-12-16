import { Router } from "express";
import { Prisma } from "@prisma/client";
import bcrypt from "bcrypt";
import prisma from "../prisma/client";
import { authMiddleware } from "../middleware/auth";
import { requirePermissions } from "../middleware/permissions";
import { logAudit } from "../utils/audit";
import { validateBody } from "../validation/validate";
import { z } from "zod";
import { getPagination } from "../utils/pagination";

export const usersRouter = Router();

usersRouter.use("/users", authMiddleware);

const userCreateSchema = z.object({
  email: z.string().email(),
  fullName: z.string().min(1),
  password: z.string().min(6),
  roleId: z.number(),
  isActive: z.boolean().optional().default(true),
});

const userUpdateSchema = z.object({
  email: z.string().email().optional(),
  fullName: z.string().min(1).optional(),
  password: z.string().min(6).optional(),
  roleId: z.number().optional(),
  isActive: z.boolean().optional(),
});

usersRouter.post(
  "/users",
  requirePermissions(["user:create"]),
  validateBody(userCreateSchema),
  async (req, res) => {
    const { email, fullName, password, roleId, isActive } = req.body;
    try {
      const passwordHash = await bcrypt.hash(password, 10);
      const user = await prisma.user.create({
        data: {
          email,
          fullName,
          passwordHash,
          roleId,
          isActive: isActive ?? true,
        },
        include: { role: true },
      });
      await logAudit({
        actorId: req.user?.id,
        action: "user:create",
        entityType: "user",
        entityId: String(user.id),
        after: { ...user, passwordHash: undefined },
      });
      const { passwordHash: _, ...userWithoutPassword } = user;
      return res.json(userWithoutPassword);
    } catch (err: any) { // eslint-disable-line @typescript-eslint/no-explicit-any
      if (err.code === "P2002") {
        return res.status(400).json({ message: "Email already exists" });
      }
      return res.status(400).json({ message: "Unable to create user" });
    }
  }
);

usersRouter.get(
  "/users",
  requirePermissions(["user:view"]),
  async (req, res) => {
    const { skip, take, page, pageSize } = getPagination(req.query);
    const { search, roleId, isActive } = req.query;
    const where = {
      roleId: roleId ? Number(roleId) : undefined,
      isActive: isActive !== undefined ? isActive === "true" : undefined,
      OR: search
        ? [
          { email: { contains: String(search), mode: Prisma.QueryMode.insensitive } },
          { fullName: { contains: String(search), mode: Prisma.QueryMode.insensitive } },
        ]
        : undefined,
    };
    const [users, total] = await Promise.all([
      prisma.user.findMany({
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
      prisma.user.count({ where }),
    ]);
    return res.json({ data: users, page, pageSize, total });
  }
);

usersRouter.get(
  "/users/:id",
  requirePermissions(["user:view"]),
  async (req, res) => {
    const id = Number(req.params.id);
    const user = await prisma.user.findUnique({
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
    if (!user) return res.status(404).json({ message: "Not found" });
    return res.json(user);
  }
);

usersRouter.patch(
  "/users/:id",
  requirePermissions(["user:update"]),
  validateBody(userUpdateSchema),
  async (req, res) => {
    const id = Number(req.params.id);
    const { email, fullName, password, roleId, isActive } = req.body;
    const existing = await prisma.user.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ message: "Not found" });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const updateData: any = {};
    if (email !== undefined) updateData.email = email;
    if (fullName !== undefined) updateData.fullName = fullName;
    if (roleId !== undefined) updateData.roleId = roleId;
    if (isActive !== undefined) updateData.isActive = isActive;
    if (password !== undefined) {
      updateData.passwordHash = await bcrypt.hash(password, 10);
    }

    const updated = await prisma.user.update({
      where: { id },
      data: updateData,
      include: { role: true },
    });
    await logAudit({
      actorId: req.user?.id,
      action: "user:update",
      entityType: "user",
      entityId: String(id),
      before: { ...existing, passwordHash: undefined },
      after: { ...updated, passwordHash: undefined },
    });
    const { passwordHash: _, ...userWithoutPassword } = updated;
    return res.json(userWithoutPassword);
  }
);

usersRouter.delete(
  "/users/:id",
  requirePermissions(["user:delete"]),
  async (req, res) => {
    const id = Number(req.params.id);
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) return res.status(404).json({ message: "Not found" });
    if (id === req.user?.id) {
      return res.status(400).json({ message: "Cannot delete yourself" });
    }
    await prisma.user.delete({ where: { id } });
    await logAudit({
      actorId: req.user?.id,
      action: "user:delete",
      entityType: "user",
      entityId: String(id),
      before: { ...user, passwordHash: undefined },
    });
    return res.json({ message: "User deleted" });
  }
);

