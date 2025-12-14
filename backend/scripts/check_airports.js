
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const airports = await prisma.airport.findMany();
    console.log(JSON.stringify(airports, null, 2));
}

main()
    .catch(e => console.error(e))
    .finally(async () => await prisma.$disconnect());
