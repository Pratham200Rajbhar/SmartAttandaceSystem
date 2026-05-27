# Requirements Document

## Introduction

This feature adds an **AI Score Review** step to the mobile attendance verification flow. Currently, the student captures a photo and immediately submits it — the backend runs AI analysis (face match, liveness, background) and marks attendance in a single call, with scores only visible on the final result screen.

The new flow inserts a dedicated review step between photo preview and final submission. The app calls the backend to obtain AI scores, presents them to the student, and only marks attendance after the student explicitly confirms. The student may also retake the photo from the review screen if the scores are unsatisfactory.

This requires a decision on the backend strategy: either a new "score-only" endpoint that runs AI analysis without writing an attendance record, or a "hold-and-confirm" pattern where the frontend calls the existing endpoint and defers navigation to the result screen until the student confirms. Both approaches are captured as requirements so the design phase can select the appropriate one.

---

## Glossary

- **Verification_Flow**: The multi-step in-app process a student follows to mark attendance (GPS → Camera → Preview → AI Score Review → Confirm Submit → Result).
- **AI_Score_Review_Screen**: The new step in the Verification_Flow where AI scores are displayed to the student before attendance is marked.
- **AI_Scores**: The four numeric values returned by the backend AI pipeline: `face_score`, `liveness_score`, `background_score`, and `final_ai_score`, each in the range [0.0, 1.0].
- **Score_Preview_Endpoint**: A new backend endpoint (`POST /student/attendance/score-preview`) that runs the AI pipeline and returns AI_Scores without writing an attendance record to the database.
- **Mark_Endpoint**: The existing backend endpoint (`POST /student/attendance/mark`) that runs the AI pipeline, writes an attendance record, and returns `AttendanceMarkResponse`.
- **Attendance_Notifier**: The `AttendanceNotifier` Riverpod `StateNotifier` in `attendance_provider.dart` that manages `AttendanceVerificationState`.
- **VerificationStep**: The Dart enum in `attendance_provider.dart` that represents the current step in the Verification_Flow.
- **AttendanceResult**: The Dart domain model in `attendance.dart` that holds all score fields and attendance status.
- **ScorePreviewResult**: A new Dart domain model that holds AI_Scores returned by the Score_Preview_Endpoint, without attendance record fields (id, status, createdAt).
- **Session**: An active class session identified by a `sessionId` string, within which a student may mark attendance.

---

## Requirements

### Requirement 1: New AI Score Review Step in the Verification Flow

**User Story:** As a student, I want to see my AI verification scores before my attendance is marked, so that I can decide whether to confirm or retake the photo.

#### Acceptance Criteria

1. THE Verification_Flow SHALL include the steps: GPS Verification → Camera Capture → Photo Preview → AI Score Review → Confirm Submit → Result, in that order.
2. WHEN the student taps "Submit" on the Photo Preview step, THE Verification_Flow SHALL transition to the AI Score Review step instead of immediately marking attendance.
3. WHILE the AI Score Review step is active, THE AI_Score_Review_Screen SHALL display the four AI_Scores: `face_score`, `liveness_score`, `background_score`, and `final_ai_score`.
4. WHILE the AI Score Review step is active, THE AI_Score_Review_Screen SHALL display a "Confirm" action and a "Retake" action.
5. THE VerificationStep enum SHALL include an `aiReview` value representing the AI Score Review step.
6. THE Attendance_Notifier SHALL expose a method to transition from the `preview` step to the `aiReview` step.

---

### Requirement 2: Backend Score Preview Without Marking Attendance

**User Story:** As a student, I want the app to fetch my AI scores without marking attendance, so that reviewing scores does not create a premature or duplicate attendance record.

#### Acceptance Criteria

1. THE Score_Preview_Endpoint SHALL accept the same multipart form fields as the Mark_Endpoint: `session_id`, `latitude`, `longitude`, `accuracy`, and `image`.
2. WHEN a valid request is received, THE Score_Preview_Endpoint SHALL run the AI pipeline and return `face_score`, `liveness_score`, `background_score`, and `final_ai_score`.
3. IF the AI pipeline fails or produces invalid results, THEN THE Score_Preview_Endpoint SHALL return HTTP 500 with a descriptive error message and SHALL NOT return partial scores.
4. WHEN a valid request is received, THE Score_Preview_Endpoint SHALL NOT write any attendance record to the database.
5. IF the `session_id` does not correspond to an active Session, THEN THE Score_Preview_Endpoint SHALL return HTTP 400 with a descriptive error message. IF the session is active but does not belong to the authenticated student's enrolled classes, THEN THE Score_Preview_Endpoint SHALL return HTTP 403 with a descriptive error message.
6. IF the student does not have a registered face embedding, THEN THE Score_Preview_Endpoint SHALL return HTTP 400 with a descriptive error message.
7. THE Score_Preview_Endpoint SHALL require the same student authentication as the Mark_Endpoint.
8. THE ScorePreviewResult Dart model SHALL contain the fields: `faceScore`, `livenessScore`, `backgroundScore`, and `finalAiScore`, each of type `double`.

---

### Requirement 3: Fetch AI Scores on Entering the Review Step

**User Story:** As a student, I want the app to automatically fetch my AI scores when I reach the review screen, so that I do not need to take any extra action to see them.

#### Acceptance Criteria

1. WHEN the Verification_Flow transitions to the `aiReview` step, THE Attendance_Notifier SHALL automatically call the Score_Preview_Endpoint with the captured image and GPS data.
2. WHILE the Score_Preview_Endpoint call is in progress, THE AI_Score_Review_Screen SHALL display a loading indicator.
3. WHEN the Score_Preview_Endpoint returns successfully, THE Attendance_Notifier SHALL store the ScorePreviewResult in the verification state.
4. WHEN the ScorePreviewResult is available, THE AI_Score_Review_Screen SHALL display the AI_Scores with the same animated score rings and progress bars used on the Result screen.
5. IF the Score_Preview_Endpoint call fails, THEN THE Attendance_Notifier SHALL store the error message in the verification state and THE AI_Score_Review_Screen SHALL display the error with a "Retry" option.
6. IF the Score_Preview_Endpoint call fails, THEN THE AI_Score_Review_Screen SHALL also display a "Retake Photo" option so the student is not blocked.

---

### Requirement 4: Confirm Submission from the Review Screen

**User Story:** As a student, I want to confirm my attendance submission after reviewing my AI scores, so that I have explicit control over when my attendance is marked.

#### Acceptance Criteria

1. WHEN the student taps "Confirm" on the AI_Score_Review_Screen, THE Attendance_Notifier SHALL call the Mark_Endpoint with the same image and GPS data used for the score preview.
2. WHEN the Mark_Endpoint returns successfully, THE Verification_Flow SHALL transition to the `done` step and navigate to the Result screen.
3. WHILE the Mark_Endpoint call is in progress after confirmation, THE Verification_Flow SHALL display the existing submitting animation (AI step labels and progress dots).
4. IF the Mark_Endpoint call fails after confirmation, THEN THE Attendance_Notifier SHALL set the error state and THE Verification_Flow SHALL transition to the `done` step, displaying the error on the Result screen.
5. IF the device is offline when the student taps "Confirm", THEN THE Attendance_Notifier SHALL queue the submission for offline sync, consistent with the existing offline behaviour in `AttendanceRepository`.

---

### Requirement 5: Retake Photo from the Review Screen

**User Story:** As a student, I want to retake my photo from the AI Score Review screen if I am unhappy with the scores, so that I can improve my verification result before submitting.

#### Acceptance Criteria

1. WHEN the student taps "Retake" on the AI_Score_Review_Screen, THE Verification_Flow SHALL discard the current image and ScorePreviewResult and transition back to the `camera` step.
2. WHEN the Verification_Flow transitions back to the `camera` step from `aiReview`, THE Attendance_Notifier SHALL clear `imagePath`, `scorePreviewResult`, and any stored error from the state.
3. WHEN the Verification_Flow transitions back to the `camera` step from `aiReview`, THE camera controller SHALL be re-initialised so the student can capture a new photo.
4. THE Verification_Flow SHALL allow the student to retake the photo and reach the AI_Score_Review_Screen again without restarting GPS verification.

---

### Requirement 6: Step Indicator Reflects the New Flow

**User Story:** As a student, I want the step indicator at the top of the verification screen to show my current position in the updated flow, so that I always know how many steps remain.

#### Acceptance Criteria

1. THE step indicator SHALL display five steps: "GPS", "Camera", "Review", "AI Score", "Submit".
2. WHEN the Verification_Flow is on the `aiReview` step, THE step indicator SHALL highlight steps 1 through 4 as active.
3. WHEN the Verification_Flow is on the `submitting` or `done` step, THE step indicator SHALL highlight all five steps as active.
4. THE step indicator SHALL remain consistent with the existing visual style (numbered circles, connecting lines, emerald active colour).

---

### Requirement 7: Offline Handling for Score Preview

**User Story:** As a student, I want the app to handle network unavailability gracefully during the score preview call, so that I am not left on a broken screen.

#### Acceptance Criteria

1. IF the device has no network connectivity when the Verification_Flow transitions to the `aiReview` step, THEN THE AI_Score_Review_Screen SHALL display a message indicating that AI score preview is unavailable offline.
2. IF the device has no network connectivity on the `aiReview` step, THEN THE AI_Score_Review_Screen SHALL offer a "Submit Anyway" action that bypasses score preview and queues the submission for offline sync.
3. IF the device has no network connectivity on the `aiReview` step, THEN THE AI_Score_Review_Screen SHALL offer a "Retake Photo" action.
4. WHEN the student taps "Submit Anyway" while offline, THE Attendance_Notifier SHALL queue the submission using the existing `OfflineQueued` path in `AttendanceRepository` and transition to the `done` step.
