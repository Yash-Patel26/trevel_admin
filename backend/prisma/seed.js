const bcrypt = require("bcrypt");
const { PrismaClient } = require("@prisma/client");
const { PERMISSIONS } = require("../dist/src/rbac/permissions");
const { ROLES } = require("../dist/src/rbac/roles");

const prisma = new PrismaClient();

async function main() {
  // Truncate users table first
  console.log('Truncating existing users...');
  await prisma.user.deleteMany({});
  console.log('✓ Users truncated');

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
    // Upsert all permissions for this role (will add new permissions like vehicle:view)
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
      fullName: "Driver Individual User",
      roleName: "Driver Individual",
    },
    {
      email: "fleet-individual@trevel.in",
      password: "112233",
      fullName: "Fleet Individual User",
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

