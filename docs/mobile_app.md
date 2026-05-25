### Phase 1: Onboarding & The "Lock-In" Flow

This flow ensures that students cannot share accounts, use fake photos, or mark attendance from a friend's phone.

**Screen 1: Splash & Auth Check**

* **Functionality:** Silently checks if a JWT token is already stored securely on the device. Routes to Dashboard if true, Login if false.

**Screen 2: Secure Login Screen**

* **Functionality:** Accepts University Email and Password (provided initially by the Admin).
* **Device Binding Trigger:** On successful login, the Flutter app reads the phone's unique hardware UUID. It sends this UUID to the backend. If the account already has a *different* UUID attached, the login is blocked with an error: *"Account bound to another device. Contact Admin."*

**Screen 3: Profile Setup (The Master Face Registration)**

* **Trigger:** Happens *only once*. If the backend returns `face_embedding: null` after login, the app locks the user on this screen.
* **UI/UX:** A camera viewfinder with an oval overlay (to guide the face). Text reads: *"Let's set up your secure profile. Look straight into the camera."*
* **Functionality:** The student takes a live photo. The app uploads it to FastAPI (`POST /api/student/register-face`). FastAPI runs DeepFace, saves the master embedding, and locks the profile permanently.

---

### Phase 2: The Core Hub

Once authenticated and registered, this is where the student spends 90% of their time.

**Screen 4: The Home Dashboard (Live Schedule)**

* **Functionality:** Fetches the student's personalized timetable for the current day from the PostgreSQL database.
* **UI/UX:** * A top greeting card: *"Welcome back, [Name]. Roll No: 104"*.
* A vertical list of "Class Cards" (e.g., *Software Engineering 401*, *Database Management*).
* **The Active State:** If a teacher has clicked "Start Session" on their web dashboard, that specific Class Card dynamically changes color (e.g., pulses green) and a large **"Mark Attendance"** button appears inside it.



---

### Phase 3: The Verification Engine (The Daily Action)

This is the strict sequence that runs when a student taps the "Mark Attendance" button on the Home Dashboard.

**Screen 5: The "Verification" Screen**

* **Step 1: GPS Lock (Silent):** The app instantly requests the device's location. A small loading spinner says *"Verifying location..."* until it secures Latitude and Longitude.
* **Step 2: Camera Capture:** The front camera opens automatically. The gallery button is completely disabled to prevent uploading old photos.
* **Step 3: Submission:** The user snaps the photo. The app packages the `student_id`, `session_id`, `latitude`, `longitude`, and the `image_file` into a secure request and sends it to your AI Orchestrator.

**Screen 6: The Result Screen**

* **Functionality:** Displays the immediate outcome from the FastAPI server.
* **Success State:** A massive Green Checkmark. *"Verified! You are marked Present for SE-401."*
* **Flagged State:** A warning Orange Icon. *"Attempt Flagged. Your teacher will review this."* (Triggered if the AI detects spoofing, invalid background, or GPS outside the geofence).

---

### Phase 4: The Offline Mode Engine (Invisible UX)

Universities often have terrible Wi-Fi in lecture halls. Your app must handle this gracefully.

* **The Flow:** If the student is on the Verification Screen (Screen 5) and the phone detects **No Internet**:
1. The app still captures the GPS and the Photo.
2. Instead of calling FastAPI, it saves the payload into a local encrypted database (like SQLite or Flutter's `Hive`).
3. The Result Screen (Screen 6) shows a Blue Sync Icon: *"Saved Offline. Do not close the app. We will sync when you connect to Wi-Fi."*
4. A background worker (using a package like `workmanager`) constantly listens for an internet connection and silently pushes the payload to the server once online.



---

### Phase 5: Analytics & Management

**Screen 7: Attendance History (Calendar View)**

* **Functionality:** A visual calendar where days are dotted Green (Present), Red (Absent), or Orange (Flagged).
* **Details:** Tapping a day shows exactly which classes were attended.

**Screen 8: Warning & Notification Center**

* **Functionality:** If your Python `IsolationForest` scanner flags the student for a dangerous skipping pattern, a Push Notification is sent to the phone.
* **UI/UX:** A dedicated alerts tab showing institutional warnings.

**Screen 9: Settings / Profile**

* **Functionality:** View basic info, log out, and request a "Device Reset" (sends a notification to the Admin web dashboard if the student buys a new phone and needs their hardware lock cleared).

### Recommended Flutter Packages for this Build:

* `camera`: For the live selfie capture.
* `geolocator`: For highly accurate, native GPS coordinates.
* `device_info_plus`: To grab the unique hardware ID for Device Binding.
* `hive` or `sqflite`: For securely caching offline attendance data.
* `dio`: For handling the complex `multipart/form-data` image uploads to your FastAPI server.