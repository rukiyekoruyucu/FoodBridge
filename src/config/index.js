// src/config/index.js

require("dotenv").config();

module.exports = {
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || "development",
  databasePath: process.env.DATABASE_PATH || "./data/foodbridge.db",
  // 🔥 Firebase Yapılandırması
  // Private Key artık buradan okunmuyor, doğrudan src/config/firebase.js dosyasında JSON key ile yükleniyor.
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  }
};