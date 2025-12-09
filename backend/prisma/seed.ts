import bcrypt from "bcrypt";
import { PrismaClient } from "@prisma/client";
import { PERMISSIONS } from "../src/rbac/permissions";
import { ROLES } from "../src/rbac/roles";

const prisma = new PrismaClient();

async function main() {
  // Seed permissions
  const permRecords = await Promise.all(
    PERMISSIONS.map((name) =>
      prisma.permission.upsert({
        where: { name },
        update: {},
        create: { name, description: name },
      })
    )
  );

  // Seed roles and role-permissions
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

  // Seed test users for different roles
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
          isActive: true,
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

