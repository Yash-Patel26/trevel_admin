const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const {
getAllPayments,
getPaymentById,
getUserPayments,
createPayment,
updatePayment,
deletePayment,
createZaakpayOrder,
handleZaakpayCallback,
getZaakpayStatus,
createZaakpayRefund,
getZaakpayRefundStatus
} = require('../controllers/paymentController');
const {
getPaymentMethods,
addPaymentMethod,
deletePaymentMethod
} = require('../controllers/paymentMethodController');
router.get('/', authMiddleware, getAllPayments);
router.get('/my/payments', authMiddleware, getUserPayments);
router.get('/methods', authMiddleware, getPaymentMethods);
router.post('/methods', authMiddleware, addPaymentMethod);
router.delete('/methods/:id', authMiddleware, deletePaymentMethod);
router.get('/history', authMiddleware, getUserPayments);
router.post('/zaakpay/order', authMiddleware, createZaakpayOrder);
router.post('/zaakpay/callback', handleZaakpayCallback);
router.get('/zaakpay/status/:orderId', authMiddleware, getZaakpayStatus);
router.post('/zaakpay/refund', authMiddleware, createZaakpayRefund);
router.get('/zaakpay/refund/:refundId', authMiddleware, getZaakpayRefundStatus);
router.get('/:id', authMiddleware, getPaymentById);
router.post('/', authMiddleware, createPayment);
router.put('/:id', authMiddleware, updatePayment);
router.delete('/:id', authMiddleware, deletePayment);
module.exports = router;
