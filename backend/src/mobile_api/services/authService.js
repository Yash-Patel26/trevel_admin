const crypto = require('crypto');
const prisma = require('../../prisma/client').default;

const getUserById = async (db, userId) => {
  const customer = await prisma.customer.findUnique({
    where: { id: userId }
  });
  if (!customer) return null;
  // Map Prisma model back to raw structure expected by legacy code if needed
  // Prisma `Customer` fields: id, name, mobile, email, profileImageUrl, createdAt, updatedAt
  // Expected return: id, email, full_name, phone, profile_image_url, created_at, updated_at
  return {
    id: customer.id,
    email: customer.email,
    full_name: customer.name,
    phone: customer.mobile,
    profile_image_url: customer.profileImageUrl,
    created_at: customer.createdAt,
    updated_at: customer.updatedAt
  };
};

const getUserByPhone = async (db, phone) => {
  const customer = await prisma.customer.findUnique({
    where: { mobile: phone }
  });
  return customer ? { id: customer.id } : null;
};

const createUser = async (db, phone) => {
  // Prisma manages IDs (uuid) automatically if configured, but schema says @default(uuid())
  // Implementation says: INSERT ... VALUES ($1, $2, NOW()) with generated UUID.
  // We can let Prisma handle UUID or provide it.
  // Schema: id String @id @default(uuid())
  // So we just provide mobile.

  const customer = await prisma.customer.create({
    data: {
      mobile: phone
    }
  });
  return customer.id;
};

const getUserWithDetails = async (db, userId) => {
  // Expected: id, phone, full_name, email, created_at
  const customer = await prisma.customer.findUnique({
    where: { id: userId }
  });
  if (!customer) return null;

  return {
    id: customer.id,
    phone: customer.mobile,
    full_name: customer.name,
    email: customer.email,
    created_at: customer.createdAt
  };
};

module.exports = {
  getUserById,
  getUserByPhone,
  createUser,
  getUserWithDetails
};

