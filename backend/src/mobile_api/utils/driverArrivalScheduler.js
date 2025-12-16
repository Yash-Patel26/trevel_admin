const { checkAllActiveBookings } = require('../services/driverArrivalNotificationService');
let intervalId = null;
let isRunning = false;
function startDriverArrivalMonitoring(intervalSeconds = 30) {
if (isRunning) {
return;
}
checkAllActiveBookings()
.then(result => {
})
.catch(error => {
});
intervalId = setInterval(async () => {
try {
const result = await checkAllActiveBookings();
} catch (error) {
}
}, intervalSeconds * 1000);
isRunning = true;
}
function stopDriverArrivalMonitoring() {
if (!isRunning) {
return;
}
if (intervalId) {
clearInterval(intervalId);
intervalId = null;
}
isRunning = false;
}
function isMonitoringRunning() {
return isRunning;
}
module.exports = {
startDriverArrivalMonitoring,
stopDriverArrivalMonitoring,
isMonitoringRunning
};
