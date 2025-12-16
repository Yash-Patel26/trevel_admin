const axios = require('axios');
const BOLT_PULL_API_URL = process.env.BOLT_PULL_API_URL || 'https://pullapi-s2.track360.co.in/api/v1/auth/pull_api';
const BOLT_USERNAME = process.env.BOLT_USERNAME || '';
const BOLT_PASSWORD = process.env.BOLT_PASSWORD || '';
async function getAllDevices(username = null, password = null) {
try {
const params = {
username: username || BOLT_USERNAME,
password: password || BOLT_PASSWORD
};
if (!params.username || !params.password) {
throw new Error('Bolt API credentials (username and password) are required');
}
const response = await axios.get(BOLT_PULL_API_URL, {
params,
headers: {
'Accept': 'application/json'
}
});
if (response.data.status !== 'success') {
throw new Error(`Bolt API error: ${response.data.message || 'Unknown error'}`);
}
return response.data.data || [];
} catch (error) {
throw error;
}
}
async function getDeviceByName(deviceName, username = null, password = null) {
try {
if (!deviceName) {
throw new Error('Device name is required');
}
const params = {
username: username || BOLT_USERNAME,
password: password || BOLT_PASSWORD,
name: deviceName
};
if (!params.username || !params.password) {
throw new Error('Bolt API credentials (username and password) are required');
}
const response = await axios.get(BOLT_PULL_API_URL, {
params,
headers: {
'Accept': 'application/json'
}
});
if (response.data.status !== 'success') {
throw new Error(`Bolt API error: ${response.data.message || 'Unknown error'}`);
}
return response.data.data || null;
} catch (error) {
throw error;
}
}
async function getDeviceByImei(deviceImei, username = null, password = null) {
try {
if (!deviceImei) {
throw new Error('Device IMEI is required');
}
const params = {
username: username || BOLT_USERNAME,
password: password || BOLT_PASSWORD,
deviceImei: deviceImei
};
if (!params.username || !params.password) {
throw new Error('Bolt API credentials (username and password) are required');
}
const response = await axios.get(BOLT_PULL_API_URL, {
params,
headers: {
'Accept': 'application/json'
}
});
if (response.data.status !== 'success') {
throw new Error(`Bolt API error: ${response.data.message || 'Unknown error'}`);
}
return response.data.data || null;
} catch (error) {
throw error;
}
}
function parseDeviceData(device) {
if (!device) return null;
return {
deviceId: device.deviceId,
name: device.name,
deviceImei: device.deviceImei,
status: device.status,
latitude: parseFloat(device.latitude) || null,
longitude: parseFloat(device.longitude) || null,
lastUpdate: device.lastUpdate,
posId: device.posId,
phone: device.phone,
type: device.type,
deviceFixTime: device.deviceFixTime,
speed: parseFloat(device.speed) || 0,
course: parseFloat(device.course) || 0,
ignition: device.ignition,
totalDistance: parseFloat(device.totalDistance) || 0,
alarm: device.alarm
};
}
async function getAllDevicesParsed(username = null, password = null) {
try {
const devices = await getAllDevices(username, password);
return devices.map(parseDeviceData);
} catch (error) {
throw error;
}
}
module.exports = {
getAllDevices,
getDeviceByName,
getDeviceByImei,
parseDeviceData,
getAllDevicesParsed
};
