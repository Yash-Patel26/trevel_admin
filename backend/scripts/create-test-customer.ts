import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function createTestCustomer() {
    try {
        // Check if test customer already exists
        const existingCustomer = await prisma.customer.findUnique({
            where: { mobile: '+919876543210' }
        });

        if (existingCustomer) {
            console.log('✅ Test customer already exists:');
            console.log({
                id: existingCustomer.id,
                name: existingCustomer.name,
                mobile: existingCustomer.mobile,
                email: existingCustomer.email
            });
            return existingCustomer;
        }

        // Create new test customer
        const customer = await prisma.customer.create({
            data: {
                name: 'Test User',
                mobile: '+919876543210',
                email: 'testuser@trevel.com',
                status: 'active'
            }
        });

        console.log('✅ Test customer created successfully:');
        console.log({
            id: customer.id,
            name: customer.name,
            mobile: customer.mobile,
            email: customer.email
        });

        console.log('\n📱 Use these credentials in the mobile app:');
        console.log('Mobile: +919876543210');
        console.log('OTP: Use any 4-digit code (backend will generate)');

        return customer;
    } catch (error) {
        console.error('❌ Error creating test customer:', error);
        throw error;
    } finally {
        await prisma.$disconnect();
    }
}

createTestCustomer();
