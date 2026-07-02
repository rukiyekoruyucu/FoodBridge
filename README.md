<div align="center">

<img src="app/assets/logo.png" alt="FoodBridge Logo" width="120" />

# 🌉 FoodBridge

**Gıda israfıyla savaşan, ihtiyaç sahipleriyle bağışçıları buluşturan topluluk platformu**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-20.x-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![SQLite](https://img.shields.io/badge/SQLite-WAL-003B57?logo=sqlite&logoColor=white)](https://sqlite.org)
[![Firebase](https://img.shields.io/badge/Firebase-Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Railway](https://img.shields.io/badge/Railway-Deployed-0B0D0E?logo=railway&logoColor=white)](https://railway.app)

[Canlı API](https://foodbridge-production-7403.up.railway.app/health) • [APK İndir](#apk-kurulumu) • [API Dokümantasyonu](#-api-referansı)

</div>

---

## 📋 İçindekiler

- [Proje Hakkında](#-proje-hakkında)
- [Özellikler](#-özellikler)
- [Ekran Görüntüleri](#-ekran-görüntüleri)
- [Teknoloji Yığını](#-teknoloji-yığını)
- [Proje Yapısı](#-proje-yapısı)
- [Kurulum](#-kurulum)
  - [Backend](#backend-kurulumu)
  - [Flutter App](#flutter-app-kurulumu)
- [APK Kurulumu](#apk-kurulumu)
- [Ortam Değişkenleri](#-ortam-değişkenleri)
- [API Referansı](#-api-referansı)
- [Kullanıcı Rolleri](#-kullanıcı-rolleri)
- [Veritabanı Şeması](#-veritabanı-şeması)
- [Katkıda Bulunma](#-katkıda-bulunma)

---

## 🌍 Proje Hakkında

**FoodBridge**, gıda israfını önlemek için bağışçıları (bireysel/kurumsal) ihtiyaç sahipleriyle buluşturan bir mobil+backend platformdur. Kullanıcılar:

- Fazla gıdalarını **ücretsiz** paylaşabilir
- Yakınlarındaki mevcut gıdaları **haritadan** keşfedebilir
- Doğrudan bağışçıyla **mesajlaşabilir**
- **Kindness Points** sistemiyle topluluk içinde takdir görebilir

---

## ✨ Özellikler

| Özellik | Açıklama |
|---------|---------|
| 🗺️ **Harita** | Çevredeki gıda noktalarını gerçek zamanlı haritada göster |
| 📦 **Bağış Akışı** | En yeni / en yakın modunda filtrelenebilir bağış listesi |
| 🧊 **Özel Buzdolabı** | Kişisel stok takibi ve son kullanma tarihi uyarıları |
| 💬 **Chat** | Bağışçı–ihtiyaç sahibi anlık mesajlaşma |
| 🏆 **Kindness Board** | En fazla bağış yapan kullanıcılar sıralaması |
| 🔒 **Firebase Auth** | Güvenli e-posta/şifre kimlik doğrulama |
| 🌙 **Dark Mode** | Tam dark/light tema desteği |
| 📤 **Cloudinary Upload** | Ürün fotoğrafı yükleme |
| 🔔 **Bildirimler** | Bağış durumu güncelleme bildirimleri |

---

## 📱 Ekran Görüntüleri

> Ekran görüntüleri yakında eklenecek.

---

## 🛠 Teknoloji Yığını

### Backend (`/` — root)
| Katman | Teknoloji |
|--------|-----------|
| Runtime | Node.js 20 + Express 5 |
| Veritabanı | SQLite 3 (better-sqlite3, WAL mode) |
| Auth | Firebase Admin SDK |
| Medya | Cloudinary |
| Deploy | Railway |
| Loglama | Winston |
| Validasyon | Joi |

### Mobile App (`/app`)
| Katman | Teknoloji |
|--------|-----------|
| Framework | Flutter 3.x (Dart) |
| State | Riverpod |
| Navigasyon | GoRouter (StatefulShellRoute) |
| HTTP | Dio + Auth Interceptor |
| Harita | Flutter Map + OpenStreetMap |
| Auth | Firebase Auth |
| Fonts | Google Fonts (Inter) |
| Animations | Shimmer loading |

---

## 📁 Proje Yapısı

```
FoodBridge/                         ← Monorepo kök
├── app/                            ← Flutter mobil uygulama
│   ├── lib/
│   │   ├── core/
│   │   │   ├── api_client.dart     ← Dio + auth interceptor
│   │   │   ├── api_constants.dart  ← Base URL (debug/release)
│   │   │   └── router.dart         ← GoRouter (StatefulShellRoute)
│   │   ├── models/                 ← JSON serileştirme (json_annotation)
│   │   ├── providers/              ← Riverpod notifier'lar
│   │   ├── screens/                ← Tüm ekranlar
│   │   ├── services/               ← API servis katmanı
│   │   └── widgets/                ← Ortak bileşenler
│   ├── android/
│   ├── pubspec.yaml
│   └── build/app/outputs/
│       └── flutter-apk/
│           └── app-release.apk     ← Son build (58 MB)
│
├── src/                            ← Backend kaynak kodu
│   ├── config/
│   │   ├── db.js                   ← SQLite bağlantısı (WAL mode)
│   │   ├── migrate.js              ← Schema + public fridge seed
│   │   └── schema.sql              ← Veritabanı şeması
│   ├── controllers/                ← İş mantığı katmanı
│   ├── middlewares/                ← Auth, role, validation
│   ├── repositories/               ← Saf DB sorgular
│   ├── routes/                     ← Express Router tanımları
│   ├── services/                   ← Repository orchestration
│   └── utils/
│       ├── ApiError.js
│       └── logger.js
├── data/                           ← SQLite DB dosyası (Railway volume)
├── .env.example
├── package.json
└── README.md
```

---

## 🚀 Kurulum

### Backend Kurulumu

#### Ön Gereksinimler
- Node.js 18+
- Firebase projesi (Admin SDK credentials)
- Cloudinary hesabı
- (Opsiyonel) Railway CLI

#### 1. Klonla

```bash
git clone https://github.com/rukiyekoruyucu/FoodBridge.git
cd FoodBridge
```

#### 2. Bağımlılıkları Yükle

```bash
npm install
```

#### 3. `.env` Dosyasını Oluştur

```bash
cp .env.example .env
```

`.env` içeriği:

```env
PORT=3000
NODE_ENV=development

# SQLite
DATABASE_PATH=./data/foodbridge.db

# Firebase Admin — service account JSON yolunu belirt
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# Cloudinary
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# CORS
CORS_ORIGIN=*
```

#### 4. Çalıştır

```bash
# Development
npm run dev

# Production
npm start
```

API `http://localhost:3000` adresinde çalışır.

#### Sağlık Kontrolü

```bash
curl http://localhost:3000/health
# → { "status": "ok" }

curl http://localhost:3000/health/db
# → { "status": "ok", "dbTime": "..." }
```

---

### Flutter App Kurulumu

#### Ön Gereksinimler
- Flutter SDK 3.x
- Android Studio / Xcode
- Firebase projesi (`google-services.json`)

#### 1. App Klasörüne Gir

```bash
cd app
```

#### 2. Bağımlılıkları Yükle

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 3. API URL'ini Ayarla

`lib/core/api_constants.dart` dosyasında:

```dart
// Debug — yerel backend
static const String debugBaseUrl = 'http://192.168.x.x:3000/api';

// Release — Railway deploy
static const String releaseBaseUrl = 'https://foodbridge-production-7403.up.railway.app/api';
```

#### 4. Firebase Ayarları

- `google-services.json` dosyasını `android/app/` klasörüne ekle
- `lib/firebase_options.dart` dosyasını `flutterfire configure` ile oluştur

#### 5. Çalıştır

```bash
# Debug modu
flutter run

# Release APK oluştur
flutter build apk --release
```

---

## 📱 APK Kurulumu

1. [Releases](https://github.com/rukiyekoruyucu/FoodBridge/releases) sayfasından son `app-release.apk`'yı indir  
   **VEYA** `app/build/app/outputs/flutter-apk/app-release.apk` dosyasını kullan
2. Android cihazda **Bilinmeyen Kaynaklar**'a izin ver
3. APK'yı kur ve aç

> **Not:** iOS için kaynak koddan build almanız gerekir (Xcode + Apple Developer hesabı)

---

## 🔑 Ortam Değişkenleri

| Değişken | Açıklama | Zorunlu |
|----------|---------|---------|
| `PORT` | Sunucu port | ❌ (default: 3000) |
| `NODE_ENV` | `development` / `production` | ✅ |
| `DATABASE_PATH` | SQLite dosya yolu | ✅ |
| `FIREBASE_PROJECT_ID` | Firebase proje ID | ✅ |
| `FIREBASE_CLIENT_EMAIL` | Service account e-posta | ✅ |
| `FIREBASE_PRIVATE_KEY` | Service account özel anahtar | ✅ |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary bulut adı | ✅ |
| `CLOUDINARY_API_KEY` | Cloudinary API anahtarı | ✅ |
| `CLOUDINARY_API_SECRET` | Cloudinary gizli anahtar | ✅ |
| `CORS_ORIGIN` | İzin verilen origin (üretimde kısıtla) | ❌ (default: *) |
| `PUBLIC_FRIDGE_ID` | Sistem genel buzdolabı ID | ❌ (auto-set) |

---

## 📡 API Referansı

Tüm istekler `/api` prefix'iyle başlar.  
Auth gerektiren endpoint'ler için `Authorization: Bearer <firebase-id-token>` header'ı gereklidir.

### 🔑 Auth — `/api/auth`

| Metod | Endpoint | Auth | Açıklama |
|-------|----------|------|---------|
| `POST` | `/auth/register` | ❌ | Yeni kullanıcı kaydı |
| `GET` | `/auth/me` | ✅ | Giriş yapan kullanıcı bilgisi |

**Register Request:**
```json
{
  "firebaseUid": "string",
  "fullName": "string (min 2)",
  "email": "email",
  "username": "string (alphanum, 3-20)",
  "role": "PERSONAL | CORPORATE | NEEDY"
}
```

---

### 👤 Kullanıcılar — `/api/users`

| Metod | Endpoint | Auth | Açıklama |
|-------|----------|------|---------|
| `GET` | `/users/me/summary` | ✅ | Profil özeti + istatistikler |
| `PATCH` | `/users/me` | ✅ | Profil güncelle |
| `GET` | `/users/leaderboard` | ❌ | En iyi bağışçılar |
| `GET` | `/users/:id/public` | ❌ | Kullanıcı public profili |

---

### 📦 Ürünler — `/api/items`

| Metod | Endpoint | Auth | Roller | Açıklama |
|-------|----------|------|--------|---------|
| `GET` | `/items/feed` | ✅ | Hepsi | Akış (latest/nearby) |
| `GET` | `/items/map` | ✅ | Hepsi | Harita marker'ları |
| `POST` | `/items` | ✅ | PERSONAL, CORPORATE | Bağış oluştur |
| `GET` | `/items/my-public` | ✅ | PERSONAL, CORPORATE | Bendi bağışlarım |
| `PUT` | `/items/:id` | ✅ | PERSONAL, CORPORATE | Bağışı güncelle |
| `DELETE` | `/items/:id` | ✅ | PERSONAL, CORPORATE | Bağışı kaldır |
| `GET` | `/items/:id` | ✅ | Hepsi | Bağış detayı |

**Feed Query Params:**
```
?mode=latest|nearby
&lat=41.0&lng=28.9    (nearby için zorunlu)
&radiusKm=10
&category=Meyve
&q=elma
&limit=20
```

---

### 🎁 Bağışlar — `/api/donations`

| Metod | Endpoint | Auth | Roller | Açıklama |
|-------|----------|------|--------|---------|
| `POST` | `/donations/request` | ✅ | Hepsi | Bağış talebi oluştur |
| `GET` | `/donations/items/:itemId/requests` | ✅ | PERSONAL, CORPORATE | Item'a gelen talepler |
| `POST` | `/donations/:id/accept` | ✅ | PERSONAL, CORPORATE | Talebi kabul et |
| `POST` | `/donations/:id/reject` | ✅ | PERSONAL, CORPORATE | Talebi reddet |
| `POST` | `/donations/:id/confirm-pickup` | ✅ | Hepsi | Teslim alındı onayla |
| `GET` | `/donations/me` | ✅ | Hepsi | Geçmiş bağışlar |

---

### 🧊 Özel Buzdolabı — `/api/private-fridges`

| Metod | Endpoint | Auth | Açıklama |
|-------|----------|------|---------|
| `GET` | `/private-fridges` | ✅ | Buzdolaplarımı listele |
| `POST` | `/private-fridges` | ✅ | Buzdolabı oluştur |
| `PUT` | `/private-fridges/:id` | ✅ | Buzdolabı güncelle |
| `DELETE` | `/private-fridges/:id` | ✅ | Buzdolabı sil |
| `GET` | `/private-fridges/:id/items` | ✅ | Ürünleri listele |
| `POST` | `/private-fridges/:id/items` | ✅ | Ürün ekle |
| `PUT` | `/private-fridges/:id/items/:itemId` | ✅ | Ürün güncelle |
| `DELETE` | `/private-fridges/:id/items/:itemId` | ✅ | Ürün sil |
| `GET` | `/private-fridges/:id/items-expiring` | ✅ | Son kullanım yaklaşan |
| `PUT` | `/private-fridges/items/:itemId/transfer` | ✅ | Genel sisteme aktar |

---

### 💬 Chat — `/api/chat`

| Metod | Endpoint | Auth | Açıklama |
|-------|----------|------|---------|
| `GET` | `/chat/rooms` | ✅ | Sohbet odalarım |
| `POST` | `/chat/dm/:userId` | ✅ | DM oluştur / aç |
| `GET` | `/chat/rooms/:roomId/messages` | ✅ | Mesaj geçmişi |
| `POST` | `/chat/rooms/:roomId/messages` | ✅ | Mesaj gönder |

---

### 📤 Yükleme — `/api/uploads`

| Metod | Endpoint | Auth | Açıklama |
|-------|----------|------|---------|
| `POST` | `/uploads/image` | ✅ | Fotoğraf yükle (Cloudinary) |

**Query:** `?folder=avatars|items-public|items-private|misc`  
**Body:** `multipart/form-data` — field: `image` (max 10MB)  
**Response:** `{ "imageUrl": "https://...", "publicId": "..." }`

---

## 👥 Kullanıcı Rolleri

| Rol | Açıklama | Yapabilecekleri |
|-----|---------|----------------|
| `PERSONAL` | Bireysel bağışçı | Bağış oluştur, özel buzdolabı yönet, bağış kabul/reddet |
| `CORPORATE` | Kurumsal bağışçı | PERSONAL ile aynı + kurumsal profil |
| `NEEDY` | İhtiyaç sahibi | Bağış talebi oluştur, DM aç, bağış akışını görüntüle |

---

## 🗄 Veritabanı Şeması

```sql
users           — Firebase ile entegre kullanıcılar
fridges         — Genel (is_public=1) ve özel (is_public=0) buzdolapları
items           — Bağış ürünleri (status: AVAILABLE/RESERVED/REMOVED/EXPIRED)
donations       — Bağış talepleri ve akış durumu
chat_rooms      — DM ve bağış bazlı sohbet odaları
chat_messages   — Mesajlar
follows         — Kullanıcı takip sistemi (PENDING/ACCEPTED)
```

**Donation Yaşam Döngüsü:**
```
NEEDY → request →  PENDING
DONOR → accept  →  ACCEPTED  (diğer talepler otomatik CANCELLED)
DONOR → confirm →  donor_confirmed_at set
NEEDY → confirm →  COMPLETED + 10 kindness_points + item REMOVED
```

---

## 🚢 Railway Deploy

Backend Railway'de çalışmaktadır. Volume mount ile SQLite dosyası kalıcıdır.

**Ortam değişkenleri Railway Dashboard'dan set edilir.**

Yeni deploy için sadece `git push origin main` yeterlidir — Railway otomatik build + restart yapar.

---

## 🤝 Katkıda Bulunma

1. Fork'la
2. Feature branch oluştur: `git checkout -b feature/yeni-ozellik`
3. Değişikliklerini commit'le: `git commit -m 'feat: Yeni özellik açıklaması'`
4. Push'la: `git push origin feature/yeni-ozellik`
5. Pull Request aç

### Commit Mesaj Formatı
```
feat:  Yeni özellik
fix:   Hata düzeltme
docs:  Dokümantasyon
style: Kod formatı
refactor: Yeniden yapılandırma
test:  Test ekleme
```

---

## 📄 Lisans

MIT License — Detaylar için [LICENSE](LICENSE) dosyasına bakın.

---

<div align="center">

**FoodBridge** — Gıda israfına köprü ol 🌉

Made with ❤️ in Turkey

</div>
