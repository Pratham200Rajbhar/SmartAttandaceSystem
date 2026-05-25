# Smart Attendance System

AI-powered attendance management system with face recognition, real-time updates, and gamification.

## Tech Stack

- **Backend:** Python, FastAPI, Prisma ORM, PostgreSQL, Redis
- **Mobile:** Flutter, Riverpod, GoRouter
- **AI:** TensorFlow (MobileNetV2 liveness detection)
- **Real-time:** WebSocket
- **Notifications:** Firebase Cloud Messaging

## Features

1. **Face Recognition Attendance** — AI-powered verification with liveness detection
2. **WebSocket Real-Time Updates** — Live session status and attendance broadcasts
3. **Dispute Management** — Students can dispute flagged attendance with proof
4. **Leave Management** — Submit/approve leave requests with auto-excused logic
5. **Smart Pass** — Time-limited QR code digital ID (30s expiry)
6. **Gamification** — Attendance streaks and progress tracking
7. **At-Risk Detection** — Alerts when attendance drops below 75%
8. **Push Notifications** — FCM for attendance, leave, disputes, and warnings

## Project Structure

```
├── backend/            # FastAPI backend
│   ├── app/
│   │   ├── api/        # Route handlers
│   │   ├── services/   # Business logic
│   │   ├── repositories/ # Database access
│   │   ├── schemas/    # Pydantic models
│   │   ├── core/       # Config, security
│   │   └── db/         # Database clients
│   ├── prisma/         # Database schema
│   └── main.py
├── mobile/             # Flutter app
│   ├── lib/
│   │   ├── features/   # Feature modules
│   │   ├── shared/     # Reusable widgets
│   │   ├── data/       # API, local storage
│   │   ├── domain/     # Models, enums
│   │   └── app/        # Router, theme
│   └── android/
├── frontend/           # Next.js teacher dashboard
└── docs/               # Architecture docs
```

## Quick Start

### Backend

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
prisma generate
prisma db push
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

API docs available at `http://localhost:8000/docs`

### Mobile App

```bash
cd mobile
flutter pub get
flutter run
```

### Environment Variables

Copy `backend/.env.example` to `backend/.env` and configure:

```env
DATABASE_URL=postgresql://user:pass@localhost:5432/smart_attendance
JWT_SECRET=your-secret-key
REDIS_URL=redis://localhost:6379
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/login` — Login with email/password
- `GET /api/v1/auth/me` — Get current user profile

### Student
- `POST /api/v1/student/attendance/{session_id}` — Mark attendance
- `GET /api/v1/student/history` — Attendance history
- `POST /api/v1/student/attendance/{id}/dispute` — Submit dispute
- `POST /api/v1/student/leaves` — Create leave request
- `GET /api/v1/student/leaves` — Get leave requests
- `GET /api/v1/student/smart-pass` — Generate Smart Pass
- `GET /api/v1/student/stats` — Get gamification stats
- `POST /api/v1/student/fcm-token` — Register FCM token

### Teacher
- `POST /api/v1/teacher/sessions` — Create attendance session
- `PUT /api/v1/teacher/attendance/{id}/resolve` — Resolve dispute
- `PUT /api/v1/teacher/leaves/{id}` — Approve/reject leave

### WebSocket
- `WS /api/v1/ws/connect?token=JWT` — Real-time updates

## FCM Setup

See [FCM_SETUP_GUIDE.md](./FCM_SETUP_GUIDE.md) for Firebase Cloud Messaging configuration.

**Quick steps:**
1. Create Firebase project
2. Add `google-services.json` to `mobile/android/app/`
3. Add `firebase-credentials.json` to `backend/`
4. Run the app — FCM initializes automatically

## Testing

```bash
# Backend
cd backend
pytest

# Mobile
cd mobile
flutter analyze
flutter test

# FCM test
cd backend
python test_fcm.py
```

## Deployment

### Backend (Docker)

```bash
cd backend
docker build -t smart-attendance-backend .
docker run -p 8000:8000 --env-file .env smart-attendance-backend
```

### Mobile (Release Build)

```bash
cd mobile
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## License

Private project.
