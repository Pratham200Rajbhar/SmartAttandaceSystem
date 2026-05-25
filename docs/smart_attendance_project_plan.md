# Smart Attendance System (SAS) — Complete Project Plan

## 1. Problem Statement

Traditional attendance systems in educational institutions suffer from several critical issues:

- **Proxy Attendance** — Students mark attendance on behalf of absent peers
- **Manual Errors** — Paper-based or roll-call methods are error-prone and inefficient
- **Time Wastage** — Calling roll consumes 5–10 minutes of every lecture
- **No Real-Time Visibility** — Teachers and admins have no live insight into attendance patterns
- **Lack of Accountability** — Students face no immediate consequences for irregular attendance
- **Data Inconsistency** — Manually maintained registers are easily lost, tampered with, or misrecorded
- **No Environment Verification** — Existing digital systems do not verify *where* or *in what context* attendance is being marked

These challenges directly impact academic integrity, administrative efficiency, and student performance tracking.

---

## 2. Our Solution

The **Smart Attendance System (SAS)** is a fully automated, AI-powered attendance platform that makes proxy attendance virtually impossible by verifying:

1. **Who you are** — Face Recognition
2. **That you're alive and present** — Liveness Detection
3. **Where you are** — GPS Geofencing
4. **That you're in a classroom** — Background Validation

Students mark attendance in seconds via a mobile app. Teachers and admins monitor everything live through a web dashboard. The entire process is secure, transparent, and data-driven.

---

## 3. Core Features

### 3.1 Student Mobile App (Flutter)
- JWT-secured login with role-based access
- One-tap attendance marking with multi-layer AI verification
- Real-time attendance status and history view
- Low-attendance alerts and push notifications
- Offline attendance capture with automatic background sync

### 3.2 Face Recognition & Liveness Detection
- Camera captures student's face during attendance
- Deep learning model matches face against stored embeddings
- Confidence score recorded for every attempt
- Liveness check prevents spoofing via photos or videos
- Attempts with low confidence are automatically flagged

### 3.3 Background Validation
- Image classification model analyzes the background scene
- Only classroom-like environments are accepted
- Rejects attempts from home, outdoors, or other non-academic settings

### 3.4 Geolocation & Geofencing
- GPS coordinates captured at the time of marking
- System checks if the student is within the defined geofence radius (default: 50 meters)
- Out-of-boundary attempts are blocked or flagged
- Admin can configure custom geofence per class/room
- System detects and rejects GPS spoofing attempts

### 3.6 Teacher Dashboard (React.js)
- Live class-wise attendance view
- Highlighted flagged/suspicious entries for manual review
- Approve or reject flagged attendance with remarks
- Generate subject-wise and date-range attendance reports
- Receive alerts for suspicious attendance bursts

### 3.7 Admin Dashboard (React.js)
- Full user management: create, edit, delete students and teachers
- Assign classes, subjects, semesters, and departments
- Configure geofence zones per classroom
- Institution-wide analytics and reporting
- Audit logs for all system events
- Role and permission management

### 3.8 Notification System
- Students: low attendance warnings, attendance confirmation
- Teachers: flagged entry alerts, session reminders
- Admins: system anomalies, bulk absentee reports

### 3.9 Offline Support
- Attendance data stored locally when no internet is available
- Automatic sync to the server once connectivity is restored
- No attendance data lost due to network issues

---

## 4. Additional Features (Making SAS Unique)

These enhancements go beyond the base SRS and significantly improve the system's robustness, intelligence, and user experience.

### 4.1 AI Decision Engine with Weighted Scoring
Instead of a simple pass/fail, every attendance attempt produces a **composite confidence score** from three AI modules:

| Module | Weight |
|---|---|
| Face Recognition | 50% |
| Liveness Detection | 30% |
| Background Validation | 20% |

Score ≥ 0.75 → **Present**
Score < 0.75 → **Flagged for Teacher Review**

This nuanced approach eliminates false rejections while maintaining high security.


### 4.2 Absentee Pattern Detection
- ML-based anomaly detection flags students with irregular attendance patterns
- Automatically generates early warning reports before attendance drops below the threshold (e.g., below 75%)
- Helps teachers intervene proactively

### 4.3 Anti-Spoofing for GPS
- Cross-validates GPS coordinates with network triangulation data
- Detects mock location apps (common on Android)
- Flags or blocks tampered location attempts automatically

### 4.4 Attendance Analytics Dashboard
- Visual charts: attendance percentage by student, class, subject, and time period
- Heatmaps of attendance trends across weeks and months
- Exportable PDF/CSV reports for official use

### 4.5 Session-Based Attendance Control
- Teachers start and stop an attendance window (e.g., 10-minute window)
- Students can only mark attendance during the active session window
- Prevents post-class or pre-class attendance manipulation

### 4.6 Multi-Factor Verification Log (Audit Trail)
- Every attendance attempt stores a full log: face snapshot, background image, GPS coordinates, all confidence scores, and final decision
- Admins can audit any flagged record with complete evidence
- Tamper-proof records stored in PostgreSQL

### 4.7 Role-Based Notification Customization
- Each user role receives only relevant, context-aware notifications
- Teachers can configure alert thresholds (e.g., alert if more than 5 students are absent)

### 4.8 Edge AI Ready Architecture
- AI models are designed to be deployable on-device (TensorFlow Lite)
- Reduces server load and allows attendance marking with minimal internet
- Future-proof for rural campuses with poor connectivity

### 4.9 LMS Integration (Future Ready)
- API hooks designed to connect with Google Classroom, Moodle, or any LMS
- Attendance data can be auto-synced to course records

### 4.10 Multi-Institution / Multi-Campus Support
- Architecture supports multiple departments, campuses, or colleges under one admin panel
- Data is segregated per institution with shared infrastructure

---

## 5. Technology Stack

### 5.1 Mobile Application
| Component | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Platform | Android 8.0 (Oreo) and above |
| State Management | Provider / Riverpod |
| Local Storage | SQLite (offline sync) |
| Camera Access | Flutter Camera Plugin |
| Location Services | Geolocator Plugin |
| Authentication | JWT Token (stored in Secure Storage) |
| Maps & Geofencing | Google Maps API |

### 5.2 Web Dashboard
| Component | Technology |
|---|---|
| Framework | React.js |
| UI Library | Tailwind CSS / Material UI |
| Charts & Analytics | Recharts / Chart.js |
| State Management | Redux / Context API |
| HTTP Client | Axios |
| Authentication | JWT (stored in HttpOnly Cookie) |

### 5.3 Backend
| Component | Technology |
|---|---|
| Framework | FastAPI (Python) |
| Language | Python 3.10+ |
| Database | PostgreSQL 13+ |
| Caching / Sessions | Redis |
| Authentication | JWT + bcrypt password hashing |
| File Storage | Local / Cloud (AWS S3 or equivalent) |
| Deployment | Docker + Nginx |
| Version Control | Git / GitHub |
| API Testing | Postman |
| OS | Ubuntu 20.04 LTS |

### 5.4 AI & ML Stack
| Component | Technology |
|---|---|
| Face Detection | OpenCV / MediaPipe |
| Face Recognition | DeepFace / FaceNet / InsightFace |
| Liveness Detection | Custom CNN / Silent Liveness Models |
| Background Classification | MobileNetV2 / EfficientNet (TensorFlow/Keras) |
| Model Serving | FastAPI integrated inference endpoints |
| Edge AI (Future) | TensorFlow Lite |

---

## 6. AI Models — Deep Dive

### 6.1 Face Recognition
**Goal:** Verify that the person marking attendance is the registered student.

**Approach:**
- Student face embeddings (128-d or 512-d vectors) stored during registration
- At attendance time, the live face is captured and converted to an embedding
- Cosine similarity or Euclidean distance calculated between live and stored embeddings
- Threshold-based decision (e.g., similarity > 0.85 = match)

**Recommended Models:** FaceNet, ArcFace (InsightFace), or DeepFace wrapper

**Why it works:** Embedding-based models are robust to lighting variation, minor pose changes, and aging.

### 6.2 Liveness Detection
**Goal:** Ensure the face is from a real, physically present person, not a photo or video replay.

**Approach:**
- Passive liveness: Analyze texture, reflection patterns, and depth cues from a single frame
- Active liveness (optional enhancement): Prompt the student to blink or turn head
- CNN trained to classify "real face" vs "spoof (photo/screen/mask)"

**Recommended Models:** Silent-Face-Anti-Spoofing (MiniFASNet), or custom MobileNet-based binary classifier

**Output:** Liveness confidence score (0.0–1.0)

### 6.3 Background Validation
**Goal:** Confirm the student is in a classroom-like environment, not at home or outdoors.

**Approach:**
- Image classification using a lightweight CNN
- Transfer learning on MobileNetV2 pretrained on ImageNet
- Fine-tuned on a custom dataset: classroom vs. non-classroom images
- Outputs a background confidence score

**Classes:** Classroom (valid) vs. Home / Outdoors / Other (invalid)

**Output:** Background confidence score (0.0–1.0)

### 6.4 AI Decision Engine
**Goal:** Combine all three scores into one final attendance decision.

**Formula:**
```
Final Score = (0.50 × face_score) + (0.30 × liveness_score)
            + (0.20 × background_score)

If geofence_valid == False → Auto-reject (regardless of AI scores)
If Final Score >= 0.75 → Status = Present
If Final Score < 0.75  → Status = Flagged (Teacher Review Required)
```


**Why this design:** Weighted scoring ensures that face and liveness (hardest to fake) carry the most weight, while background serves as a corroborating signal.

---

## 7. Database Design Summary

### Core Tables

| Table | Purpose |
|---|---|
| `users` | Central identity store for all roles |
| `students` | Student academic profile, enrollment, face embedding |
| `teachers` | Teacher department and designation info |
| `classes` | Class/subject mapped to a teacher |
| `geofences` | GPS boundary per class (lat, lng, radius) |
| `attendance` | Full attendance record with all confidence scores |
| `env_metrics` | Background image, environment confidence |
| `notifications` | System-generated messages per user |
| `sessions` | Active attendance windows opened by teachers |

### Key Relationships
- `students` → `users` (FK: user_id)
- `teachers` → `users` (FK: user_id)
- `attendance` → `students`, `classes`, `teachers` (FK)
- `geofences` → `classes` (FK: class_id)
- `env_metrics` → `attendance` (FK: attendance_id)
- `notifications` → `users` (FK: user_id)

---

## 8. System Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                   CLIENT LAYER                          │
│   Flutter Mobile App (Student)  │  React.js Dashboard  │
│                                 │  (Teacher + Admin)    │
└──────────────────┬──────────────┴──────────┬────────────┘
                   │ HTTPS / JWT             │ HTTPS / JWT
                   ▼                         ▼
┌─────────────────────────────────────────────────────────┐
│                  BACKEND LAYER (FastAPI)                │
│  ┌────────────┐ ┌──────────────┐ ┌───────────────────┐  │
│  │ Auth API   │ │ Attendance   │ │  Admin/Teacher    │  │
│  │ (JWT)      │ │ Verification │ │  Management API   │  │
│  └────────────┘ └──────┬───────┘ └───────────────────┘  │
│                        │                                 │
│                ┌───────▼────────┐                        │
│                │  AI Inference  │                        │
│                │  Engine        │                        │
│                │ • Face Recog.  │                        │
│                │ • Liveness     │                        │
│                │ • Background   │                        │
│                                        │
│                └───────┬────────┘                        │
└────────────────────────┼────────────────────────────────┘
                         │
          ┌──────────────┴──────────────┐
          ▼                             ▼
┌──────────────────┐         ┌──────────────────┐
│  PostgreSQL DB   │         │  Redis Cache     │
│  (Primary Store) │         │  (Sessions/OTP)  │
└──────────────────┘         └──────────────────┘
```

---

## 9. Security Design

| Threat | Mitigation |
|---|---|
| Proxy attendance (photo spoofing) | Liveness detection |
| Proxy attendance (location faking) | GPS anti-spoofing + geofencing |
| Unauthorized access | JWT + role-based access control |
| Data interception | HTTPS/SSL end-to-end encryption |
| Brute force login | Rate limiting + account lockout |
| Data tampering | Audit logs + immutable attendance records |
| Insecure data storage | Encrypted local storage on mobile |
| API abuse | JWT expiry + refresh token rotation |

---

## 10. Non-Functional Requirements Summary

| Requirement | Target |
|---|---|
| Response time per attendance request | ≤ 3 seconds |
| Concurrent users supported | Up to 5,000 |
| System uptime | ≥ 99% |
| Mobile platform support | Android 8.0+ |
| Browser support | Chrome, Firefox, Edge (latest) |
| Backend OS | Ubuntu 20.04 LTS |
| Data backup | Automated cloud backups |
| Horizontal scaling | Docker + Kubernetes ready |

---

## 11. Development Process: Agile (Scrum)

### Why Agile?
- AI modules (face, liveness, background) need iterative tuning — Agile supports this naturally
- Multiple parallel workstreams (mobile, backend, dashboard, AI) fit sprint-based parallel development
- Requirements like geofence radius and AI thresholds can change — Agile accommodates this
- Early testing per sprint means issues are caught before they compound

### Sprint Plan (18 Weeks)

| Sprint | Weeks | Focus |
|---|---|---|
| Sprint 1 | 1–3 | Requirement analysis, system design, backend + app scaffolding, JWT auth |
| Sprint 2 | 3–5 | Face recognition integration, liveness detection, attendance API |
| Sprint 3 | 5–7 | Background validation module, decision engine |
| Sprint 4 | 7–9 | GPS geofencing, offline storage, auto-sync mechanism |
| Sprint 5 | 10–12 | Teacher dashboard: live attendance, flagged records, manual correction |
| Sprint 6 | 12–14 | Admin dashboard: user management, geofence config, analytics/reports |
| Sprint 7 | 14–16 | Full integration testing, load testing, AI threshold tuning |
| Sprint 8 | 16–18 | Docker deployment, documentation, final review, demo preparation |

---

## 12. Project Timeline (Gantt Summary)

| Phase | Weeks |
|---|---|
| Requirement Analysis | 1 – 3 |
| System Design (UI + Backend) | 3 – 6 |
| Backend & Database Setup | 6 – 9 |
| Mobile App Development | 6 – 10 |
| Web Dashboard Development | 10 – 13 |
| Integration & Testing | 13 – 16 |
| Deployment | 16 – 17 |
| Final Review & Documentation | 17 – 18 |

**Key note:** Mobile App and Backend development overlap intentionally (Weeks 6–9) to reduce total delivery time.

---

## 13. Hardware Requirements Summary

| Role | Minimum Specs |
|---|---|
| Student Device | Android phone, 3GB RAM, 5MP front camera, GPS, 3G/4G |
| Teacher Device | Laptop/PC, Core i3 6th Gen, 4GB RAM, stable internet |
| Admin Device | Laptop/PC, Core i5, 8GB RAM, Full HD display |
| Backend Server | Quad-core 2.0 GHz+, 8GB RAM, 100GB SSD, high-speed internet |

---

## 14. Future Enhancements

1. **LMS Integration** — Sync with Google Classroom, Moodle, or other platforms automatically
2. **Multi-Institution Panel** — One super-admin managing multiple campuses
3. **Edge AI on Device** — Run face recognition and liveness locally via TensorFlow Lite (no internet needed for AI checks)
4. **iOS Support** — Extend Flutter app to support iOS devices
5. **Dark Mode & Accessibility** — Improve mobile UX with theming and accessibility features
6. **Auto-Scaling Backend** — Kubernetes-based horizontal scaling for large institutions
7. **Behavioral Analytics** — Detect chronic absenteeism trends using ML clustering
8. **Biometric Fallback** — Fingerprint-based backup verification if face recognition fails
9. **Parent Portal** — Read-only portal for parents to track ward's attendance
10. **Chatbot Support** — AI assistant for students to query their attendance and get academic guidance

---

## 15. Conclusion

The Smart Attendance System is not just an attendance tool — it is a complete academic integrity platform. By combining state-of-the-art AI verification (face, liveness, background) with geolocation enforcement and real-time dashboards, it eliminates every known vector for attendance fraud while providing actionable analytics to educators.

Built on a modern, scalable stack (Flutter · React.js · FastAPI · PostgreSQL · Redis · Docker), the system is production-ready, extensible, and designed to grow from a single department to an entire university network.

---

*Document prepared based on SRS v1.0 | Smart Attendance System | Capstone Project-I | Ganpat University*
