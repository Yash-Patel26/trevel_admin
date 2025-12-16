const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const { getUserById, getCurrentUser, updateUser } = require('../controllers/userController');

router.get('/me', authMiddleware, getCurrentUser);
router.get('/:id', authMiddleware, getUserById);
router.put('/:id', authMiddleware, updateUser);

module.exports = router;
