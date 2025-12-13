// Simple SMS service for development
// In production, integrate with your preferred SMS provider

export const smsService = {
    sendOtpMessage: async ({ phone, name, otp }: { phone: string; name?: string; otp: string }) => {
        // For development: Log OTP to console
        console.log("\n" + "=".repeat(70));
        console.log("📱 OTP MESSAGE");
        console.log("=".repeat(70));
        console.log(`To: ${phone}`);
        console.log(`Name: ${name || 'N/A'}`);
        console.log(`OTP: ${otp}`);
        console.log(`Message: Your OTP for Trevel is ${otp}. Valid for 5 minutes.`);
        console.log("=".repeat(70) + "\n");

        // In production, replace this with actual SMS API call
        // Example: await twilioClient.messages.create({ ... })

        return { success: true, mode: 'development' };
    },

    sendTextMessage: async ({ phone, message }: { phone: string; message: string }) => {
        // For development: Log message to console
        console.log("\n" + "=".repeat(70));
        console.log("📱 TEXT MESSAGE");
        console.log("=".repeat(70));
        console.log(`To: ${phone}`);
        console.log(`Message: ${message}`);
        console.log("=".repeat(70) + "\n");

        // In production, replace this with actual SMS API call

        return { success: true, mode: 'development' };
    }
};
