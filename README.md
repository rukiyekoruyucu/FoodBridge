# FoodBridge Backend Pro

Node.js + Express + PostgreSQL (Supabase) + Redis + Firebase Auth tabanlı, rol bazlı (NEEDY / PERSONAL / CORPORATE) FoodBridge backend.

## Kurulum

```bash
npm install
cp .env.example .env
# .env dosyasını kendi bilgilerinle doldur
npm run dev
```

### Temel Endpointler

- `GET /health`
- `POST /api/auth/register` (Firebase token zorunlu)
- `GET /api/auth/me`
- `GET /api/users/me/summary`
- `POST /api/fridges` (PERSONAL / CORPORATE)
- `GET /api/fridges/nearby?lat=..&lon=..&radiusKm=5`
- `POST /api/fridges/:fridgeId/items`
- `GET /api/fridges/:fridgeId/items`
- `POST /api/donations`
- `POST /api/donations/:id/accept`
- `POST /api/donations/:id/complete`
- `GET /api/donations/me`
```

