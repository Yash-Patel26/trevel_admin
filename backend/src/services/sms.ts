import twilio from 'twilio';

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const verifyServiceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

let twilioClient: twilio.Twilio | null = null;

// Initialize Twilio client only if credentials are available
if (accountSid && authToken) {
    twilioClient = twilio(accountSid, authToken);
}

export const smsService = {
    sendOtpMessage: async ({ phone, name, otp }: { phone: string; name?: string; otp: string }) => {
        const message = `Your OTP for Trevel is ${otp}. Valid for 5 minutes.`;

        // Log to console for manual verification
        console.log("\n" + "=".repeat(70));
        console.log("📱 OTP MESSAGE");
        console.log("=".repeat(70));
        console.log(`To: ${phone}`);
        console.log(`Name: ${name || 'N/A'}`);
        console.log(`OTP: ${otp}`);
        console.log(`Message: ${message}`);
        console.log("=".repeat(70) + "\n");

        // Always return success immediately
        return { success: true, mode: 'console_log' };
    },

    sendTextMessage: async ({ phone, message }: { phone: string; message: string }) => {
        // Log to console for manual verification
        console.log("\n" + "=".repeat(70));
        console.log("📱 TEXT MESSAGE");
        console.log("=".repeat(70));
        console.log(`To: ${phone}`);
        console.log(`Message: ${message}`);
        console.log("=".repeat(70) + "\n");

        return { success: true, mode: 'console_log' };
    }
};
