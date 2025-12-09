// foodbridge-backend/src/config/firebase.js (Güncellenmiş Versiyon)

const admin = require('firebase-admin');
const path = require('path');

// Service Account dosyasının içeriğini yükle
const serviceAccountPath = path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH);
let serviceAccount;

try {
    // 1. JSON dosyasının içeriğini oku ve bir JavaScript objesi olarak yükle
    serviceAccount = require(serviceAccountPath);
} catch (err) {
    console.error(`❌ HATA: Firebase Service Account dosyası (${serviceAccountPath}) yüklenirken hata oluştu.`, err.message);
    process.exit(1);
}

// Firebase Admin SDK'yı Başlat
try {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        // 🚨 KRİTİK EKLEME: Proje kimliğini burada açıkça belirtiyoruz.
        projectId: process.env.FIREBASE_PROJECT_ID
    });
    console.log('✅ Firebase Admin SDK başarıyla başlatıldı.');
} catch (error) {
    if (!admin.apps.length) {
        console.error('❌ Firebase Admin SDK başlatma hatası:', error.message);
    }
}

module.exports = admin;