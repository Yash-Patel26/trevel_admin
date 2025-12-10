/**
 * Backfill driver documents with existing S3 URLs.
 *
 * Usage (from backend/ directory):
 *   node scripts/backfill_driver_documents.js --driverId=123
 *
 * Configure the DOCUMENTS array below with the S3 URLs you already have.
 * The script skips creating a document if one with the same (driverId, type) already exists.
 */

require("dotenv").config({ path: "./.env" });
const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

// TODO: Fill in your S3 URLs here before running.
// Example:
// const DOCUMENTS = [
//   { type: "pan", url: "https://.../pan.png" },
//   { type: "aadhar", url: "https://.../aadhar.png" },
//   { type: "driving_license", url: "https://.../dl.png" },
//   { type: "police_verification", url: "https://.../police.png" },
// ];
const DOCUMENTS = [];

function getDriverId() {
  const arg = process.argv.find((a) => a.startsWith("--driverId="));
  const fromArg = arg ? Number(arg.split("=")[1]) : undefined;
  const fromEnv = process.env.DRIVER_ID ? Number(process.env.DRIVER_ID) : undefined;
  return fromArg || fromEnv;
}

async function main() {
  const driverId = getDriverId();
  if (!driverId) {
    console.error("❌ driverId is required. Pass --driverId=123 or set DRIVER_ID in env.");
    process.exit(1);
  }

  if (!Array.isArray(DOCUMENTS) || DOCUMENTS.length === 0) {
    console.error("❌ DOCUMENTS is empty. Please add your S3 URLs in the DOCUMENTS array.");
    process.exit(1);
  }

  const driver = await prisma.driver.findUnique({ where: { id: driverId } });
  if (!driver) {
    console.error(`❌ Driver ${driverId} not found`);
    process.exit(1);
  }

  console.log(`🔎 Backfilling documents for driver ${driverId} (${driver.name || driver.email || driver.mobile})`);

  for (const doc of DOCUMENTS) {
    const type = String(doc.type || "").trim();
    const url = String(doc.url || "").trim();
    if (!type || !url) {
      console.warn("⚠️  Skipping document with missing type or url:", doc);
      continue;
    }

    const existing = await prisma.driverDocument.findFirst({
      where: { driverId, type },
    });

    if (existing) {
      console.log(`➡️  Skipping ${type}: already exists (id=${existing.id})`);
      continue;
    }

    const created = await prisma.driverDocument.create({
      data: {
        driverId,
        type,
        url,
        status: "uploaded",
      },
    });
    console.log(`✅ Created ${type}: id=${created.id}`);
  }

  console.log("🎉 Backfill complete");
}

main()
  .catch((err) => {
    console.error("❌ Error:", err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

