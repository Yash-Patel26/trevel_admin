import prisma from "../prisma/client";

export async function logAudit(params: {
  actorId?: number;
  action: string;
  entityType: string;
  entityId?: string;
  before?: unknown;
  after?: unknown;
}) {
  await prisma.auditLog.create({
    data: {
      actorId: params.actorId,
      action: params.action,
      entityType: params.entityType,
      entityId: params.entityId,
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      before: params.before as any,
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      after: params.after as any,
    },
  });
}

