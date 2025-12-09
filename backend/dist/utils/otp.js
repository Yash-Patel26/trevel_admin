"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateOtp = generateOtp;
function generateOtp() {
    const num = Math.floor(1000 + Math.random() * 9000);
    return String(num);
}
