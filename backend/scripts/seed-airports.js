
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    await prisma.airport.upsert({
        where: { airportCode: 'DEL' },
        update: {},
        create: {
            airportCode: 'DEL',
            airportName: 'Indira Gandhi International Airport',
            city: 'New Delhi',
            latitude: 28.5562,
            longitude: 77.1000,
            terminal: 'Terminal 1,Terminal 2,Terminal 3'
        }
    });

    await prisma.airport.upsert({
        where: { airportCode: 'BOM' },
        update: {},
        create: {
            airportCode: 'BOM',
            airportName: 'Chhatrapati Shivaji Maharaj International Airport',
            city: 'Mumbai',
            latitude: 19.0902,
            longitude: 72.8628,
            terminal: 'Terminal 1,Terminal 2'
        }
    });

    console.log("Airports seeded");
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
