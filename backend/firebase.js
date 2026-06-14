const admin = require("firebase-admin");

if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
    throw new Error(
        "FIREBASE_SERVICE_ACCOUNT environment variable is missing"
    );
}

// Prevent re-initialization (VERY IMPORTANT in production)
if (!admin.apps.length) {
    const serviceAccount = JSON.parse(
        process.env.FIREBASE_SERVICE_ACCOUNT
    );

    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
    });
}

module.exports = admin;