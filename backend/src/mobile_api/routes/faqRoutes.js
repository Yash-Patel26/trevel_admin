const express = require('express');
const router = express.Router();
const { getFaq, markFaqHelpful } = require('../controllers/faqController');
router.get('/', getFaq);
router.post('/:id/helpful', markFaqHelpful);
module.exports = router;
