const prisma = require('../../prisma/client').default;

// Helper to map Prisma Customer to Legacy User format
const mapCustomerToUser = (customer) => {
  if (!customer) return null;
  return {
    id: customer.id,
    full_name: customer.name,
    email: customer.email,
    phone: customer.mobile,
    profile_image_url: customer.profileImageUrl,
    created_at: customer.createdAt || new Date().toISOString(), // Fallback if missing
    updated_at: customer.updatedAt || new Date().toISOString()
  };
};

const getUserById = async (db, userId) => {
  // db ignored
  try {
    const customer = await prisma.customer.findUnique({
      where: { id: userId }
    });
    return mapCustomerToUser(customer);
  } catch (error) {
    console.error('Error getting user by id:', error);
    return null;
  }
};

const createUser = async (db, userData) => {
  // db ignored
  const { id, email, phone, full_name } = userData;
  try {
    const customer = await prisma.customer.create({
      data: {
        id: id, // Optional if we want to enforce specific ID
        email: email,
        mobile: phone,
        name: full_name
      }
    });
    return mapCustomerToUser(customer);
  } catch (error) {
    console.error('Error creating user:', error);
    return null;
  }
};

const updateUser = async (db, userId, updateData) => {
  // Map legacy update fields to Prisma fields
  const prismaUpdateData = {};

  if (updateData.full_name !== undefined) prismaUpdateData.name = updateData.full_name;
  if (updateData.phone !== undefined) prismaUpdateData.mobile = updateData.phone;
  if (updateData.email !== undefined) prismaUpdateData.email = updateData.email;
  // Handle other potential fields if strictly needed, but these are the main ones
  // legacy query: keys mapped to values.

  // Handle profile_image_url
  if (updateData.profile_image_url !== undefined) prismaUpdateData.profileImageUrl = updateData.profile_image_url;

  try {
    const customer = await prisma.customer.update({
      where: { id: userId },
      data: prismaUpdateData
    });
    return mapCustomerToUser(customer);
  } catch (error) {
    console.error('Error updating user:', error);
    return null;
  }
};

module.exports = {
  getUserById,
  createUser,
  updateUser
};

