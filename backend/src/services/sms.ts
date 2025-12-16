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

        if (twilioClient) {
            try {
                // If verify service SID is available, use verify API (more robust for OTPs)
                if (verifyServiceSid) {
                    // This requires a different flow (sendVerification), but for now let's stick to message creation
                    // or if the user intends to use the Verify API, we should use twilioClient.verify.v2.services(verifyServiceSid).verifications.create...
                    // Given the current generic "sendOtpMessage", sending a text is safer unless we refactor to use Verify API specifically.
                    // However, standard SMS via Twilio:
                    await twilioClient.messages.create({
                        body: message,
                        from: process.env.TWILIO_PHONE_NUMBER, // Ensure this env var exists found
                        to: phone
                    });
                    return { success: true, mode: 'twilio_sms' };
                } else {
                    // Fallback to standard SMS
                    await twilioClient.messages.create({
                        body: message,
                        from: process.env.TWILIO_PHONE_NUMBER,
                        to: phone
                    });
                    return { success: true, mode: 'twilio_sms' };
                }
            } catch (error) {
                console.error("Twilio Send Error:", error);
                // Fallback to console log if Twilio fails
            }
        }

        // Log to console for manual verification (fallback)
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
        if (twilioClient) {
            try {
                await twilioClient.messages.create({
                    body: message,
                    from: process.env.TWILIO_PHONE_NUMBER,
                    to: phone
                });
                return { success: true, mode: 'twilio_sms' };
            } catch (error) {
                console.error("Twilio Send Text Error:", error);
            }
        }

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
