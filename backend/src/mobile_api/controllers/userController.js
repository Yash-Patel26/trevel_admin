const userService = require('../services/userService');
const getUserById = async (req, res) => {
try {
const { id } = req.params;
const user = await userService.getUserById(id);
if (!user) {
return res.status(404).json({
success: false,
error: 'User not found'
});
}
res.status(200).json({
success: true,
data: user
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch user',
message: error.message
});
}
};
const getCurrentUser = async (req, res) => {
try {
const userId = req.user.id;
let user = await userService.getUserById(userId);
if (!user) {
user = await userService.createUser({
id: userId,
email: req.user.email,
phone: req.user.phone || null,
full_name: req.user.user_metadata?.full_name || null
});
if (!user) {
throw new Error('Failed to create user profile');
}
}
res.status(200).json({
success: true,
data: {
id: user.id,
full_name: user.full_name || '',
email: user.email || '',
phone: user.phone || '',
profile_image_url: user.profile_image_url || null,
created_at: user.created_at
}
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch current user',
message: error.message
});
}
};
const createUser = async (req, res) => {
return res.status(410).json({
success: false,
error: 'Deprecated',
message: 'User creation is not available through admin API. Users must be created via OTP flow on mobile app: POST /api/auth/verify-otp'
});
};
const updateUser = async (req, res) => {
try {
const { id } = req.params;
const userId = req.user.id;
if (id !== userId) {
return res.status(403).json({
success: false,
error: 'Forbidden',
message: 'You can only update your own profile.'
});
}
const {
full_name,
fullName,
phone,
date_of_birth,
dateOfBirth,
address,
city,
country,
profile_image_url,
profileImageUrl
} = req.body;
const updateData = {};
if (full_name !== undefined || fullName !== undefined) updateData.full_name = full_name || fullName;
if (phone !== undefined) updateData.phone = phone;
if (date_of_birth !== undefined || dateOfBirth !== undefined) updateData.date_of_birth = date_of_birth || dateOfBirth;
if (address !== undefined) updateData.address = address;
if (city !== undefined) updateData.city = city;
if (country !== undefined) updateData.country = country;
if (profile_image_url !== undefined || profileImageUrl !== undefined) updateData.profile_image_url = profile_image_url || profileImageUrl;
const user = await userService.updateUser(id, updateData);
if (!user) {
return res.status(404).json({
success: false,
error: 'User not found'
});
}
res.status(200).json({
success: true,
message: 'User updated successfully',
data: {
id: user.id,
full_name: user.full_name || '',
email: user.email || '',
phone: user.phone || '',
profile_image_url: user.profile_image_url || null,
created_at: user.created_at,
updated_at: user.updated_at || user.created_at
}
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to update user',
message: error.message
});
}
};
module.exports = {
getUserById,
getCurrentUser,
updateUser
};
