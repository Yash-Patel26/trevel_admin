const faqService = require('../services/faqService');
const getFaq = async (req, res) => {
try {
const { category } = req.query;
const faqs = await faqService.getFaq(category);
res.status(200).json({
success: true,
count: faqs.length,
data: faqs
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch FAQ',
message: error.message
});
}
};
const markFaqHelpful = async (req, res) => {
try {
const { id } = req.params;
const { helpful } = req.body;
if (typeof helpful !== 'boolean') {
return res.status(400).json({
success: false,
error: 'helpful must be a boolean value'
});
}
const faq = await faqService.markFaqHelpful(id, helpful);
if (!faq) {
return res.status(404).json({
success: false,
error: 'FAQ not found'
});
}
res.status(200).json({
success: true,
data: faq
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to update FAQ',
message: error.message
});
}
};
module.exports = {
getFaq,
markFaqHelpful
};
