const db = require('../config/postgresClient');
const profileService = require('../services/profileService');
const resolveUserId = (req) => {
return req.user?.id || req.headers['x-user-id'] || req.headers['user-id'] || null;
};
const getProfile = async (req, res) => {
try {
const userId = resolveUserId(req);
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}

let user = await profileService.getUserById(db, userId);

if (!user) {
const userData = req.user || {};
const inferredName = userData.full_name || userData.name || userData.user_metadata?.full_name || userData.user_metadata?.name || null;
const inferredEmail = userData.email || userData.user_metadata?.email || null;
const inferredPhone = userData.phone || userData.user_metadata?.phone || null;

user = await profileService.createUserProfile(db, {
userId,
full_name: inferredName,
email: inferredEmail,
phone: inferredPhone
});
} else {
// User exists, but check if full_name is missing and update it
if (!user.full_name || user.full_name.trim() === '') {
const userData = req.user || {};
const inferredName = userData.full_name || 
                     userData.name || 
                     userData.user_metadata?.full_name || 
                     userData.user_metadata?.name ||
                     user.phone?.replace(/^\+91/, '') ||
                     'User';
// Update the user record with the inferred name
try {
await profileService.updateUserFullName(db, userId, inferredName);
user.full_name = inferredName;
} catch (updateError) {
// Error updating full_name
}
}
}

// Fetch user statistics (total trips, CO2 savings, trees planted)
// Always ensure statistics are included, even if calculation fails
let statistics = {
total_trips: 0,
co2_savings: '0g',
trees_planted: 0.00
};

try {
const fetchedStats = await profileService.getUserStatistics(db, userId);
if (fetchedStats) {
statistics = fetchedStats;
}
} catch (error) {
// Use default statistics if there's an error
}

// Normalize profile response (always includes statistics)
const profileData = profileService.normalizeProfileResponse(user, statistics);

// Ensure full_name is never null or empty (use fallback if needed)
if (!profileData.full_name || profileData.full_name.trim() === '') {
// Try to get name from user metadata or use phone number as fallback
const fallbackName = req.user?.user_metadata?.full_name || 
                     req.user?.user_metadata?.name || 
                     req.user?.name ||
                     profileData.phone?.replace(/^\+91/, '') || 
                     'User';
profileData.full_name = fallbackName;
}


// Ensure all required fields are present
const finalResponse = {
success: true,
data: {
...profileData,
// Explicitly ensure these fields are always present
full_name: profileData.full_name || 'User',
total_trips: profileData.total_trips !== undefined ? profileData.total_trips : 0,
co2_savings: profileData.co2_savings || '0g',
trees_planted: profileData.trees_planted !== undefined ? profileData.trees_planted : 0.00
}
};


return res.status(200).json(finalResponse);
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to fetch profile',
message: error.message
});
}
};
const createProfile = async (req, res) => {
try {
const userId = resolveUserId(req);
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const user = req.user || {};
const inferredName = user.full_name || user.name || user.user_metadata?.full_name || user.user_metadata?.name || null;
const inferredEmail = user.email || user.user_metadata?.email || null;
const inferredPhone = user.phone || user.user_metadata?.phone || null;
const existing = await profileService.ensureProfileExists(db, {
userId,
full_name: inferredName,
email: inferredEmail,
phone: inferredPhone
});
return res.status(200).json({
success: true,
message: 'Profile already exists',
data: profileService.normalizeProfileResponse(existing)
});
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to create profile',
message: error.message
});
}
};
const updateProfile = async (req, res) => {
try {
const userId = resolveUserId(req);
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const user = req.user || {};
const inferredName = user.full_name || user.name || user.user_metadata?.full_name || user.user_metadata?.name || null;
const inferredEmail = user.email || user.user_metadata?.email || null;
const inferredPhone = user.phone || user.user_metadata?.phone || null;
await profileService.ensureProfileExists(db, {
userId,
full_name: inferredName,
email: inferredEmail,
phone: inferredPhone
});

const { full_name, phone, email, emergency_contact, profile_image_url, gender, date_of_birth, address } = req.body;
const updateData = {};
if (full_name !== undefined && full_name !== null) updateData.full_name = full_name.trim();
if (phone !== undefined && phone !== null) updateData.phone = phone.trim();
if (email !== undefined) updateData.email = email === null || email === '' ? null : email.trim();
if (emergency_contact !== undefined) updateData.emergency_contact = emergency_contact === null || emergency_contact === '' ? null : emergency_contact.trim();
if (profile_image_url !== undefined) updateData.profile_image_url = profile_image_url === null || profile_image_url === '' ? null : profile_image_url.trim();
if (gender !== undefined) updateData.gender = gender === null || gender === '' ? null : gender.trim();
if (date_of_birth !== undefined) updateData.date_of_birth = date_of_birth === null || date_of_birth === '' ? null : date_of_birth;
if (address !== undefined) updateData.address = address === null || address === '' ? null : address.trim();
if (Object.keys(updateData).length === 0) {
return res.status(400).json({
success: false,
error: 'No changes provided',
message: 'Provide at least one field to update.'
});
}
try {
const updatedUser = await profileService.updateUserProfile(db, userId, updateData);

// Fetch statistics for updated profile response
let statistics = {
total_trips: 0,
co2_savings: '0g',
trees_planted: 0.00
};

try {
const fetchedStats = await profileService.getUserStatistics(db, userId);
if (fetchedStats) {
statistics = fetchedStats;
}
} catch (error) {
// Use default statistics if there's an error
}

const updatedProfileData = profileService.normalizeProfileResponse(updatedUser, statistics);

// Ensure full_name is never null or empty
if (!updatedProfileData.full_name || updatedProfileData.full_name.trim() === '') {
const fallbackName = updateData.full_name || 
                     req.user?.user_metadata?.full_name || 
                     req.user?.user_metadata?.name || 
                     req.user?.name ||
                     updatedProfileData.phone?.replace(/^\+91/, '') || 
                     'User';
updatedProfileData.full_name = fallbackName;
}

return res.status(200).json({
success: true,
message: 'Profile updated successfully',
data: updatedProfileData
});
} catch (dbError) {
return res.status(500).json({
success: false,
error: 'Database error',
message: dbError.message || 'Failed to update profile in database'
});
}
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to update profile',
message: error.message
});
}
};
const getPromoCodes = async (req, res) => {
try {
const userId = resolveUserId(req);
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const promoCodes = await profileService.getUserPromoCodes(db, userId);
return res.status(200).json({
success: true,
data: promoCodes,
count: promoCodes.length
});
} catch (error) {
return res.status(500).json({
success: false,
error: 'Failed to fetch promo codes',
message: error.message
});
}
};
module.exports = {
getProfile,
createProfile,
updateProfile,
getPromoCodes
};
