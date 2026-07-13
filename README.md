<div align="center">

<img src="app/assets/foodbridge_logo.png" alt="FoodBridge Logo" width="140" />

# FoodBridge

### An open-source platform connecting food donors with people in need — fighting waste, one meal at a time.

[![CI](https://github.com/rukiyekoruyucu/FoodBridge/actions/workflows/ci.yml/badge.svg)](https://github.com/rukiyekoruyucu/FoodBridge/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-20.x-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![SQLite](https://img.shields.io/badge/SQLite-WAL_Mode-003B57?logo=sqlite&logoColor=white)](https://sqlite.org)
[![Firebase](https://img.shields.io/badge/Firebase-Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Railway](https://img.shields.io/badge/Railway-Live-0B0D0E?logo=railway&logoColor=white)](https://railway.app)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**[Live API](https://foodbridge-production-7403.up.railway.app/health)** &nbsp;•&nbsp;
**[Download APK](https://github.com/rukiyekoruyucu/FoodBridge/releases)** &nbsp;•&nbsp;
**[API Docs](#-api-reference)** &nbsp;•&nbsp;
**[Türkçe](README.tr.md)**

</div>

---

## About the Project

**FoodBridge** is a full-stack mobile + backend platform that tackles food waste by connecting donors (individuals and businesses) with people in need. Built as a monorepo combining a Flutter mobile app with a Node.js/Express REST API, deployed on Railway.

**Core user flows:**
- Share surplus food for **free**
- Discover nearby donations on a **real-time map**
- **Chat directly** with donors via Socket.IO
- Earn **Kindness Points** and climb the community leaderboard
- Track personal food stock with a **private fridge** manager

---

## Features

| Feature | Description |
|---------|-------------|
| **Map View** | Real-time donation map using OpenStreetMap (no API key) |
| **Feed** | Paginated list — latest or nearby mode with infinite scroll |
| **Private Fridge** | Personal inventory tracker with expiry date alerts |
| **Real-time Chat** | Socket.IO messaging between donors and recipients |
| **Leaderboard** | Top donors ranked by Kindness Points |
| **Firebase Auth** | Secure email/password auth with in-memory token cache |
| **Dark / Light Mode** | Full theme support |
| **Image Upload** | Cloudinary CDN integration |
| **Role-based Access** | 3 user roles with fine-grained endpoint permissions |
| **Scalable** | WAL mode, 16 DB indexes, rate limiting — ready for 1000+ users |

---

## Architecture

```
+-----------------------------------------------------+
|                  Flutter (Android)                   |
|  GoRouter · Riverpod · Dio · flutter_map · Socket   |
+------------------------+----------------------------+
                         | HTTPS + WebSocket
+------------------------v----------------------------+
|             Node.js / Express REST API               |
|  Firebase Auth Middleware · Joi Validation           |
|  Rate Limiting · Helmet · Morgan                     |
|                                                      |
|   Routes -> Controllers -> Services -> Repos         |
|                         |                            |
|      SQLite (better-sqlite3, WAL mode)               |
|   16 indexes · 64 MB cache · busy_timeout            |
+-----------------------------------------------------+
         Deployed on Railway · Cloudinary CDN
```

---

## Tech Stack

### Backend (`/src`)

| Layer | Technology |
|-------|------------|
| Runtime | Node.js 20 + Express 4 |
| Database | SQLite 3 via `better-sqlite3` (WAL mode, 64 MB cache) |
| Auth | Firebase Admin SDK + 5-min in-memory token cache |
| Media | Cloudinary |
| Realtime | Socket.IO 4 |
| Deployment | Railway |
| Logging | Winston |
| Validation | Joi |
| Rate Limiting | express-rate-limit (per-endpoint) |
| Testing | Jest 29 + Supertest |

### Mobile App (`/app`)

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.x (Dart) |
| State Management | Riverpod |
| Navigation | GoRouter (StatefulShellRoute) |
| HTTP | Dio + Auth Interceptor |
| Maps | Flutter Map + OpenStreetMap |
| Auth | Firebase Auth |
| Fonts | Google Fonts (Inter) |

---

## Project Structure

```
FoodBridge/
|
+-- .github/
|   +-- workflows/
|       +-- ci.yml              <- GitHub Actions CI (Node 18 + 20)
|
+-- app/                        <- Flutter mobile app
|   +-- lib/
|   |   +-- core/               <- Router, API client, constants
|   |   +-- models/             <- JSON serialization
|   |   +-- providers/          <- Riverpod state notifiers
|   |   +-- screens/            <- 14 screens
|   |   +-- services/           <- API service layer
|   |   +-- widgets/            <- Shared UI components
|   +-- android/
|   +-- pubspec.yaml
|
+-- src/                        <- Backend source (Node.js)
|   +-- config/
|   |   +-- db.js               <- SQLite setup (WAL, pragmas, cache)
|   |   +-- migrate.js          <- Schema initialization + seed
|   |   +-- schema.sql          <- Tables + 16 performance indexes
|   +-- controllers/            <- HTTP request handlers
|   +-- middlewares/            <- Auth, role, validation
|   +-- repositories/           <- Pure DB queries (sync API)
|   +-- routes/                 <- Express Routers
|   +-- services/               <- Business logic layer
|   +-- sockets/                <- Socket.IO handler
|   +-- jobs/                   <- Cron: expire stale items
|   +-- utils/                  <- ApiError, Haversine geo, logger
|
+-- tests/
|   +-- unit/
|   |   +-- utils/              <- geo.test.js, ApiError.test.js
|   |   +-- services/           <- itemService.test.js, donationService.test.js
|   +-- integration/
|       +-- health.test.js      <- HTTP endpoint tests (supertest)
|
+-- data/                       <- SQLite DB (Railway volume mount)
+-- .env.example
+-- jest.config.js
+-- package.json
+-- railway.json
+-- README.md
```

---

## Getting Started

### Prerequisites

- Node.js 18+
- Flutter SDK 3.x (for mobile app)
- Firebase project (Admin SDK credentials)
- Cloudinary account

### Backend Setup

```bash
# Clone
git clone https://github.com/rukiyekoruyucu/FoodBridge.git
cd FoodBridge

# Install dependencies
npm install

# Configure
cp .env.example .env
# Fill in Firebase and Cloudinary credentials in .env

# Run
npm run dev     # Development (nodemon)
npm start       # Production
```

Health check:
```bash
curl https://foodbridge-production-7403.up.railway.app/health
# -> { "status": "ok" }
```

### Flutter App Setup

```bash
cd app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Place your google-services.json in android/app/
# Update lib/core/api_constants.dart with your backend URL

flutter run                    # Debug mode
flutter build apk --release    # Build release APK
```

---

## Download APK

1. Go to **[Releases](https://github.com/rukiyekoruyucu/FoodBridge/releases)** and download the latest `app-release.apk`
2. On Android: **Settings → Security → Allow unknown sources**
3. Tap the APK → **Install**

> **iOS:** Build from source with Xcode + Apple Developer account.

---

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `PORT` | Server port | No (default: 3000) |
| `NODE_ENV` | `development` / `production` / `test` | Yes |
| `DATABASE_PATH` | SQLite file path | Yes |
| `FIREBASE_PROJECT_ID` | Firebase project ID | Yes |
| `FIREBASE_CLIENT_EMAIL` | Service account email | Yes |
| `FIREBASE_PRIVATE_KEY` | Service account private key | Yes |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name | Yes |
| `CLOUDINARY_API_KEY` | Cloudinary API key | Yes |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret | Yes |
| `CORS_ORIGIN` | Allowed CORS origin | No (default: `*`) |
| `PUBLIC_FRIDGE_ID` | System public fridge ID | No (auto-set) |

---

## API Reference

All endpoints prefixed with `/api`.
Protected endpoints require: `Authorization: Bearer <firebase-id-token>`

### Auth

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/auth/register` | No | Register new user |
| `GET` | `/auth/me` | Yes | Get current user |

### Users

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/users/me/summary` | Yes | Profile + stats |
| `PATCH` | `/users/me` | Yes | Update profile |
| `GET` | `/users/leaderboard` | No | Top donors |
| `GET` | `/users/:id/public` | No | Public profile |

### Items

| Method | Endpoint | Auth | Roles | Description |
|--------|----------|------|-------|-------------|
| `GET` | `/items/feed` | Yes | All | Paginated feed (latest / nearby) |
| `GET` | `/items/map` | Yes | All | Map markers |
| `POST` | `/items` | Yes | PERSONAL, CORPORATE | Create donation |
| `GET` | `/items/my-public` | Yes | PERSONAL, CORPORATE | My donations |
| `PUT` | `/items/:id` | Yes | PERSONAL, CORPORATE | Update donation |
| `DELETE` | `/items/:id` | Yes | PERSONAL, CORPORATE | Remove donation |

Feed params: `?mode=latest|nearby&lat=&lng=&radiusKm=10&category=&q=&limit=20&offset=0`

### Donations

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/donations/request` | Yes | Create request |
| `GET` | `/donations/items/:itemId/requests` | Yes | List requests |
| `POST` | `/donations/:id/accept` | Yes | Accept request |
| `POST` | `/donations/:id/reject` | Yes | Reject request |
| `POST` | `/donations/:id/confirm-pickup` | Yes | Confirm pickup |
| `GET` | `/donations/me` | Yes | My history |

Lifecycle: `PENDING -> ACCEPTED -> COMPLETED` (with automatic kindness points award)

### Chat

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/chat/rooms` | Yes | My rooms |
| `POST` | `/chat/dm/:userId` | Yes | Open DM |
| `GET` | `/chat/rooms/:roomId/messages` | Yes | Message history |

Socket.IO: `join_room` / `send_message` / `new_message` events

### Uploads

`POST /uploads/image` — `multipart/form-data`, field: `image` (max 10 MB)
Query: `?folder=avatars|items-public|items-private`
Response: `{ "imageUrl": "...", "publicId": "..." }`

---

## User Roles

| Role | Description | Can Do |
|------|-------------|--------|
| `PERSONAL` | Individual donor | Create donations, manage private fridge, accept/reject requests |
| `CORPORATE` | Business donor | Same as PERSONAL + corporate profile |
| `NEEDY` | Person in need | Request donations, open DMs, browse feed and map |

---

## Database Schema

```
users           — Firebase-integrated user accounts
fridges         — Public (is_public=1) and private (is_public=0) fridges
items           — Donations (AVAILABLE / RESERVED / REMOVED / EXPIRED)
donations       — Request lifecycle (PENDING / ACCEPTED / COMPLETED / CANCELLED)
chat_rooms      — DM and donation-based rooms
chat_messages   — Chat messages
follows         — User follow graph (PENDING / ACCEPTED)
```

16 performance indexes for feed, map, chat, leaderboard, and donation status queries.

---

## Testing

```bash
npm test                  # All tests
npm run test:unit         # Unit tests only (no DB or Firebase needed)
npm run test:integration  # Integration tests (in-memory SQLite)
npm run test:coverage     # With coverage report
```

Test coverage:

```
tests/
+-- unit/
|   +-- utils/
|   |   +-- ApiError.test.js       (6 tests)  Custom exception class
|   |   +-- geo.test.js            (6 tests)  Haversine formula accuracy
|   +-- services/
|       +-- itemService.test.js    (10 tests) Business logic + ownership guards
|       +-- donationService.test.js (8 tests) Donation rules + error cases
+-- integration/
    +-- health.test.js             (4 tests)  HTTP endpoint smoke tests
```

All unit tests use **mocked repositories** — zero real DB or Firebase calls in CI.

---

## CI/CD

GitHub Actions runs on every push to `main` and on all pull requests:

| Job | What it does |
|-----|-------------|
| `test (18.x)` | Full test suite on Node.js 18 |
| `test (20.x)` | Full test suite on Node.js 20, uploads coverage artifact |
| `lint-check` | Syntax validation on all 50 source files |

Railway auto-deploys on every push to `main`.

---

## Performance & Scalability

Optimized for **1,000+ concurrent users**:

| Optimization | Detail |
|-------------|--------|
| SQLite WAL mode | Concurrent reads/writes without blocking |
| 64 MB page cache | Reduces disk I/O dramatically |
| Firebase token cache | 5-min TTL — avoids per-request Firebase round-trips |
| 16 DB indexes | No full table scans on hot queries |
| Bounding box pre-filter | Geographic pre-filter before Haversine calculation |
| Offset pagination | Feed loads 20 items at a time |
| Socket room cache | In-memory Set — no DB query per message |
| Per-endpoint rate limiting | Auth, upload, chat protected independently |
| `busy_timeout = 5000 ms` | Prevents write-contention crashes under load |

---

## Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit: `git commit -m 'feat: describe your change'`
4. Push: `git push origin feature/your-feature`
5. Open a Pull Request

Commit format (Conventional Commits):
```
feat:     New feature
fix:      Bug fix
perf:     Performance improvement
test:     Add or update tests
docs:     Documentation only
refactor: Restructuring without behavior change
chore:    Build / config changes
```

---

## License

[MIT License](LICENSE) (c) 2025 rukiyekoruyucu

---

<div align="center">

**FoodBridge** — Be a bridge against food waste

*Made with love in Turkey*

</div>
