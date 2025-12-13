import prisma from "../prisma/client";

export async function logVehicleAction(params: {
  vehicleId: string;
  actorId?: number;
  action: string;
  payload?: unknown;
}) {
  await prisma.vehicleLog.create({
    data: {
      vehicleId: params.vehicleId,
      actorId: params.actorId,
      action: params.action,
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      payload: params.payload as any,
    },
  });
}

export async function logDriverAction(params: {
  driverId: string;
  actorId?: number;
  action: string;
  payload?: unknown;
}) {
  await prisma.driverLog.create({
    data: {
      driverId: params.driverId,
      actorId: params.actorId,
      action: params.action,
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      payload: params.payload as any,
    },
  });
}
