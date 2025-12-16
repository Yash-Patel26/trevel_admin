const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    try {
        console.log("Connecting...");
        const users = await prisma.customer.findMany({ take: 1 });
        console.log("Connection successful. Found users:", users.length);
    } catch (e) {
        console.error("Connection failed:", e);
    } finally {
        await prisma.$disconnect();
    }
}

main();
