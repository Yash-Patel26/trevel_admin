import bcrypt from "bcrypt";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

// --- Constants from src/rbac/permissions.ts & roles.ts ---

const PERMISSIONS = [
  "vehicle:create",
  "vehicle:review",
  "vehicle:approve",
  "vehicle:view",
  "vehicle:assign",
  "vehicle:logs",
  "driver:create",
  "driver:verify",
  "driver:train",
  "driver:approve",
  "driver:view",
  "driver:assign",
  "driver:edit",
  "driver:delete",
  "driver:logs",
  "dashboard:view",
  "ticket:create",
  "ticket:view",
  "ticket:update",
  "notifications:manage",
  "reports:view",
  "audit:view",
  "customer:view",
  "customer:create",
  "booking:create",
  "booking:view",
  "booking:assign",
  "booking:update",
  "ride:create",
  "ride:view",
  "ride:update",
  "user:create",
  "user:view",
  "user:update",
  "user:delete",
];

const ROLES: Record<string, string[]> = {
  "Operational Admin": [...PERMISSIONS],
  "Fleet Admin": [
    "vehicle:create",
    "vehicle:review",
    "vehicle:approve",
    "vehicle:logs",
    "vehicle:view",
    "vehicle:assign",
    "dashboard:view",
    "ticket:create",
    "ticket:view",
    "ticket:update",
    "notifications:manage",
    "reports:view",
    "customer:view",
    "booking:view",
    "booking:assign",
    "booking:update",
    "ride:view",
  ],
  "Driver Admin": [
    "driver:create",
    "driver:verify",
    "driver:train",
    "driver:approve",
    "driver:view",
    "driver:assign",
    "driver:edit",
    "driver:delete",
    "driver:logs",
    "vehicle:view",
    "vehicle:assign",
    "dashboard:view",
    "ticket:create",
    "ticket:view",
    "ticket:update",
    "customer:view",
    "booking:view",
    "booking:assign",
    "booking:update",
    "ride:create",
    "ride:view",
    "ride:update",
  ],
  "Driver Individual": [
    "dashboard:view",
    "driver:create",
    "driver:view",
    "driver:edit",
    "ticket:create",
    "ticket:view",
    "ticket:update",
  ],
  "Fleet Individual": [
    "dashboard:view",
    "vehicle:view",
    "ticket:create",
    "ticket:view",
    "ticket:update",
  ],
  "Team": [
    "dashboard:view",
    "ticket:create",
    "ticket:view",
    "ticket:update",
    "booking:create",
    "booking:view",
    "booking:assign",
    "booking:update",
    "ride:create",
    "ride:view",
    "ride:update",
    "customer:view",
    "driver:view",
    "driver:verify",
    "driver:approve",
    "vehicle:view",
    "vehicle:review",
    "vehicle:approve",
    "reports:view",
    "notifications:manage",
  ],
};

// --- Constants from Pricing Seed ---

const MINI_TRAVEL_PRICING = [
  { minKm: 0.1, maxKm: 5, peakBasePrice: 189.52, nonPeakBasePrice: 189.52 },
  { minKm: 5.1, maxKm: 8, peakBasePrice: 284.76, nonPeakBasePrice: 237.14 },
  { minKm: 8.1, maxKm: 12, peakBasePrice: 380.00, nonPeakBasePrice: 284.76 },
  { minKm: 12.1, maxKm: 15, peakBasePrice: 475.24, nonPeakBasePrice: 380.00 },
  { minKm: 15.1, maxKm: 18, peakBasePrice: 570.48, nonPeakBasePrice: 475.24 },
  { minKm: 18.1, maxKm: 21, peakBasePrice: 665.71, nonPeakBasePrice: 570.48 },
  { minKm: 21.1, maxKm: 25, peakBasePrice: 760.95, nonPeakBasePrice: 665.71 },
  { minKm: 25.5, maxKm: 30, peakBasePrice: 856.19, nonPeakBasePrice: 760.95 }
];

const MINI_TRAVEL_BEYOND_30KM = {
  peak: { perKmRate: 25, baseCharge: 299 },
  nonPeak: { perKmRate: 20, baseCharge: 299 }
};

const AIRPORT_PRICING = {
  drop: { basePrice: 951.43, totalPrice: 999 },
  pickup: { basePrice: 1189.52, totalPrice: 1249 }
};

const HOURLY_RENTAL_PRICING = {
  2: { basePrice: 951.43, totalPrice: 999 },
  3: { basePrice: 1427.62, totalPrice: 1499 },
  4: { basePrice: 1903.81, totalPrice: 1999 },
  5: { basePrice: 2380.00, totalPrice: 2499 },
  6: { basePrice: 2856.19, totalPrice: 2999 },
  7: { basePrice: 3332.38, totalPrice: 3499 },
  8: { basePrice: 3808.57, totalPrice: 3999 },
  9: { basePrice: 4284.76, totalPrice: 4499 },
  10: { basePrice: 4760.95, totalPrice: 4999 },
  11: { basePrice: 5237.14, totalPrice: 5499 },
  12: { basePrice: 5713.33, totalPrice: 5999 }
};

const PEAK_HOURS = {
  miniTravel: [
    { start: 8, end: 11 },
    { start: 17, end: 21 }
  ],
  airport: [
    { start: 8, end: 11 },
    { start: 16, end: 22 }
  ]
};

async function main() {
  console.log('Seeding Permissions...');
  const permRecords = await Promise.all(
    PERMISSIONS.map((name) =>
      prisma.permission.upsert({
        where: { name },
        update: {},
        create: { name, description: name },
      })
    )
  );

  console.log('Seeding Roles...');
  for (const [roleName, perms] of Object.entries(ROLES)) {
    const role = await prisma.role.upsert({
      where: { name: roleName },
      update: {},
      create: { name: roleName, description: roleName },
    });
    for (const permName of perms) {
      const perm = permRecords.find((p) => p.name === permName);
      if (perm) {
        await prisma.rolePermission.upsert({
          where: { roleId_permissionId: { roleId: role.id, permissionId: perm.id } },
          update: {},
          create: { roleId: role.id, permissionId: perm.id },
        });
      }
    }
  }

  console.log('Seeding Users...');
  const testUsers = [
    {
      email: "admin@trevel.in",
      password: "112233",
      fullName: "Operational Admin",
      roleName: "Operational Admin",
    },
    {
      email: "fleet@trevel.in",
      password: "112233",
      fullName: "Fleet Admin",
      roleName: "Fleet Admin",
    },
    {
      email: "driver@trevel.in",
      password: "112233",
      fullName: "Driver Admin",
      roleName: "Driver Admin",
    },
    {
      email: "driver-individual@trevel.in",
      password: "112233",
      fullName: "Driver Individual",
      roleName: "Driver Individual",
    },
    {
      email: "fleet-individual@trevel.in",
      password: "112233",
      fullName: "Fleet Individual",
      roleName: "Fleet Individual",
    },
    {
      email: "team@trevel.in",
      password: "112233",
      fullName: "Team Member",
      roleName: "Team",
    },
  ];

  for (const userData of testUsers) {
    const role = await prisma.role.findUnique({ where: { name: userData.roleName } });
    if (role) {
      const passwordHash = await bcrypt.hash(userData.password, 10);
      await prisma.user.upsert({
        where: { email: userData.email },
        update: {
          fullName: userData.fullName,
          passwordHash,
          roleId: role.id,
          isActive: true, // Ensuring existing users are active
        },
        create: {
          email: userData.email,
          fullName: userData.fullName,
          passwordHash,
          roleId: role.id,
          isActive: true,
        },
      });
      console.log(`✓ Created/Updated user: ${userData.email} (${userData.roleName})`);
    }
  }

  console.log('Seeding Pricing Configs...');

  await prisma.pricingConfig.upsert({
    where: { serviceType: 'mini-travel' },
    update: {},
    create: {
      serviceType: 'mini-travel',
      config: {
        tiers: MINI_TRAVEL_PRICING,
        beyond30Km: MINI_TRAVEL_BEYOND_30KM,
        gstRate: 0.05,
        peakHours: PEAK_HOURS.miniTravel
      }
    }
  });

  await prisma.pricingConfig.upsert({
    where: { serviceType: 'airport-drop' },
    update: {},
    create: {
      serviceType: 'airport-drop',
      config: {
        pricing: AIRPORT_PRICING.drop,
        gstRate: 0.05,
        peakHours: PEAK_HOURS.airport
      }
    }
  });

  await prisma.pricingConfig.upsert({
    where: { serviceType: 'airport-pickup' },
    update: {},
    create: {
      serviceType: 'airport-pickup',
      config: {
        pricing: AIRPORT_PRICING.pickup,
        gstRate: 0.05,
        peakHours: PEAK_HOURS.airport
      }
    }
  });

  await prisma.pricingConfig.upsert({
    where: { serviceType: 'hourly-rental' },
    update: {},
    create: {
      serviceType: 'hourly-rental',
      config: {
        packages: HOURLY_RENTAL_PRICING,
        gstRate: 0.05
      }
    }
  });

  console.log('Seeding completed.');
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
