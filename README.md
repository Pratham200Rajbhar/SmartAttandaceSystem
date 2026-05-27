# Smart Attendance System

An AI-powered multi-layered attendance verification platform that eliminates proxy attendance in educational institutions through face recognition, liveness detection, GPS geofencing, and background validation.

## Problem

Traditional attendance systems in educational institutions are vulnerable to proxy attendance — students marking attendance on behalf of others. Existing solutions lack multi-factor verification and are easily bypassed.

## Solution

The Smart Attendance System provides a three-tier verification approach:

- **Student Mobile App** — Students capture a live selfie within a GPS-bounded geofence. The app automatically collects location data and captures facial images for AI verification.
- **AI Inference Engine** — Three neural networks work together: face recognition (matching against enrolled embeddings), liveness detection (anti-spoofing against photos/videos), and background validation (confirming the environment is a classroom).
- **Teacher Web Dashboard** — Teachers manage live attendance sessions, review flagged entries with AI confidence scores, and have final decision authority through an intuitive web interface.

A weighted decision engine computes a final confidence score. High-confidence entries are auto-approved; borderline cases are flagged for teacher review.

## Key Features

- **Multi-layer AI verification** — face recognition, liveness detection, background validation
- **GPS geofencing** — restricts attendance marking to authorized locations
- **Real-time attendance** — live session rosters via WebSocket
- **Offline support** — attendance queues sync when connectivity resumes
- **Device binding** — hardware UUID lock prevents account sharing
- **Smart Pass** — QR-based time-limited verification
- **Comprehensive dashboards** — teacher review queue, admin management, analytics, CSV export
- **Absentee pattern detection** — ML-based anomaly detection on attendance history
- **Full audit trail** — all actions logged for accountability

## Architecture Overview

The system has three components:

- **Flutter Mobile App** (students) — camera, GPS, offline storage, push notifications
- **Next.js Web Dashboard** (teachers & admins) — session management, flagged review, analytics, CRUD
- **FastAPI Backend** (Python) — REST API, WebSocket, AI inference, PostgreSQL + Redis

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend | FastAPI (Python), PostgreSQL, Redis, TensorFlow, DeepFace |
| Frontend | Next.js, React, Tailwind CSS, Leaflet, Recharts |
| Mobile | Flutter, Riverpod, Dio, Hive, Firebase |
| Infrastructure | Docker, GitHub Actions, Vercel |

## Getting Started

### Backend
```bash
cd backend
cp .env.example .env    # configure database, JWT, Redis
docker compose up --build
```

### Frontend
```bash
cd frontend
npm install
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1 npm run dev
```

### Mobile
```bash
cd mobile
flutter pub get
flutter run
```

## License

MIT
