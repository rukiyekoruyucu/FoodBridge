// src/config/firebase.js
const admin = require("firebase-admin");
const logger = require("../utils/logger");

if (!admin.apps.length) {
  let credential;

  // Önce FIREBASE_PRIVATE_KEY env var'ından oku (Railway/production ortamı)
  const privateKeyEnv = process.env.FIREBASE_PRIVATE_KEY;
  if (privateKeyEnv) {
    const serviceAccount = {
      type: "service_account",
      project_id: process.env.FIREBASE_PROJECT_ID,
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
      private_key: privateKeyEnv.replace(/\\n/g, "\n"),
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
      client_id: process.env.FIREBASE_CLIENT_ID,
      auth_uri: "https://accounts.google.com/o/oauth2/auth",
      token_uri: "https://oauth2.googleapis.com/token",
      auth_provider_x509_cert_url:
        "https://www.googleapis.com/oauth2/v1/certs",
      client_x509_cert_url: process.env.FIREBASE_CLIENT_CERT_URL,
      universe_domain: "googleapis.com",
    };
    credential = admin.credential.cert(serviceAccount);
    logger.info("Firebase Admin: env variable'lardan başlatıldı.");
  } else {
    // Local geliştirme ortamı: firebase_key.json dosyasından oku
    try {
      const serviceAccount = require("./firebase_key.json");
      credential = admin.credential.cert(serviceAccount);
      logger.info("Firebase Admin: firebase_key.json'dan başlatıldı.");
    } catch (e) {
      logger.error(
        "Firebase başlatılamadı: ne FIREBASE_PRIVATE_KEY env var'ı ne de firebase_key.json bulundu."
      );
      throw e;
    }
  }

  admin.initializeApp({ credential });
} else {
  logger.info("Firebase Admin zaten başlatılmıştı.");
}

module.exports = admin;