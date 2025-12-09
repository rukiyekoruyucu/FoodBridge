// foodbridge-backend/generate-token.js

// 1. Adım: .env dosyasındaki değişkenleri yükle
require('dotenv').config();

// 2. Adım: Firebase Admin SDK'yı yükle
// Projenizin yapısına göre path'i kontrol edin (config klasöründen yüklüyoruz)
const admin = require('./src/config/firebase');

// 🚨 KENDİ TEST UID'nizi BURAYA YAPIŞTIRIN!
// (Örn: Donor kullanıcınızın UID'si)
const targetUid = 'oVzVO8cFs2PmjgRQlN5PXEY15Zh2';

console.log(`\n🔑 UID için Custom Token oluşturuluyor: ${targetUid}`);

admin.auth().createCustomToken(targetUid)
    .then((customToken) => {
        console.log("\n--- CUSTOM TOKEN'INIZ (Bearer Token) ---\n");
        console.log(customToken);
        console.log("\n---------------------------------------\n");
        process.exit(0); // Başarılı çıkış
    })
    .catch((error) => {
        console.error("\n❌ Token oluşturulurken hata oluştu. Konfigürasyonu kontrol edin:", error.message);
        process.exit(1); // Hatalı çıkış
    });