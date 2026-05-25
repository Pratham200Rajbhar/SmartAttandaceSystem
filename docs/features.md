### 👑 The Admin Dashboard (System & Infrastructure)

The Admin role is the root user responsible for setting up the baseline data and running high-level anomaly detection.

* **Identity & Access Management**
* **Student Registration:** Create student profiles (Email, Password, Enrollment Number).
* **Teacher Registration:** Create teacher profiles (Email, Password, Department).
* **User Directory:** A searchable, paginated data table to view and manage all system users.


* **Academic Infrastructure**
* **Class Setup:** Create new academic entities (e.g., "Software Engineering 401").
* **Teacher Assignment:** Link a specific teacher account to a class.
* **Bulk Enrollment:** Upload or input a list of student IDs to instantly enroll a cohort into a specific class.


* **AI & Data Science Hub**
* **Absentee Pattern Scanner:** A dedicated page to manually trigger the `IsolationForest` ML model.
* **Anomaly Reports:** A warning dashboard highlighting specific students exhibiting hidden skipping patterns or sudden attendance drops.



---

### 🎓 The Teacher Dashboard (Classroom Execution)

The Teacher role is scoped entirely to the specific classes they are assigned to manage.

* **Pre-Class Configuration**
* **My Classes Hub:** A grid displaying only their assigned classes.
* **Geofence Setup:** An interactive Leaflet map where the teacher can drop a GPS pin on their lecture hall and adjust the valid radius (in meters) for attendance marking.


* **Live Session Execution**
* **Session Controls:** "Start" and "Stop" toggles to open and close the timed attendance window.
* **Real-Time Roster:** A live-updating data table categorizing students as Present, Flagged, or Absent.
* **Emergency Manual Override:** Inline "Present" and "Absent" action buttons next to every student's name on the live roster, allowing the teacher to bypass the AI entirely if a student's phone breaks or the network fails.


* **Post-Class Review (Human-in-the-Loop)**
* **Flagged Queue:** A list of students who attempted attendance but failed an AI check (e.g., GPS mismatch, low face match, spoofing attempt).
* **Evidence Dashboard:** Displays the exact AI confidence scores for the flagged attempt.
* **Resolution Controls:** "Approve" (override to Present) or "Reject" (override to Absent) buttons to resolve the flagged status.


* **Analytics & Insights**
* **Class Trends:** Visual Recharts graphs showing the overall attendance percentage over the semester.
* **Historical Logs:** An archive of all past sessions to view old rosters.


