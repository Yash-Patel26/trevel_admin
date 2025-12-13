import prisma from "../prisma/client";

export async function queueNotification(params: {
  actorId?: number;
  targetId?: string | number;
  type: string;
  channel?: string;
  payload?: unknown;
}) {
  await prisma.notification.create({
    data: {
      actorId: params.actorId,
      targetId: params.targetId ? String(params.targetId) : undefined,
      type: params.type,
      channel: params.channel ?? "in-app",
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      payload: params.payload as any,
      status: "queued",
    },
  });
}

