const db = require('../config/postgresClient');
const { createNotification } = require('./notificationController');
const emergencyService = require('../services/emergencyService');
const createEmergencySos = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}
const { booking_id, latitude, longitude, address } = req.body;
if (!latitude || !longitude) {
return res.status(400).json({
success: false,
error: 'Location (latitude and longitude) is required'
});
}

const sosEvent = await emergencyService.createEmergencySos(db, {
userId,
booking_id,
latitude,
longitude,
address
});
await createNotification(
userId,
'Emergency SOS Activated',
'Your emergency SOS has been activated. Help is on the way.',
'emergency',
booking_id || null
);
res.status(201).json({
success: true,
message: 'Emergency SOS activated successfully',
data: sosEvent
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to activate emergency SOS',
message: error.message
});
}
};
const getEmergencyContacts = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}

const contacts = await emergencyService.getEmergencyContacts(db, userId);
res.status(200).json({
success: true,
count: contacts.length,
data: contacts
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch emergency contacts',
message: error.message
});
}
};
const addEmergencyContact = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}
const { name, phone_number, relationship, is_primary, can_receive_alerts } = req.body;
if (!name || !phone_number) {
return res.status(400).json({
success: false,
error: 'Name and phone_number are required'
});
}

const contact = await emergencyService.addEmergencyContact(db, {
userId,
name,
phone_number,
relationship,
is_primary,
can_receive_alerts
});
res.status(201).json({
success: true,
data: contact
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to add emergency contact',
message: error.message
});
}
};
const updateEmergencyContact = async (req, res) => {
try {
const userId = req.user?.id;
const { id } = req.params;
const { name, phone_number, relationship, is_primary, can_receive_alerts } = req.body;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}

try {
const contact = await emergencyService.updateEmergencyContact(db, id, userId, {
name,
phone_number,
relationship,
is_primary,
can_receive_alerts
});
if (!contact) {
return res.status(404).json({
success: false,
error: 'Emergency contact not found'
});
}
res.status(200).json({
success: true,
data: contact
});
} catch (error) {
if (error.message.includes('No fields to update')) {
return res.status(400).json({
success: false,
error: 'No fields to update',
message: error.message
});
}
throw error;
}
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to update emergency contact',
message: error.message
});
}
};
const deleteEmergencyContact = async (req, res) => {
try {
const userId = req.user?.id;
const { id } = req.params;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}

const contact = await emergencyService.deleteEmergencyContact(db, id, userId);
if (!contact) {
return res.status(404).json({
success: false,
error: 'Emergency contact not found'
});
}
res.status(200).json({
success: true,
message: 'Emergency contact deleted successfully'
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to delete emergency contact',
message: error.message
});
}
};
module.exports = {
createEmergencySos,
getEmergencyContacts,
addEmergencyContact,
updateEmergencyContact,
deleteEmergencyContact
};
