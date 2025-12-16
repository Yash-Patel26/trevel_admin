const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const {
createEmergencySos,
getEmergencyContacts,
addEmergencyContact,
updateEmergencyContact,
deleteEmergencyContact
} = require('../controllers/emergencyController');
router.post('/sos', authMiddleware, createEmergencySos);
router.get('/contacts', authMiddleware, getEmergencyContacts);
router.post('/contacts', authMiddleware, addEmergencyContact);
router.put('/contacts/:id', authMiddleware, updateEmergencyContact);
router.delete('/contacts/:id', authMiddleware, deleteEmergencyContact);
module.exports = router;
