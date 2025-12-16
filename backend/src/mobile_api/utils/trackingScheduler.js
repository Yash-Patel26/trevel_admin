const vehicleTrackingService = require('../services/vehicleTrackingService');
let syncInterval = null;
let isRunning = false;
function startTrackingSync(intervalMs = 60000) {
if (isRunning) {
return;
}
runSync();
syncInterval = setInterval(() => {
runSync();
}, intervalMs);
isRunning = true;
}
function stopTrackingSync() {
if (syncInterval) {
clearInterval(syncInterval);
syncInterval = null;
isRunning = false;
}
}
async function runSync() {
try {
const result = await vehicleTrackingService.syncVehiclePositions({
checkHubRadius: true,
storeHistory: true
});
if (result.hubEvents.length > 0) {
}
} catch (error) {
}
}
function getSyncStatus() {
return {
isRunning,
interval: syncInterval ? (syncInterval._idleTimeout || 'unknown') : null
};
}
module.exports = {
startTrackingSync,
stopTrackingSync,
runSync,
getSyncStatus
};
