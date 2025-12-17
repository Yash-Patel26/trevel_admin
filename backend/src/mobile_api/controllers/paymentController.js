const db = require('../config/postgresClient');
const crypto = require('crypto');
const zaakpayClient = require('../services/zaakpayClient');
const { verifyChecksum } = require('../utils/zaakpaySignature');
const paymentService = require('../services/paymentService');
const toPaise = (value) => {
  const amountNumber = Number(value);
  if (!Number.isFinite(amountNumber) || amountNumber <= 0) return null;
  return Math.round(amountNumber * 100);
};
const fromPaise = (value) => {
  if (value === undefined || value === null) return null;
  const paiseNumber = Number(value);
  if (!Number.isFinite(paiseNumber)) return null;
  return paiseNumber / 100;
};
const mapGatewayStatus = (status = '') => {
  const normalized = String(status).toUpperCase();
  if (['SUCCESS', 'CAPTURED', 'PAID'].includes(normalized)) return 'completed';
  if (['FAILED', 'DECLINED', 'ERROR'].includes(normalized)) return 'failed';
  return 'pending';
};
const getAllPayments = async (req, res) => {
  try {
    const { trip_id, status, user_id, limit } = req.query;

    const { payments, count } = await paymentService.getAllPayments(db, {
      trip_id,
      status,
      user_id,
      limit
    });
    res.status(200).json({
      success: true,
      count,
      data: payments
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch payments',
      message: error.message
    });
  }
};
const getPaymentById = async (req, res) => {
  try {
    const { id } = req.params;

    const payment = await paymentService.getPaymentById(db, id);
    if (!payment) {
      return res.status(404).json({
        success: false,
        error: 'Payment not found'
      });
    }
    res.status(200).json({
      success: true,
      data: payment
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch payment',
      message: error.message
    });
  }
};
const getUserPayments = async (req, res) => {
  try {
    const userId = req.user.id;

    const { payments, count } = await paymentService.getUserPayments(db, userId);
    res.status(200).json({
      success: true,
      count,
      data: payments
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch user payments',
      message: error.message
    });
  }
};
const createPayment = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      trip_id,
      amount,
      currency,
      status = 'pending',
      payment_method,
      transaction_id,
      notes
    } = req.body;
    if (!trip_id || !amount) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
        message: 'trip_id and amount are required'
      });
    }

    const payment = await paymentService.createPayment(db, {
      trip_id,
      userId,
      amount,
      currency,
      status,
      payment_method,
      transaction_id,
      notes
    });
    if (!payment) {
      throw new Error('Failed to create payment');
    }
    res.status(201).json({
      success: true,
      message: 'Payment created successfully',
      data: payment
    });
  } catch (error) {
    if (error.code === '23505') {
      return res.status(409).json({
        success: false,
        error: 'Payment already exists',
        message: 'A payment for this transaction already exists'
      });
    }
    res.status(500).json({
      success: false,
      error: 'Failed to create payment',
      message: error.message
    });
  }
};
const updatePayment = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const { status, notes } = req.body;

    const existingPayment = await paymentService.getPaymentByIdAndUserId(db, id, userId);
    if (!existingPayment) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden',
        message: 'You can only update your own payments'
      });
    }
    const payment = await paymentService.updatePayment(db, id, { status, notes });
    if (!payment) {
      return res.status(404).json({
        success: false,
        error: 'Payment not found'
      });
    }
    res.status(200).json({
      success: true,
      message: 'Payment updated successfully',
      data: payment
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to update payment',
      message: error.message
    });
  }
};
const deletePayment = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const existingPayment = await paymentService.getPaymentByIdAndUserId(db, id, userId);
    if (!existingPayment) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden',
        message: 'You can only delete your own payments'
      });
    }
    const payment = await paymentService.deletePayment(db, id);
    if (!payment) {
      return res.status(404).json({
        success: false,
        error: 'Payment not found'
      });
    }
    res.status(200).json({
      success: true,
      message: 'Payment deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to delete payment',
      message: error.message
    });
  }
};
const createZaakpayOrder = async (req, res) => {
  try {
    console.log('[PaymentController] createZaakpayOrder called');
    console.log('[PaymentController] Request path:', req.path);
    console.log('[PaymentController] Request method:', req.method);
    console.log('[PaymentController] Request body:', JSON.stringify(req.body, null, 2));
    const userId = req.user?.id || null;
    const {
      trip_id,
      amount,
      currency = 'INR',
      order_id,
      return_url,
      callback_url,
      customer = {},
      metadata = {},
      gateway_fields = {}
    } = req.body || {};
    if (!trip_id || !amount) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
        message: 'trip_id and amount are required'
      });
    }
    const amountPaise = toPaise(amount);
    if (!amountPaise) {
      return res.status(400).json({
        success: false,
        error: 'Invalid amount',
        message: 'amount must be a positive number'
      });
    }
    const resolvedReturnUrl = return_url || process.env.ZAAKPAY_RETURN_URL;
    // Fix callback URL - ensure it includes /v1 and /zaakpay if not provided
    let resolvedCallbackUrl = callback_url || process.env.ZAAKPAY_CALLBACK_URL;
    if (resolvedCallbackUrl && !resolvedCallbackUrl.includes('/zaakpay/callback')) {
      // Auto-fix callback URL if it's missing /v1 or /zaakpay
      if (resolvedCallbackUrl.includes('/api/payments/callback')) {
        resolvedCallbackUrl = resolvedCallbackUrl.replace('/api/payments/callback', '/api/v1/payments/zaakpay/callback');
      } else if (resolvedCallbackUrl.includes('/payments/callback')) {
        resolvedCallbackUrl = resolvedCallbackUrl.replace('/payments/callback', '/api/v1/payments/zaakpay/callback');
      }
    }
    if (!resolvedReturnUrl || !resolvedCallbackUrl) {
      return res.status(400).json({
        success: false,
        error: 'Missing callback configuration',
        message: 'return_url or ZAAKPAY_RETURN_URL and callback_url or ZAAKPAY_CALLBACK_URL are required'
      });
    }
    const orderId = order_id || `${process.env.ZAAKPAY_ORDER_PREFIX || 'TRVL'}-${crypto.randomUUID()}`;
    const orderPayload = {
      orderId,
      amount: amountPaise,
      currencyCode: currency,
      returnUrl: resolvedReturnUrl,
      notifyUrl: resolvedCallbackUrl,
      productDescription: metadata.description || 'Trevel ride payment',
      buyerName: customer.name,
      buyerEmail: customer.email,
      buyerPhoneNumber: customer.phone,
      merchantParam1: trip_id,
      merchantParam2: userId,
      ...gateway_fields
    };
    let gatewayResponse;
    try {
      console.log('[PaymentController] Calling Zaakpay createOrder...');
      console.log('[PaymentController] Order payload:', JSON.stringify(orderPayload, null, 2));
      gatewayResponse = await zaakpayClient.createOrder(orderPayload);
      console.log('[PaymentController] Zaakpay response received:', JSON.stringify(gatewayResponse, null, 2));
    } catch (error) {
      console.error('[PaymentController] Zaakpay API call failed:');
      console.error('[PaymentController] Error:', error.message);
      console.error('[PaymentController] Stack:', error.stack);
      throw error;
    }

    await paymentService.upsertGatewayEvent(db, {
      orderId,
      tripId: trip_id,
      userId,
      amount: Number(amount),
      currency,
      status: 'pending',
      rawPayload: { request: orderPayload, response: gatewayResponse }
    });
    await paymentService.recordPaymentSnapshot(db, {
      tripId: trip_id,
      userId: userId,
      amount: Number(amount),
      currency: currency,
      status: 'pending'
    });
    const checkoutPayload = {
      merchantIdentifier: process.env.ZAAKPAY_MERCHANT_ID,
      ...orderPayload,
      checksum: gatewayResponse.checksum || gatewayResponse.data?.checksum
    };
    res.status(201).json({
      success: true,
      data: {
        order_id: orderId,
        amount: Number(amount),
        currency,
        payment_url: gatewayResponse.paymentUrl || gatewayResponse.paymenturl || null,
        checkout_payload: checkoutPayload
      },
      gateway_response: gatewayResponse
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to create Zaakpay order',
      message: error.message
    });
  }
};
const handleZaakpayCallback = async (req, res) => {
  try {
    const payload = req.body || {};
    const orderId = payload.orderId || payload.order_id;
    if (!orderId) {
      return res.status(400).json({
        success: false,
        error: 'Missing orderId in callback payload'
      });
    }
    if (!verifyChecksum(payload)) {
      return res.status(400).json({
        success: false,
        error: 'Checksum validation failed'
      });
    }
    const gatewayStatus = payload.responseCode || payload.txnStatus || payload.status;
    const localStatus = mapGatewayStatus(gatewayStatus);
    const amountRupees = fromPaise(payload.amount);

    const eventRecord = await paymentService.upsertGatewayEvent(db, {
      orderId,
      amount: amountRupees,
      currency: payload.currencyCode || 'INR',
      status: localStatus,
      rawPayload: payload
    });
    if (eventRecord?.trip_id && amountRupees) {
      await paymentService.recordPaymentSnapshot(db, {
        tripId: eventRecord.trip_id,
        userId: eventRecord.user_id || null,
        amount: amountRupees,
        currency: payload.currencyCode || 'INR',
        status: localStatus
      });
    }
    res.status(200).json({
      success: true,
      status: localStatus,
      order_id: orderId,
      gateway_status: gatewayStatus,
      pg_transaction_id: payload.pgTxnId || payload.pg_txn_id || payload.transactionId,
      data: payload
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to process Zaakpay callback',
      message: error.message
    });
  }
};
const getZaakpayStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    if (!orderId) {
      return res.status(400).json({
        success: false,
        error: 'orderId is required'
      });
    }
    const gatewayResponse = await zaakpayClient.getTransactionStatus({ orderId });
    const gatewayStatus = gatewayResponse.txnStatus || gatewayResponse.status;
    const localStatus = mapGatewayStatus(gatewayStatus);
    const amountRupees = fromPaise(gatewayResponse.amount);

    await paymentService.upsertGatewayEvent(db, {
      orderId,
      amount: amountRupees,
      currency: gatewayResponse.currencyCode || 'INR',
      status: localStatus,
      rawPayload: gatewayResponse
    });
    res.status(200).json({
      success: true,
      status: localStatus,
      gateway_response: gatewayResponse
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch Zaakpay status',
      message: error.message
    });
  }
};
const createZaakpayRefund = async (req, res) => {
  try {
    const { order_id, trip_id, booking_id, refund_amount, amount, currency = 'INR', refund_reference, reason } = req.body || {};

    let resolvedOrderId = order_id;
    // If order_id missing but trip_id/booking_id provided, look it up
    if (!resolvedOrderId && (trip_id || booking_id)) {
      const targetTripId = trip_id || booking_id;
      // Find successful payment for this trip
      // We need to use paymentService to find the payment by trip_id
      // Since we don't have a direct method exposed here, we might need to query DB or add a method.
      // For now, let's query the payment_gateway_events table or payments table
      const { rows } = await db.query(
        `SELECT order_id FROM payment_gateway_events 
         WHERE trip_id = $1 AND status = 'completed' 
         ORDER BY created_at DESC LIMIT 1`,
        [targetTripId]
      );
      if (rows.length > 0) {
        resolvedOrderId = rows[0].order_id;
      }
    }

    const resolvedAmount = refund_amount || amount;

    if (!resolvedOrderId || !resolvedAmount) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
        message: 'order_id (or booking_id of a completed payment) and refund_amount are required'
      });
    }

    const refundAmountPaise = toPaise(resolvedAmount);
    if (!refundAmountPaise) {
      return res.status(400).json({
        success: false,
        error: 'Invalid refund amount'
      });
    }

    const refundId = refund_reference || `RFND-${crypto.randomUUID()}`;
    const refundPayload = {
      orderId: resolvedOrderId,
      refundId,
      refundAmount: refundAmountPaise,
      currencyCode: currency,
      refundReason: reason
    };
    const gatewayResponse = await zaakpayClient.createRefund(refundPayload);
    res.status(201).json({
      success: true,
      data: {
        refund_id: refundId,
        order_id,
        status: gatewayResponse.refundStatus || gatewayResponse.status,
        gateway_response: gatewayResponse
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to create Zaakpay refund',
      message: error.message
    });
  }
};
const getZaakpayRefundStatus = async (req, res) => {
  try {
    const { refundId } = req.params;
    if (!refundId) {
      return res.status(400).json({
        success: false,
        error: 'refundId is required'
      });
    }
    const gatewayResponse = await zaakpayClient.getRefundStatus({ refundId });
    res.status(200).json({
      success: true,
      gateway_response: gatewayResponse
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch Zaakpay refund status',
      message: error.message
    });
  }
};
module.exports = {
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
};
