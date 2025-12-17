const axios = require('axios');
const { generateChecksum, sanitizePayload } = require('../utils/zaakpaySignature');
const merchantId = process.env.ZAAKPAY_MERCHANT_ID;
const merchantKey = process.env.ZAAKPAY_MERCHANT_KEY;
// Use sandbox for testing if Merchant ID is placeholder, otherwise use configured URL
const configuredBaseUrl = process.env.ZAAKPAY_BASE_URL || 'https://zaakstaging.zaakpay.com';
// Auto-detect if Merchant ID is placeholder and switch to sandbox/mock
const isPlaceholderMerchantId = merchantId && (merchantId.includes('xxxx') || merchantId.includes('your_merchant') || merchantId.length < 20);
const baseUrl = isPlaceholderMerchantId ? 'https://zaakstaging.zaakpay.com' : configuredBaseUrl;
const isMockMode = process.env.ZAAKPAY_MOCK_MODE === 'true';

// Log configuration on module load
console.log('[ZaakpayClient] ========================================');
console.log('[ZaakpayClient] Configuration:');
console.log('[ZaakpayClient] - Base URL:', baseUrl);
if (isPlaceholderMerchantId) {
  console.warn('[ZaakpayClient] ⚠️  WARNING: Merchant ID appears to be placeholder!');
  console.warn('[ZaakpayClient] ⚠️  Switched to sandbox URL for testing');
  console.warn('[ZaakpayClient] ⚠️  To use live API, update ZAAKPAY_MERCHANT_ID with actual value from dashboard');
}
console.log('[ZaakpayClient] - Mock Mode:', isMockMode);
console.log('[ZaakpayClient] - Merchant ID:', merchantId ? (isPlaceholderMerchantId ? merchantId.substring(0, 10) + '... (PLACEHOLDER)' : merchantId.substring(0, 10) + '...') : 'NOT SET');
console.log('[ZaakpayClient] - Merchant Key:', merchantKey ? 'SET' : 'NOT SET');
console.log('[ZaakpayClient] - ZAAKPAY_CREATE_ORDER_PATH env:', process.env.ZAAKPAY_CREATE_ORDER_PATH || 'NOT SET');
console.log('[ZaakpayClient] ========================================');
// Zaakpay API endpoint paths
// Correct structure based on Zaakpay documentation:
// - Live (api.zaakpay.com): /api/v1/payment-transactions/createorder
// - Staging (zaakstaging.zaakpay.com): /api/v1/payment-transactions/createorder
// - Sandbox (sandbox.zaakpay.com): /api/v1/payment-transactions/createorder (or /api/ without v1)
const getEndpointPath = (pathSuffix) => {
  // Check for custom path override via env
  const customCreateOrder = process.env.ZAAKPAY_CREATE_ORDER_PATH;
  if (customCreateOrder && pathSuffix.includes('createorder')) {
    console.log('[ZaakpayClient] ⚠️  Found ZAAKPAY_CREATE_ORDER_PATH env var:', customCreateOrder);

    // FIX: Auto-correct if missing /v1/ for api.zaakpay.com
    let correctedPath = customCreateOrder;
    if (baseUrl.includes('api.zaakpay.com') || baseUrl.includes('zaakstaging.zaakpay.com')) {
      if (!customCreateOrder.includes('/api/v1/')) {
        // Fix the path by adding /v1/ if missing
        correctedPath = customCreateOrder.replace('/api/payment-transactions/', '/api/v1/payment-transactions/');
        console.error('[ZaakpayClient] ❌ ERROR: Custom path missing /v1/!');
        console.error('[ZaakpayClient] Original:', customCreateOrder);
        console.error('[ZaakpayClient] ✅ Auto-corrected to:', correctedPath);
      }
    }
    return correctedPath;
  }

  // ALWAYS use /api/v1/ prefix - this is the correct format for Zaakpay API
  // Based on Zaakpay documentation, all environments use /api/v1/
  const path = `/api/v1${pathSuffix}`;

  if (baseUrl.includes('api.zaakpay.com') || baseUrl.includes('zaakstaging.zaakpay.com')) {
    console.log('[ZaakpayClient] ✅ Using Live/Staging endpoint:', path);
  } else if (baseUrl.includes('sandbox.zaakpay.com')) {
    console.log('[ZaakpayClient] ✅ Using Sandbox endpoint:', path);
  } else {
    console.log('[ZaakpayClient] ✅ Using default endpoint:', path);
  }

  return path;
};

// Zaakpay API endpoints - FIXED to use correct paths
const endpoints = {
  createOrder: getEndpointPath('/payment-transactions/createorder'),
  transactionStatus: getEndpointPath('/payment-transactions/status'),
  refund: getEndpointPath('/payment-refunds/create'),
  refundStatus: getEndpointPath('/payment-refunds/status')
};

// CRITICAL: Validate and auto-fix all endpoints to ensure they have /api/v1/ for api.zaakpay.com
console.log('[ZaakpayClient] ========================================');
console.log('[ZaakpayClient] Validating and fixing endpoint paths...');
Object.entries(endpoints).forEach(([name, path]) => {
  if (baseUrl.includes('api.zaakpay.com') || baseUrl.includes('zaakstaging.zaakpay.com')) {
    if (!path.includes('/api/v1/')) {
      console.error(`[ZaakpayClient] ❌ ERROR: ${name} endpoint missing /api/v1/!`);
      console.error(`[ZaakpayClient] Current: ${path}`);
      // Auto-fix it by adding /v1/
      let fixedPath = path;
      if (path.includes('/api/payment-transactions/')) {
        fixedPath = path.replace('/api/payment-transactions/', '/api/v1/payment-transactions/');
      } else if (path.includes('/api/payment-refunds/')) {
        fixedPath = path.replace('/api/payment-refunds/', '/api/v1/payment-refunds/');
      } else if (path.startsWith('/payment-transactions/')) {
        fixedPath = '/api/v1' + path;
      } else if (path.startsWith('/payment-refunds/')) {
        fixedPath = '/api/v1' + path;
      }
      console.error(`[ZaakpayClient] ✅ Auto-fixed to: ${fixedPath}`);
      // Update the endpoint in the object
      endpoints[name] = fixedPath;
    } else {
      console.log(`[ZaakpayClient] ✅ ${name}: ${path}`);
    }
  } else {
    console.log(`[ZaakpayClient] ✅ ${name}: ${path}`);
  }
});
console.log('[ZaakpayClient] ========================================');
const ensureCredentials = () => {
  if (isMockMode) return;
  if (!merchantId || !merchantKey) {
    throw new Error('Zaakpay merchant credentials are not configured');
  }
};
const resolveUrl = (endpoint) => {
  if (!endpoint) throw new Error('Zaakpay endpoint is required');
  if (/^https?:\/\//.test(endpoint)) {
    // Already a full URL, return as-is
    return endpoint;
  }

  // Remove leading slash from endpoint
  let cleanEndpoint = endpoint.replace(/^\//, '');
  const cleanBaseUrl = baseUrl.replace(/\/$/, '');

  // IMPORTANT: Never remove /api/ or /api/v1/ from endpoint!
  // The endpoint path from getEndpointPath() is already correct
  // Just construct the full URL
  const fullUrl = `${cleanBaseUrl}/${cleanEndpoint}`;

  // Validate the URL structure
  if (cleanBaseUrl.includes('api.zaakpay.com')) {
    if (!fullUrl.includes('/api/v1/')) {
      console.error('[ZaakpayClient] ❌ ERROR: api.zaakpay.com URL missing /api/v1/ prefix!');
      console.error('[ZaakpayClient] Current URL:', fullUrl);
      console.error('[ZaakpayClient] Expected format: https://api.zaakpay.com/api/v1/payment-transactions/createorder');
    }
  }

  console.log('[ZaakpayClient] Resolved URL:', fullUrl);
  console.log('[ZaakpayClient] Base URL:', cleanBaseUrl);
  console.log('[ZaakpayClient] Endpoint Path:', cleanEndpoint);
  return fullUrl;
};
const buildHeaders = () => ({
  'Content-Type': 'application/json'
});
const mockResponse = (type, payload = {}) => {
  const now = new Date().toISOString();
  switch (type) {
    case 'createOrder':
      return {
        status: 'MOCK_SUCCESS',
        orderId: payload.orderId,
        amount: payload.amount,
        checksum: generateChecksum(payload, merchantKey || 'mock-key'),
        paymentUrl: 'https://mock.zaakpay.com/pay',
        createdAt: now
      };
    case 'transactionStatus':
      return {
        status: 'MOCK_SUCCESS',
        orderId: payload.orderId,
        pgTxnId: 'MOCKTXN123',
        amount: payload.amount || 0,
        txnStatus: 'SUCCESS',
        fetchedAt: now
      };
    case 'refund':
      return {
        status: 'MOCK_SUCCESS',
        refundId: payload.refundId || `RFND-${Date.now()}`,
        orderId: payload.orderId,
        refundStatus: 'SUCCESS',
        amount: payload.refundAmount,
        createdAt: now
      };
    case 'refundStatus':
      return {
        status: 'MOCK_SUCCESS',
        refundId: payload.refundId,
        refundStatus: 'SUCCESS',
        fetchedAt: now
      };
    default:
      return { status: 'MOCK', payload };
  }
};
const sendSignedRequest = async (endpoint, payload = {}) => {
  ensureCredentials();
  const sanitizedPayload = sanitizePayload({
    merchantIdentifier: merchantId,
    ...payload
  });
  const checksum = generateChecksum(sanitizedPayload, merchantKey || '');
  const requestBody = {
    ...sanitizedPayload,
    checksum
  };
  const url = resolveUrl(endpoint);
  console.log('[ZaakpayClient] ========================================');
  console.log('[ZaakpayClient] Making request to Zaakpay API:');
  console.log('[ZaakpayClient] URL:', url);
  console.log('[ZaakpayClient] Method: POST');
  console.log('[ZaakpayClient] Request payload keys:', Object.keys(requestBody));
  console.log('[ZaakpayClient] Merchant ID:', merchantId?.substring(0, 15) + '...');

  // CRITICAL: Validate URL and credentials before making request
  if (baseUrl.includes('api.zaakpay.com') && !url.includes('/api/v1/')) {
    console.error('[ZaakpayClient] ❌❌❌ CRITICAL: URL missing /v1/ - this will cause 404!');
    console.error('[ZaakpayClient] Current URL:', url);
    throw new Error('Zaakpay endpoint URL is incorrect - missing /v1/ prefix');
  }

  if (isPlaceholderMerchantId && baseUrl.includes('api.zaakpay.com')) {
    console.error('[ZaakpayClient] ❌❌❌ CRITICAL ERROR: Using placeholder Merchant ID with live API!');
    console.error('[ZaakpayClient] This will cause 404 or authentication error!');
    console.error('[ZaakpayClient] Solution: Update ZAAKPAY_MERCHANT_ID with actual value from dashboard');
    console.error('[ZaakpayClient] OR enable mock mode: ZAAKPAY_MOCK_MODE=true');
    console.error('[ZaakpayClient] OR use sandbox: ZAAKPAY_BASE_URL=https://sandbox.zaakpay.com');
  }

  try {
    console.log('[ZaakpayClient] Sending request...');
    const { data } = await axios.post(url, requestBody, { headers: buildHeaders() });
    console.log('[ZaakpayClient] ✅ Request successful!');
    console.log('[ZaakpayClient] Response:', JSON.stringify(data, null, 2));
    console.log('[ZaakpayClient] ========================================');
    return data;
  } catch (error) {
    console.error('[ZaakpayClient] ========================================');
    console.error('[ZaakpayClient] ❌ Request FAILED!');
    console.error('[ZaakpayClient] URL that failed:', url);
    console.error('[ZaakpayClient] Status:', error.response?.status);
    console.error('[ZaakpayClient] Status Text:', error.response?.statusText);
    console.error('[ZaakpayClient] Response Data:', error.response?.data);
    console.error('[ZaakpayClient] Error Message:', error.message);
    if (error.response?.status === 404) {
      console.error('[ZaakpayClient] ========================================');
      console.error('[ZaakpayClient] 404 ERROR DIAGNOSIS:');
      console.error('[ZaakpayClient] Possible causes:');
      if (isPlaceholderMerchantId) {
        console.error('[ZaakpayClient] 1. ❌ Merchant ID is placeholder - Update with actual value from dashboard');
      }
      console.error('[ZaakpayClient] 2. Endpoint URL might be wrong - Current:', url);
      console.error('[ZaakpayClient] 3. Merchant account might not be activated for this API');
      console.error('[ZaakpayClient] 4. Try using sandbox URL: ZAAKPAY_BASE_URL=https://sandbox.zaakpay.com');
      console.error('[ZaakpayClient] 5. Or enable mock mode: ZAAKPAY_MOCK_MODE=true');
      console.error('[ZaakpayClient] ========================================');
    }
    throw new Error(`Zaakpay API error: ${error.response?.status || 'Network Error'} - ${error.response?.data?.message || error.message || 'Unknown error'}`);
  }
};
const createOrder = async (payload = {}) => {
  console.log('[ZaakpayClient] ========================================');
  console.log('[ZaakpayClient] ========== createOrder called ==========');
  console.log('[ZaakpayClient] Mock Mode:', isMockMode);
  console.log('[ZaakpayClient] Base URL:', baseUrl);
  console.log('[ZaakpayClient] Endpoint path:', endpoints.createOrder);
  const expectedUrl = `${baseUrl.replace(/\/$/, '')}/${endpoints.createOrder.replace(/^\//, '')}`;
  console.log('[ZaakpayClient] Expected full URL:', expectedUrl);

  // CRITICAL CHECK: Verify endpoint has /v1/ for api.zaakpay.com
  if (baseUrl.includes('api.zaakpay.com') && !endpoints.createOrder.includes('/api/v1/')) {
    console.error('[ZaakpayClient] ❌❌❌ CRITICAL ERROR: Endpoint missing /v1/!');
    console.error('[ZaakpayClient] Current endpoint:', endpoints.createOrder);
    console.error('[ZaakpayClient] This will cause 404 error!');
    // Force fix it
    endpoints.createOrder = endpoints.createOrder.replace('/api/payment-transactions/', '/api/v1/payment-transactions/');
    console.error('[ZaakpayClient] ✅ Force-fixed to:', endpoints.createOrder);
  }

  if (isMockMode) {
    console.log('[ZaakpayClient] Using MOCK mode - returning mock response');
    return mockResponse('createOrder', payload);
  }
  console.log('[ZaakpayClient] Using REAL Zaakpay API');
  console.log('[ZaakpayClient] ========================================');
  return sendSignedRequest(endpoints.createOrder, payload);
};
const getTransactionStatus = async (payload = {}) => {
  if (isMockMode) return mockResponse('transactionStatus', payload);
  return sendSignedRequest(endpoints.transactionStatus, payload);
};
const createRefund = async (payload = {}) => {
  if (isMockMode) return mockResponse('refund', payload);
  return sendSignedRequest(endpoints.refund, payload);
};
const getRefundStatus = async (payload = {}) => {
  if (isMockMode) return mockResponse('refundStatus', payload);
  return sendSignedRequest(endpoints.refundStatus, payload);
};
module.exports = {
  createOrder,
  getTransactionStatus,
  createRefund,
  getRefundStatus
};
