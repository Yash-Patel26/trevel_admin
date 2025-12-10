const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function resetAndSeed() {
    try {
        console.log('🗑️  Deleting all data...');

        // Delete in correct order (child tables first to avoid foreign key constraints)
        await prisma.ticketUpdate.deleteMany({});
        await prisma.ticket.deleteMany({});
        await prisma.notification.deleteMany({});
        await prisma.rideSummary.deleteMany({});
        await prisma.booking.deleteMany({});
        await prisma.customer.deleteMany({});
        await prisma.driverDocument.deleteMany({});
        await prisma.driverLog.deleteMany({});
        await prisma.driverBackgroundCheck.deleteMany({});
        await prisma.driverTrainingAssignment.deleteMany({});
        await prisma.vehicleAssignment.deleteMany({});
        await prisma.driver.deleteMany({});
        await prisma.vehicleLog.deleteMany({});
        await prisma.vehicleReview.deleteMany({});
        await prisma.vehicle.deleteMany({});
        await prisma.refreshToken.deleteMany({});
        await prisma.auditLog.deleteMany({});
        await prisma.user.deleteMany({});
        await prisma.rolePermission.deleteMany({});
        await prisma.permission.deleteMany({});
        await prisma.role.deleteMany({});

        console.log('✅ All data deleted successfully!');
        console.log('');
        console.log('🌱 Seeding database...');

        // Create Permissions
        const permissions = await Promise.all([
            prisma.permission.create({ data: { name: 'driver:view', description: 'View drivers' } }),
            prisma.permission.create({ data: { name: 'driver:create', description: 'Create drivers' } }),
            prisma.permission.create({ data: { name: 'driver:edit', description: 'Edit drivers' } }),
            prisma.permission.create({ data: { name: 'driver:delete', description: 'Delete drivers' } }),
            prisma.permission.create({ data: { name: 'driver:verify', description: 'Verify driver background' } }),
            prisma.permission.create({ data: { name: 'driver:approve', description: 'Approve drivers' } }),
            prisma.permission.create({ data: { name: 'driver:assign', description: 'Assign vehicles to drivers' } }),
            prisma.permission.create({ data: { name: 'driver:train', description: 'Assign training to drivers' } }),
            prisma.permission.create({ data: { name: 'driver:logs', description: 'View driver logs' } }),
            prisma.permission.create({ data: { name: 'vehicle:view', description: 'View vehicles' } }),
            prisma.permission.create({ data: { name: 'vehicle:create', description: 'Create vehicles' } }),
            prisma.permission.create({ data: { name: 'vehicle:edit', description: 'Edit vehicles' } }),
            prisma.permission.create({ data: { name: 'vehicle:delete', description: 'Delete vehicles' } }),
            prisma.permission.create({ data: { name: 'vehicle:assign', description: 'Assign vehicles' } }),
            prisma.permission.create({ data: { name: 'ticket:view', description: 'View tickets' } }),
            prisma.permission.create({ data: { name: 'ticket:create', description: 'Create tickets' } }),
            prisma.permission.create({ data: { name: 'ticket:edit', description: 'Edit tickets' } }),
            prisma.permission.create({ data: { name: 'ticket:delete', description: 'Delete tickets' } }),
            prisma.permission.create({ data: { name: 'user:view', description: 'View users' } }),
            prisma.permission.create({ data: { name: 'user:create', description: 'Create users' } }),
            prisma.permission.create({ data: { name: 'user:edit', description: 'Edit users' } }),
            prisma.permission.create({ data: { name: 'user:delete', description: 'Delete users' } }),
        ]);

        console.log(`✓ Created ${permissions.length} permissions`);

        // Create Roles
        const superAdminRole = await prisma.role.create({
            data: { name: 'Super Admin', description: 'Full system access' }
        });

        const operationalAdminRole = await prisma.role.create({
            data: { name: 'Operational Admin', description: 'Manage operations' }
        });

        const driverAdminRole = await prisma.role.create({
            data: { name: 'Driver Admin', description: 'Manage drivers' }
        });

        const teamRole = await prisma.role.create({
            data: { name: 'Team', description: 'Team member access' }
        });

        const driverIndividualRole = await prisma.role.create({
            data: { name: 'Driver Individual', description: 'Individual driver access' }
        });

        console.log('✓ Created 5 roles');

        // Assign all permissions to Super Admin
        for (const permission of permissions) {
            await prisma.rolePermission.create({
                data: {
                    roleId: superAdminRole.id,
                    permissionId: permission.id,
                },
            });
        }

        // Assign driver and vehicle permissions to Operational Admin
        const operationalPermissions = permissions.filter(p =>
            p.name.startsWith('driver:') || p.name.startsWith('vehicle:') || p.name.startsWith('ticket:')
        );
        for (const permission of operationalPermissions) {
            await prisma.rolePermission.create({
                data: {
                    roleId: operationalAdminRole.id,
                    permissionId: permission.id,
                },
            });
        }

        // Assign driver permissions to Driver Admin
        const driverPermissions = permissions.filter(p => p.name.startsWith('driver:'));
        for (const permission of driverPermissions) {
            await prisma.rolePermission.create({
                data: {
                    roleId: driverAdminRole.id,
                    permissionId: permission.id,
                },
            });
        }

        // Assign view permissions to Team
        const teamPermissions = permissions.filter(p =>
            p.name === 'driver:view' || p.name === 'driver:approve' || p.name === 'vehicle:view'
        );
        for (const permission of teamPermissions) {
            await prisma.rolePermission.create({
                data: {
                    roleId: teamRole.id,
                    permissionId: permission.id,
                },
            });
        }

        // Assign limited permissions to Driver Individual
        const driverIndividualPermissions = permissions.filter(p =>
            p.name === 'driver:view' || p.name === 'driver:create' || p.name === 'driver:edit'
        );
        for (const permission of driverIndividualPermissions) {
            await prisma.rolePermission.create({
                data: {
                    roleId: driverIndividualRole.id,
                    permissionId: permission.id,
                },
            });
        }

        console.log('✓ Assigned permissions to roles');

        // Create default Super Admin user
        const bcrypt = require('bcrypt');
        const hashedPassword = await bcrypt.hash('admin123', 10);

        const superAdmin = await prisma.user.create({
            data: {
                email: 'admin@trevel.com',
                fullName: 'Super Admin',
                passwordHash: hashedPassword,
                isActive: true,
                roleId: superAdminRole.id,
            },
        });

        console.log('✓ Created Super Admin user (email: admin@trevel.com, password: admin123)');

        console.log('');
        console.log('✅ Database reset and seeded successfully!');
        console.log('');
        console.log('📝 Login credentials:');
        console.log('   Email: admin@trevel.com');
        console.log('   Password: admin123');
        console.log('');

    } catch (error) {
        console.error('❌ Error resetting database:', error);
        throw error;
    } finally {
        await prisma.$disconnect();
    }
}

resetAndSeed()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    });
