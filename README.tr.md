<div align="center">

<img src="app/assets/foodbridge_logo.png" alt="FoodBridge Logo" width="140" />

# FoodBridge

### Gıda israfıyla savaşan, bağışçıları ihtiyaç sahipleriyle buluşturan açık kaynak platform

[![CI](https://github.com/rukiyekoruyucu/FoodBridge/actions/workflows/ci.yml/badge.svg)](https://github.com/rukiyekoruyucu/FoodBridge/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-20.x-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![SQLite](https://img.shields.io/badge/SQLite-WAL_Mode-003B57?logo=sqlite&logoColor=white)](https://sqlite.org)
[![Firebase](https://img.shields.io/badge/Firebase-Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Railway](https://img.shields.io/badge/Railway-Canlı-0B0D0E?logo=railway&logoColor=white)](https://railway.app)
[![License](https://img.shields.io/badge/Lisans-MIT-green.svg)](LICENSE)

**[🌐 Canlı API](https://foodbridge-production-7403.up.railway.app/health)** &nbsp;•&nbsp;
**[📱 APK İndir](https://github.com/rukiyekoruyucu/FoodBridge/releases)** &nbsp;•&nbsp;
**[📡 API Dokümantasyonu](#-api-referansı)** &nbsp;•&nbsp;
**[🇬🇧 English](README.md)**

</div>

---

## 📋 İçindekiler

- [Proje Hakkında](#-proje-hakkında)
- [Özellikler](#-özellikler)
- [Mimari](#-mimari)
- [Teknoloji Yığını](#-teknoloji-yığını)
- [Proje Yapısı](#-proje-yapısı)
- [Kurulum](#-kurulum)
- [APK Kurulumu](#-apk-kurulumu)
- [Ortam Değişkenleri](#-ortam-değişkenleri)
- [API Referansı](#-api-referansı)
- [Kullanıcı Rolleri](#-kullanıcı-rolleri)
- [Veritabanı Şeması](#-veritabanı-şeması)
- [Testler](#-testler)
- [CI/CD](#-cicd)
- [Performans ve Ölçeklenebilirlik](#-performans-ve-ölçeklenebilirlik)
- [Katkıda Bulunma](#-katkıda-bulunma)

---

## 🌍 Proje Hakkında

**FoodBridge**, gıda israfını önlemek amacıyla bağışçıları (bireysel/kurumsal) ihtiyaç sahipleriyle buluşturan bir Flutter mobil uygulaması + Node.js/Express REST API monoreposudur. Railway üzerinde canlıdır.

**Temel kullanım akışları:**
- 🥗 Fazla gıdaları **ücretsiz** paylaş
- 🗺️ Yakınındaki bağışları **gerçek zamanlı haritada** bul
- 💬 Bağışçıyla **Socket.IO** üzerinden anlık mesajlaş
- 🏆 **Kindness Points** kazanarak lider tablosuna çık
- 🧊 **Özel buzdolabı** ile kişisel stoku takip et

---

## ✨ Özellikler

| Özellik | Açıklama |
|---------|----------|
| **Harita** | OpenStreetMap tabanlı gerçek zamanlı bağış haritası (API key gerekmez) |
| **Feed** | Sayfalandırılmış bağış listesi — en yeni / en yakın modu |
| **Infinite Scroll** | Offset tabanlı sayfalama (20 ürün/sayfa) |
| **Özel Buzdolabı** | Kişisel stok takibi + son kullanma tarihi uyarıları |
| **Gerçek Zamanlı Chat** | Socket.IO ile anlık mesajlaşma |
| **Kindness Board** | Kindness Points'e göre sıralanan bağışçı listesi |
| **Firebase Auth** | In-memory token cache ile güvenli kimlik doğrulama |
| **Dark / Light Mode** | Tam tema desteği |
| **Fotoğraf Yükleme** | Cloudinary CDN entegrasyonu |
| **Rol Bazlı Yetkilendirme** | 3 kullanıcı rolü, endpoint seviyesinde izin kontrolü |
| **Ölçeklenebilir** | WAL mode, 16 DB index, rate limiting — 1000+ kullanıcı hazır |

---

## 🏗 Mimari

```
+-----------------------------------------------------+
|              Flutter Mobil Uygulama                  |
|   GoRouter · Riverpod · Dio · flutter_map · Socket  |
+------------------------+----------------------------+
                         | HTTPS + WebSocket
+------------------------v----------------------------+
|           Node.js / Express REST API                 |
|   Firebase Auth Middleware · Joi Validasyon          |
|   Rate Limiting · Helmet · Morgan                    |
|                                                      |
|   Routes -> Controllers -> Services -> Repos         |
|                         |                            |
|     SQLite (better-sqlite3, WAL mode)                |
|   16 index · 64 MB cache · busy_timeout              |
+-----------------------------------------------------+
        Railway deploy · Cloudinary CDN
```

---

## 🛠 Teknoloji Yığını

### Backend (`/src`)

| Katman | Teknoloji |
|--------|-----------|
| Runtime | Node.js 20 + Express 4 |
| Veritabanı | SQLite 3 — `better-sqlite3` (WAL mode, 64 MB cache) |
| Auth | Firebase Admin SDK + 5 dk in-memory token cache |
| Medya | Cloudinary |
| Gerçek Zamanlı | Socket.IO 4 |
| Deploy | Railway |
| Loglama | Winston |
| Validasyon | Joi |
| Rate Limit | express-rate-limit (endpoint bazlı) |
| Test | Jest 29 + Supertest |

### Mobil Uygulama (`/app`)

| Katman | Teknoloji |
|--------|-----------|
| Framework | Flutter 3.x (Dart) |
| State Yönetimi | Riverpod |
| Navigasyon | GoRouter (StatefulShellRoute) |
| HTTP | Dio + Auth Interceptor |
| Harita | Flutter Map + OpenStreetMap |
| Auth | Firebase Auth |
| Font | Google Fonts (Inter) |

---

## 📁 Proje Yapısı

```
FoodBridge/
|
+-- .github/
|   +-- workflows/
|       +-- ci.yml              <- GitHub Actions CI (Node 18 + 20)
|
+-- app/                        <- Flutter mobil uygulama
|   +-- lib/
|   |   +-- core/               <- Router, API client, sabitler
|   |   +-- models/             <- JSON serileştirme
|   |   +-- providers/          <- Riverpod notifier'lar
|   |   +-- screens/            <- 14 ekran
|   |   +-- services/           <- API servis katmanı
|   |   +-- widgets/            <- Ortak UI bileşenleri
|   +-- android/
|   +-- pubspec.yaml
|
+-- src/                        <- Backend kaynak kodu (Node.js)
|   +-- config/
|   |   +-- db.js               <- SQLite kurulumu (WAL, pragma'lar)
|   |   +-- migrate.js          <- Schema başlatma + seed
|   |   +-- schema.sql          <- Tablolar + 16 performans index'i
|   +-- controllers/            <- HTTP istek işleyicileri
|   +-- middlewares/            <- Auth, rol, validasyon
|   +-- repositories/           <- Saf DB sorguları (senkron API)
|   +-- routes/                 <- Express Router tanımları
|   +-- services/               <- İş mantığı katmanı
|   +-- sockets/                <- Socket.IO handler
|   +-- jobs/                   <- Cron: süresi dolan ürünleri işaretle
|   +-- utils/                  <- ApiError, Haversine geo, logger
|
+-- tests/
|   +-- unit/
|   |   +-- utils/              <- geo.test.js, ApiError.test.js
|   |   +-- services/           <- itemService.test.js, donationService.test.js
|   +-- integration/
|       +-- health.test.js      <- HTTP endpoint testleri (supertest)
|
+-- data/                       <- SQLite DB dosyası (Railway volume)
+-- .env.example
+-- jest.config.js
+-- package.json
+-- railway.json
+-- README.md
```

---

## 🚀 Kurulum

### Ön Gereksinimler

- Node.js 18+
- Flutter SDK 3.x (mobil uygulama için)
- Firebase projesi (Admin SDK kimlik bilgileri)
- Cloudinary hesabı

### Backend Kurulumu

```bash
# Klonla
git clone https://github.com/rukiyekoruyucu/FoodBridge.git
cd FoodBridge

# Bağımlılıkları yükle
npm install

# Ortam değişkenlerini ayarla
cp .env.example .env
# .env dosyasına Firebase ve Cloudinary bilgilerini gir

# Çalıştır
npm run dev     # Geliştirme (nodemon ile otomatik yeniden başlatma)
npm start       # Üretim
```

Sağlık kontrolü:
```bash
curl https://foodbridge-production-7403.up.railway.app/health
# -> { "status": "ok" }
```

### Flutter Uygulama Kurulumu

```bash
cd app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# google-services.json dosyasını android/app/ klasörüne koy
# lib/core/api_constants.dart'da backend URL'ini güncelle

flutter run                    # Debug modu
flutter build apk --release    # Release APK oluştur
```

---

## 📱 APK Kurulumu

1. **[Releases](https://github.com/rukiyekoruyucu/FoodBridge/releases)** sayfasından son `app-release.apk`'yı indir
2. Android cihazda **Ayarlar → Güvenlik → Bilinmeyen Kaynaklara İzin Ver**
3. APK dosyasına dokun → **Yükle**

> **iOS:** Xcode + Apple Developer hesabı ile kaynak koddan build almanız gerekir.

---

## 🔑 Ortam Değişkenleri

| Değişken | Açıklama | Zorunlu |
|----------|----------|---------|
| `PORT` | Sunucu portu | ❌ (varsayılan: 3000) |
| `NODE_ENV` | `development` / `production` / `test` | ✅ |
| `DATABASE_PATH` | SQLite dosya yolu | ✅ |
| `FIREBASE_PROJECT_ID` | Firebase proje ID | ✅ |
| `FIREBASE_CLIENT_EMAIL` | Service account e-posta | ✅ |
| `FIREBASE_PRIVATE_KEY` | Service account özel anahtarı | ✅ |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary bulut adı | ✅ |
| `CLOUDINARY_API_KEY` | Cloudinary API anahtarı | ✅ |
| `CLOUDINARY_API_SECRET` | Cloudinary gizli anahtarı | ✅ |
| `CORS_ORIGIN` | İzin verilen CORS origin | ❌ (varsayılan: `*`) |
| `PUBLIC_FRIDGE_ID` | Sistem genel buzdolabı ID | ❌ (başlangıçta otomatik set) |

---

## 📡 API Referansı

Tüm endpoint'ler `/api` prefix'iyle başlar.  
Korunan endpoint'ler için: `Authorization: Bearer <firebase-id-token>`

### Auth

| Metod | Endpoint | Auth | Açıklama |
|-------|----------|------|----------|
| `POST` | `/auth/register` | ❌ | Yeni kullanıcı kaydı |
| `GET` | `/auth/me` | ✅ | Giriş yapan kullanıcı bilgisi |

### Kullanıcılar

| Metod | Endpoint | Auth | Açıklama |
|-------|----------|------|----------|
| `GET` | `/users/me/summary` | ✅ | Profil + istatistikler |
| `PATCH` | `/users/me` | ✅ | Profil güncelle |
| `GET` | `/users/leaderboard` | ❌ | En iyi bağışçılar |
| `GET` | `/users/:id/public` | ❌ | Public profil |

### Ürünler (Bağışlar)

| Metod | Endpoint | Auth | Rol | Açıklama |
|-------|----------|------|-----|----------|
| `GET` | `/items/feed` | ✅ | Hepsi | Sayfalandırılmış feed |
| `GET` | `/items/map` | ✅ | Hepsi | Harita marker'ları |
| `POST` | `/items` | ✅ | PERSONAL, CORPORATE | Bağış oluştur |
| `GET` | `/items/my-public` | ✅ | PERSONAL, CORPORATE | Benim bağışlarım |
| `PUT` | `/items/:id` | ✅ | PERSONAL, CORPORATE | Bağış güncelle |
| `DELETE` | `/items/:id` | ✅ | PERSONAL, CORPORATE | Bağış kaldır |

Feed parametreleri: `?mode=latest|nearby&lat=&lng=&radiusKm=10&category=&q=&limit=20&offset=0`

### Bağış Talepleri

Yaşam döngüsü: `PENDING → ACCEPTED → COMPLETED` (otomatik Kindness Points ödülü ile)

### Chat (Socket.IO)

Olaylar: `join_room` / `send_message` / `new_message`

---

## 👥 Kullanıcı Rolleri

| Rol | Açıklama | Yetkiler |
|-----|----------|----------|
| `PERSONAL` | Bireysel bağışçı | Bağış oluştur, özel buzdolabı yönet, talepleri kabul/reddet |
| `CORPORATE` | Kurumsal bağışçı | PERSONAL ile aynı + kurumsal profil |
| `NEEDY` | İhtiyaç sahibi | Bağış talebi oluştur, DM başlat, feed ve haritayı görüntüle |

---

## 🗄 Veritabanı Şeması

```
users           — Firebase entegrasyonlu kullanıcılar
fridges         — Genel (is_public=1) ve özel (is_public=0) buzdolapları
items           — Bağış ürünleri (AVAILABLE / RESERVED / REMOVED / EXPIRED)
donations       — Bağış talep yaşam döngüsü
chat_rooms      — DM ve bağış bazlı sohbet odaları
chat_messages   — Mesajlar
follows         — Kullanıcı takip grafiği (PENDING / ACCEPTED)
```

Feed, harita, chat, leaderboard ve bağış durumu sorguları için **16 performans index'i** mevcuttur.

---

## 🧪 Testler

```bash
npm test                  # Tüm testler
npm run test:unit         # Sadece unit testler (DB veya Firebase gerekmez)
npm run test:integration  # Entegrasyon testleri (in-memory SQLite)
npm run test:coverage     # Coverage raporu ile
```

Test kapsamı:

```
tests/
+-- unit/
|   +-- utils/
|   |   +-- ApiError.test.js        (6 test)  Özel exception sınıfı
|   |   +-- geo.test.js             (6 test)  Haversine formülü doğruluğu
|   +-- services/
|       +-- itemService.test.js     (10 test) İş mantığı + sahiplik kontrolleri
|       +-- donationService.test.js  (8 test) Bağış kuralları + hata senaryoları
+-- integration/
    +-- health.test.js              (4 test)  HTTP endpoint smoke testleri
```

Tüm unit testler **mock repository** kullanır — CI'da gerçek DB veya Firebase bağlantısı gerekmez.

---

## ⚙️ CI/CD

GitHub Actions, `main`'e her push ve tüm pull request'lerde çalışır:

| Job | Açıklama |
|-----|----------|
| `test (18.x)` | Node.js 18 üzerinde tam test suite |
| `test (20.x)` | Node.js 20 üzerinde tam test suite + coverage artifact yükleme |
| `lint-check` | Tüm 50 kaynak dosyada sözdizimi doğrulama |

**Railway**, `main`'e her push'ta otomatik deploy alır.

---

## ⚡ Performans ve Ölçeklenebilirlik

**1000+ eş zamanlı kullanıcı** için optimize edilmiştir:

| Optimizasyon | Detay |
|-------------|-------|
| SQLite WAL mode | Eş zamanlı okuma/yazma çakışması önlendi |
| 64 MB page cache | Disk I/O dramatik şekilde azaltıldı |
| Firebase token cache | 5 dk TTL — her istekte Firebase round-trip yok |
| 16 DB index | Hot sorgularda full table scan yok |
| Bounding box ön filtresi | Haversine hesaplamasından önce coğrafi kısıtlama |
| Offset sayfalama | Feed 20 ürün/sayfa yüklüyor |
| Socket room cache | In-memory Set — mesaj başına DB sorgusu yok |
| Endpoint bazlı rate limit | Auth, upload, chat ayrı ayrı korumalı |
| `busy_timeout = 5000 ms` | Yük altında yazma çakışması crashlerini önler |

---

## 🤝 Katkıda Bulunma

1. Repo'yu fork'la
2. Feature branch oluştur: `git checkout -b feature/yeni-ozellik`
3. Commit: `git commit -m 'feat: özellik açıklaması'`
4. Push: `git push origin feature/yeni-ozellik`
5. Pull Request aç

Commit formatı (Conventional Commits):
```
feat:     Yeni özellik
fix:      Hata düzeltme
perf:     Performans iyileştirmesi
test:     Test ekle/güncelle
docs:     Sadece dokümantasyon
refactor: Davranış değişmeden yeniden yapılandırma
chore:    Build / config değişikliği
```

---

## 📄 Lisans

[MIT Lisansı](LICENSE) © 2025 rukiyekoruyucu

---

<div align="center">

**FoodBridge** — Gıda israfına köprü ol 🌉

*Türkiye'den ❤️ ile yapıldı*

</div>
