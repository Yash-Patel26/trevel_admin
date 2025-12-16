import admin from 'firebase-admin';
import path from 'path';

let firebaseInitialized = false;

export function initializeFirebase() {
    if (firebaseInitialized) {
        return;
    }

    try {
        const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
        const firebaseProjectId = process.env.FIREBASE_PROJECT_ID;

        if (!serviceAccountPath && !firebaseProjectId) {
            console.warn("Firebase credentials not found in environment variables.");
            return;
        }

        if (serviceAccountPath) {
            // eslint-disable-next-line @typescript-eslint/no-var-requires
            const serviceAccount = require(path.resolve(process.cwd(), serviceAccountPath));
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
            });
        } else if (firebaseProjectId) {
            admin.initializeApp({
                projectId: firebaseProjectId,
            });
        }

        firebaseInitialized = true;
        console.log("Firebase initialized successfully");
    } catch (error) {
        console.error("Failed to initialize Firebase:", error);
    }
}

export const firebaseAdmin = admin;
