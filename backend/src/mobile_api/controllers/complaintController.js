const db = require('../config/postgresClient');
const complaintService = require('../services/complaintService');
const getComplaints = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const { status, category, user_id, all } = req.query;

const complaints = await complaintService.getComplaints(db, {
status,
category,
user_id,
all,
userId
});
res.status(200).json({
success: true,
count: complaints.length,
data: complaints
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch complaints',
message: error.message
});
}
};
const getComplaintById = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const { id } = req.params;
const { user_id } = req.query;

try {
const complaint = await complaintService.getComplaintById(db, id, userId, user_id);
if (!complaint) {
return res.status(404).json({
success: false,
error: 'Complaint not found'
});
}
res.status(200).json({
success: true,
data: complaint
});
} catch (error) {
if (error.message.includes('permission')) {
return res.status(403).json({
success: false,
error: 'Forbidden',
message: error.message
});
}
throw error;
}
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch complaint',
message: error.message
});
}
};
const createComplaint = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const {
booking_id,
booking_type,
subject,
description,
category = 'other',
priority = 'medium'
} = req.body;
if (!subject || !description) {
return res.status(400).json({
success: false,
error: 'Missing required fields',
message: 'subject and description are required'
});
}

const complaint = await complaintService.createComplaint(db, {
userId,
booking_id,
booking_type,
subject,
description,
category,
priority
});
res.status(201).json({
success: true,
message: 'Complaint submitted successfully',
data: complaint
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to create complaint',
message: error.message
});
}
};
const updateComplaint = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized',
message: 'User authentication required'
});
}
const { id } = req.params;
const { subject, description, category, priority, status, admin_notes } = req.body;

try {
const complaint = await complaintService.updateComplaint(db, id, userId, {
subject,
description,
category,
priority,
status,
admin_notes
});
if (!complaint) {
return res.status(404).json({
success: false,
error: 'Complaint not found'
});
}
res.status(200).json({
success: true,
message: 'Complaint updated successfully',
data: complaint
});
} catch (error) {
if (error.message.includes('can only update') || error.message.includes('Only open complaints')) {
return res.status(403).json({
success: false,
error: 'Forbidden',
message: error.message
});
}
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
error: 'Failed to update complaint',
message: error.message
});
}
};
module.exports = {
getComplaints,
getComplaintById,
createComplaint,
updateComplaint
};
