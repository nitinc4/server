let admin = null;
let isConfigured = false;

try {
  // Gracefully handle if firebase-admin is not yet installed (i.e. before user runs npm install)
  const firebaseAdmin = require('firebase-admin');

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  let privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (projectId && clientEmail && privateKey) {
    // If the key is base64 encoded to avoid hosting platform parsing issues
    if (!privateKey.includes('BEGIN PRIVATE KEY')) {
      try {
        privateKey = Buffer.from(privateKey, 'base64').toString('utf8');
      } catch (e) {
        // Fallback to regular parsing if not base64
      }
    }

    // Handle newline character escaping in the private key if needed
    if (privateKey.startsWith('"') && privateKey.endsWith('"')) {
      privateKey = privateKey.substring(1, privateKey.length - 1);
    }
    privateKey = privateKey.replace(/\\n/g, '\n');

    firebaseAdmin.initializeApp({
      credential: firebaseAdmin.credential.cert({
        projectId: projectId,
        clientEmail: clientEmail,
        privateKey: privateKey,
      }),
    });

    admin = firebaseAdmin;
    isConfigured = true;
    console.log('[FCM] Firebase Admin SDK successfully initialized using environment variables.');
  } else {
    console.log('[FCM] Firebase credentials not fully set in .env. Running in MOCK notification mode.');
  }
} catch (error) {
  if (error.code === 'MODULE_NOT_FOUND') {
    console.log('[FCM] firebase-admin package is not installed. Running in MOCK notification mode. Please run "npm install" once you are ready.');
  } else {
    console.error('[FCM] Error initializing Firebase Admin SDK:', error.message);
    console.log('[FCM] Running in MOCK notification mode.');
  }
}

module.exports = {
  admin,
  isConfigured,
};
