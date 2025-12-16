const paymentMethodService = require('../services/paymentMethodService');
const getPaymentMethods = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}

const paymentMethods = await paymentMethodService.getPaymentMethods(userId);
res.status(200).json({
success: true,
count: paymentMethods.length,
data: paymentMethods
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to fetch payment methods',
message: error.message
});
}
};
const addPaymentMethod = async (req, res) => {
try {
const userId = req.user?.id;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}
const {
type,
provider,
card_number_last4,
card_brand,
card_holder_name,
expiry_month,
expiry_year,
upi_id,
is_default,
payment_gateway_token,
metadata
} = req.body;
if (!type) {
return res.status(400).json({
success: false,
error: 'Payment method type is required'
});
}

const paymentMethod = await paymentMethodService.addPaymentMethod({
userId,
type,
provider,
card_number_last4,
card_brand,
card_holder_name,
expiry_month,
expiry_year,
upi_id,
is_default,
payment_gateway_token,
metadata
});
res.status(201).json({
success: true,
data: paymentMethod
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to add payment method',
message: error.message
});
}
};
const deletePaymentMethod = async (req, res) => {
try {
const userId = req.user?.id;
const { id } = req.params;
if (!userId) {
return res.status(401).json({
success: false,
error: 'Unauthorized'
});
}

const existing = await paymentMethodService.getPaymentMethodById(db, id, userId);
if (!existing) {
return res.status(404).json({
success: false,
error: 'Payment method not found'
});
}
await paymentMethodService.deletePaymentMethod(db, id, userId);
res.status(200).json({
success: true,
message: 'Payment method deleted successfully'
});
} catch (error) {
res.status(500).json({
success: false,
error: 'Failed to delete payment method',
message: error.message
});
}
};
module.exports = {
getPaymentMethods,
addPaymentMethod,
deletePaymentMethod
};
