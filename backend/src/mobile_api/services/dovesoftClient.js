const axios = require('axios');
const REQUIRED_ENV_VARS = [
'DOVESOFT_API_KEY',
'DOVESOFT_WABA_NUMBER',
'DOVESOFT_OTP_TEMPLATE_NAME'
];
const ensureConfig = () => {
const missing = REQUIRED_ENV_VARS.filter((key) => !process.env[key]);
if (missing.length) {
throw new Error(
`DoveSoft environment variables missing: ${missing.join(', ')}. Please configure in .env file.`
);
}
};
const getBaseUrl = () => {
return process.env.DOVESOFT_BASE_URL || 'https://speqtrainnov.in/REST/directApi';
};
const buildHeaders = () => ({
'Key': process.env.DOVESOFT_API_KEY,
'wabaNumber': process.env.DOVESOFT_WABA_NUMBER,
'content-type': 'application/json'
});
const sendOtpMessage = async ({ phone, name, otp }) => {
// Check config but don't crash - return gracefully if not configured
const missing = REQUIRED_ENV_VARS.filter((key) => !process.env[key]);
if (missing.length) {
// In production, you might want to throw, but for serverless environments, we'll allow it
if (process.env.NODE_ENV === 'production' && process.env.REQUIRE_DOVESOFT === 'true') {
throw new Error(`DoveSoft environment variables missing: ${missing.join(', ')}`);
}
return { success: false, message: 'DoveSoft not configured' };
}
if (!phone || !otp) {
throw new Error('DoveSoft send requires phone and otp');
}
let cleanPhone = phone.replace(/[\s-]/g, '');
if (!cleanPhone.startsWith('+')) {
if (cleanPhone.startsWith('0')) {
cleanPhone = cleanPhone.substring(1);
}
if (cleanPhone.length === 10) {
cleanPhone = '+91' + cleanPhone;
} else {
cleanPhone = '+' + cleanPhone;
}
}
const templateName = process.env.DOVESOFT_OTP_TEMPLATE_NAME;
let templateBody = null;
try {
const templateResponse = await getTemplate(templateName);
if (templateResponse?.data && templateResponse.data.length > 0) {
templateBody = templateResponse.data[0];
}
} catch (error) {
}
const payload = {
messaging_product: "whatsapp",
to: cleanPhone,
type: "template",
template: {
name: templateName,
language: {
code: process.env.DOVESOFT_TEMPLATE_LANGUAGE || "en"
}
}
};
if (templateBody?.components) {
payload.template.components = templateBody.components.map(comp => {
if (comp.type === "BODY") {
return {
type: "BODY",
parameters: [
{
type: "text",
text: otp
}
]
};
}
return comp;
});
} else {
payload.template.components = [
{
type: "BODY",
parameters: [
{
type: "text",
text: otp
}
]
}
];
}
try {
const url = `${getBaseUrl()}/message`;
const { data } = await axios.post(url, payload, {
headers: buildHeaders(),
timeout: Number(process.env.DOVESOFT_TIMEOUT_MS || 10000)
});
return data;
} catch (error) {
const details = error.response?.data;
const message =
details?.message || details?.error || error.message || 'Unknown error';
const err = new Error(`DoveSoft send failed: ${message}`);
err.status = error.response?.status;
err.details = details;
throw err;
}
};
const sendTextMessage = async ({ phone, message }) => {
ensureConfig();
if (!phone || !message) {
throw new Error('DoveSoft send requires phone and message');
}
let cleanPhone = phone.replace(/[\s-]/g, '');
if (!cleanPhone.startsWith('+')) {
if (cleanPhone.startsWith('0')) {
cleanPhone = cleanPhone.substring(1);
}
if (cleanPhone.length === 10) {
cleanPhone = '+91' + cleanPhone;
} else {
cleanPhone = '+' + cleanPhone;
}
}
const payload = {
messaging_product: "whatsapp",
to: cleanPhone,
type: "text",
recipient_type: "individual",
text: {
body: message
}
};
try {
const url = `${getBaseUrl()}/message`;
const { data } = await axios.post(url, payload, {
headers: buildHeaders(),
timeout: Number(process.env.DOVESOFT_TIMEOUT_MS || 10000)
});
return data;
} catch (error) {
const details = error.response?.data;
const message =
details?.message || details?.error || error.message || 'Unknown error';
const err = new Error(`DoveSoft text send failed: ${message}`);
err.status = error.response?.status;
err.details = details;
throw err;
}
};
const getTemplate = async (templateName) => {
ensureConfig();
try {
const url = `${getBaseUrl()}/getTemplate/${templateName}`;
const { data } = await axios.get(url, {
headers: buildHeaders(),
timeout: Number(process.env.DOVESOFT_TIMEOUT_MS || 10000)
});
return data;
} catch (error) {
const details = error.response?.data;
const message =
details?.message || details?.error || error.message || 'Unknown error';
const err = new Error(`DoveSoft get template failed: ${message}`);
err.status = error.response?.status;
err.details = details;
throw err;
}
};
const cleanPhoneNumber = (phone) => {
let cleanPhone = phone.replace(/[\s-]/g, '');
if (!cleanPhone.startsWith('+')) {
if (cleanPhone.startsWith('0')) {
cleanPhone = cleanPhone.substring(1);
}
if (cleanPhone.length === 10) {
cleanPhone = '+91' + cleanPhone;
} else {
cleanPhone = '+' + cleanPhone;
}
}
return cleanPhone;
};
const createTemplate = async (templateData) => {
ensureConfig();
if (!templateData || !templateData.name || !templateData.category || !templateData.components) {
throw new Error('Template data must include name, category, and components');
}
try {
const url = `${getBaseUrl()}/template/createTemplate`;
const { data } = await axios.post(url, templateData, {
headers: buildHeaders(),
timeout: Number(process.env.DOVESOFT_TIMEOUT_MS || 10000)
});
return data;
} catch (error) {
const details = error.response?.data;
const message =
details?.message || details?.error || error.message || 'Unknown error';
const err = new Error(`DoveSoft create template failed: ${message}`);
err.status = error.response?.status;
err.details = details;
throw err;
}
};
const getTemplateList = async () => {
ensureConfig();
try {
const url = `${getBaseUrl()}/getTemplateList`;
const { data } = await axios.post(url, {}, {
headers: buildHeaders(),
timeout: Number(process.env.DOVESOFT_TIMEOUT_MS || 10000)
});
return data;
} catch (error) {
const details = error.response?.data;
const message =
details?.message || details?.error || error.message || 'Unknown error';
const err = new Error(`DoveSoft get template list failed: ${message}`);
err.status = error.response?.status;
err.details = details;
throw err;
}
};
const getTemplateByNameOrId = async (templateNameOrId) => {
ensureConfig();
try {
const url = `${getBaseUrl()}/getTemplate/${templateNameOrId}`;
const { data } = await axios.get(url, {
headers: buildHeaders(),
timeout: Number(process.env.DOVESOFT_TIMEOUT_MS || 10000)
});
return data;
} catch (error) {
try {
const url = `${getBaseUrl()}/getTemplate`;
const { data } = await axios.post(url, {
templatename: templateNameOrId
}, {
headers: buildHeaders(),
timeout: Number(process.env.DOVESOFT_TIMEOUT_MS || 10000)
});
return data;
} catch (postError) {
const details = error.response?.data || postError.response?.data;
const message =
details?.message || details?.error || error.message || postError.message || 'Unknown error';
const err = new Error(`DoveSoft get template failed: ${message}`);
err.status = error.response?.status || postError.response?.status;
err.details = details;
throw err;
}
}
};
const editTemplate = async (templateId, updateData) => {
ensureConfig();
if (!templateId || !updateData) {
throw new Error('Template ID and update data are required');
}
try {
const url = `${getBaseUrl()}/editTemplateById/${templateId}`;
const { data } = await axios.post(url, updateData, {
headers: buildHeaders(),
timeout: Number(process.env.DOVESOFT_TIMEOUT_MS || 10000)
});
return data;
} catch (error) {
const details = error.response?.data;
const message =
details?.message || details?.error || error.message || 'Unknown error';
const err = new Error(`DoveSoft edit template failed: ${message}`);
err.status = error.response?.status;
err.details = details;
throw err;
}
};
const deleteTemplate = async (templateName) => {
ensureConfig();
if (!templateName) {
throw new Error('Template name is required');
}
try {
const url = `${getBaseUrl()}/deleteTemplate?templateName=${encodeURIComponent(templateName)}`;
const { data } = await axios.post(url, {}, {
headers: buildHeaders(),
timeout: Number(process.env.DOVESOFT_TIMEOUT_MS || 10000)
});
return data;
} catch (error) {
const details = error.response?.data;
const message =
details?.message || details?.error || error.message || 'Unknown error';
const err = new Error(`DoveSoft delete template failed: ${message}`);
err.status = error.response?.status;
err.details = details;
throw err;
}
};
const sendImage = async ({ phone, imageUrl, caption }) => {
ensureConfig();
if (!phone || !imageUrl) {
throw new Error('Phone and image URL are required');
}
const cleanPhone = cleanPhoneNumber(phone);
const payload = {
messaging_product: "whatsapp",
to: cleanPhone,
type: "image",
image: {
link: imageUrl
}
};
if (caption) {
payload.image.caption = caption;
}
try {
const url = `${getBaseUrl()}/message`;
const { data } = await axios.post(url, payload, {
headers: buildHeaders(),
timeout: Number(process.env.DOVESOFT_TIMEOUT_MS || 10000)
});
return data;
} catch (error) {
const details = error.response?.data;
const message =
details?.message || details?.error || error.message || 'Unknown error';
const err = new Error(`DoveSoft send image failed: ${message}`);
err.status = error.response?.status;
err.details = details;
throw err;
}
};
const sendVideo = async ({ phone, videoUrl, caption }) => {
ensureConfig();
if (!phone || !videoUrl) {
throw new Error('Phone and video URL are required');
}
const cleanPhone = cleanPhoneNumber(phone);
const payload = {
messaging_product: "whatsapp",
to: cleanPhone,
type: "video",
video: {
link: videoUrl
}
};
if (caption) {
payload.video.caption = caption;
}
try {
const url = `${getBaseUrl()}/message`;
const { data } = await axios.post(url, payload, {
headers: buildHeaders(),
timeout: Number(process.env.DOVESOFT_TIMEOUT_MS || 10000)
});
return data;
} catch (error) {
const details = error.response?.data;
const message =
details?.message || details?.error || error.message || 'Unknown error';
const err = new Error(`DoveSoft send video failed: ${message}`);
err.status = error.response?.status;
err.details = details;
throw err;
}
};
const sendAudio = async ({ phone, audioUrl }) => {
ensureConfig();
if (!phone || !audioUrl) {
throw new Error('Phone and audio URL are required');
}
const cleanPhone = cleanPhoneNumber(phone);
const payload = {
messaging_product: "whatsapp",
to: cleanPhone,
type: "audio",
audio: {
link: audioUrl
}
};
try {
const url = `${getBaseUrl()}/message`;
const { data } = await axios.post(url, payload, {
headers: buildHeaders(),
timeout: Number(process.env.DOVESOFT_TIMEOUT_MS || 10000)
});
return data;
} catch (error) {
const details = error.response?.data;
const message =
details?.message || details?.error || error.message || 'Unknown error';
const err = new Error(`DoveSoft send audio failed: ${message}`);
err.status = error.response?.status;
err.details = details;
throw err;
}
};
const sendDocument = async ({ phone, documentUrl, filename, caption }) => {
ensureConfig();
if (!phone || !documentUrl) {
throw new Error('Phone and document URL are required');
}
const cleanPhone = cleanPhoneNumber(phone);
const payload = {
messaging_product: "whatsapp",
to: cleanPhone,
type: "document",
document: {
link: documentUrl
}
};
if (filename) {
payload.document.filename = filename;
}
if (caption) {
payload.document.caption = caption;
}
try {
const url = `${getBaseUrl()}/message`;
const { data } = await axios.post(url, payload, {
headers: buildHeaders(),
timeout: Number(process.env.DOVESOFT_TIMEOUT_MS || 10000)
});
return data;
} catch (error) {
const details = error.response?.data;
const message =
details?.message || details?.error || error.message || 'Unknown error';
const err = new Error(`DoveSoft send document failed: ${message}`);
err.status = error.response?.status;
err.details = details;
throw err;
}
};
const sendList = async ({ phone, headerText, bodyText, footerText, buttonText, sections }) => {
ensureConfig();
if (!phone || !bodyText || !buttonText || !sections || !Array.isArray(sections)) {
throw new Error('Phone, body text, button text, and sections array are required');
}
const cleanPhone = cleanPhoneNumber(phone);
const payload = {
messaging_product: "whatsapp",
recipient_type: "individual",
to: cleanPhone,
type: "interactive",
interactive: {
type: "list",
body: {
text: bodyText
},
action: {
button: buttonText,
sections: sections
}
}
};
if (headerText) {
payload.interactive.header = {
type: "text",
text: headerText
};
}
if (footerText) {
payload.interactive.footer = {
text: footerText
};
}
try {
const url = `${getBaseUrl()}/message`;
const { data } = await axios.post(url, payload, {
headers: buildHeaders(),
timeout: Number(process.env.DOVESOFT_TIMEOUT_MS || 10000)
});
return data;
} catch (error) {
const details = error.response?.data;
const message =
details?.message || details?.error || error.message || 'Unknown error';
const err = new Error(`DoveSoft send list failed: ${message}`);
err.status = error.response?.status;
err.details = details;
throw err;
}
};
const sendButton = async ({ phone, bodyText, buttons }) => {
ensureConfig();
if (!phone || !bodyText || !buttons || !Array.isArray(buttons)) {
throw new Error('Phone, body text, and buttons array are required');
}
const cleanPhone = cleanPhoneNumber(phone);
const payload = {
messaging_product: "whatsapp",
recipient_type: "individual",
to: cleanPhone,
type: "interactive",
interactive: {
type: "button",
body: {
text: bodyText
},
action: {
buttons: buttons.map(btn => ({
type: "reply",
reply: {
id: btn.id,
title: btn.title
}
}))
}
}
};
try {
const url = `${getBaseUrl()}/message`;
const { data } = await axios.post(url, payload, {
headers: buildHeaders(),
timeout: Number(process.env.DOVESOFT_TIMEOUT_MS || 10000)
});
return data;
} catch (error) {
const details = error.response?.data;
const message =
details?.message || details?.error || error.message || 'Unknown error';
const err = new Error(`DoveSoft send button failed: ${message}`);
err.status = error.response?.status;
err.details = details;
throw err;
}
};
const downloadAttachmentFile = async (mediaId) => {
ensureConfig();
if (!mediaId) {
throw new Error('Media ID is required');
}
try {
const url = `${getBaseUrl()}/downloadAttachmentFile`;
const { data } = await axios.post(url, {
mediaId: mediaId
}, {
headers: buildHeaders(),
timeout: Number(process.env.DOVESOFT_TIMEOUT_MS || 10000),
responseType: 'arraybuffer'
});
return data;
} catch (error) {
const details = error.response?.data;
const message =
details?.message || details?.error || error.message || 'Unknown error';
const err = new Error(`DoveSoft download attachment failed: ${message}`);
err.status = error.response?.status;
err.details = details;
throw err;
}
};
module.exports = {
sendOtpMessage,
sendTextMessage,
getTemplate,
createTemplate,
getTemplateList,
getTemplateByNameOrId,
editTemplate,
deleteTemplate,
sendImage,
sendVideo,
sendAudio,
sendDocument,
sendList,
sendButton,
downloadAttachmentFile
};
