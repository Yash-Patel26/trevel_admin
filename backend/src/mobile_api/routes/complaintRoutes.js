const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const {
getComplaints,
getComplaintById,
createComplaint,
updateComplaint
} = require('../controllers/complaintController');
router.get('/', authMiddleware, getComplaints);
router.get('/:id', authMiddleware, getComplaintById);
router.post('/', authMiddleware, createComplaint);
router.put('/:id', authMiddleware, updateComplaint);
router.post('/contact', authMiddleware, createComplaint);
router.post('/report-issue', authMiddleware, createComplaint);
module.exports = router;
