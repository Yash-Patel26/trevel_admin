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
        
        // Development mode: Log to console
        console.log("\n" + "=".repeat(70));
        console.log("📱 OTP MESSAGE");
        console.log("=".repeat(70));
        console.log(`To: ${phone}`);
        console.log(`Name: ${name || 'N/A'}`);
        console.log(`OTP: ${otp}`);
        console.log(`Message: ${message}`);
        console.log("=".repeat(70) + "\n");

        // Production mode: Send via Twilio Verify API
        if (twilioClient && verifyServiceSid) {
            try {
                // Format phone number for international format
                const formattedPhone = phone.startsWith('+') ? phone : `+91${phone}`;
                
                // Use Twilio Verify API to send OTP
                const verification = await twilioClient.verify.v2
                    .services(verifyServiceSid)
                    .verifications
                    .create({ to: formattedPhone, channel: 'sms' });

                console.log(`✅ OTP sent successfully via Twilio Verify. Status: ${verification.status}`);
                return { success: true, mode: 'production', status: verification.status };
            } catch (error: any) {
                console.error('❌ Twilio Verify Error:', error.message);
                // Fallback to development mode on error
                return { success: true, mode: 'development_fallback', error: error.message };
            }
        }

        // No Twilio credentials: Development mode
        return { success: true, mode: 'development' };
    },

    sendTextMessage: async ({ phone, message }: { phone: string; message: string }) => {
        // Development mode: Log to console
        console.log("\n" + "=".repeat(70));
        console.log("📱 TEXT MESSAGE");
        console.log("=".repeat(70));
        console.log(`To: ${phone}`);
        console.log(`Message: ${message}`);
        console.log("=".repeat(70) + "\n");

        // For text messages, we still use the Messages API (not Verify)
        // This is for notifications, not OTPs
        if (twilioClient) {
            try {
                const formattedPhone = phone.startsWith('+') ? phone : `+91${phone}`;
                
                // Note: You need a Twilio phone number for this
                // For now, just log in development mode
                console.log('ℹ️  Text message sending requires TWILIO_PHONE_NUMBER in .env');
                return { success: true, mode: 'development' };
            } catch (error: any) {
                console.error('❌ Twilio SMS Error:', error.message);
                return { success: true, mode: 'development_fallback', error: error.message };
            }
        }

        return { success: true, mode: 'development' };
    }
};
