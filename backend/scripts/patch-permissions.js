
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
    datasources: {
        db: {
            url: "postgresql://postgres:MySuperSecretPassword123!@trevel-db-mumbai.cluster-cros8s2gc0ix.ap-south-1.rds.amazonaws.com:5432/postgres",
        },
    },
});

const PERMISSIONS = [
    "customer:view",
    "customer:create",
];

async function main() {
    console.log("Patching permissions...");

    // 1. Ensure permissions exist
    for (const name of PERMISSIONS) {
        try {
            const perm = await prisma.permission.upsert({
                where: { name },
                update: {},
                create: { name, description: name },
            });
            console.log(`- Ensured permission: ${name} (ID: ${perm.id})`);
        } catch (e) {
            console.error(`Failed to upsert permission ${name}:`, e);
        }
    }

    // 2. Assign to Operational Admin role
    try {
        const adminRole = await prisma.role.findUnique({
            where: { name: "Operational Admin" },
        });

        if (!adminRole) {
            console.error("Operational Admin role not found!");
            return;
        }

        for (const name of PERMISSIONS) {
            const perm = await prisma.permission.findUnique({ where: { name } });
            if (perm) {
                await prisma.rolePermission.upsert({
                    where: {
                        roleId_permissionId: {
                            roleId: adminRole.id,
                            permissionId: perm.id,
                        },
                    },
                    update: {},
                    create: {
                        roleId: adminRole.id,
                        permissionId: perm.id,
                    },
                });
                console.log(`- Assigned ${name} to Operational Admin`);
            }
        }
    } catch (e) {
        console.error("Error managing role permissions:", e);
    }

    console.log("Done!");
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
