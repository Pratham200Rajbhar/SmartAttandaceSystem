Smart Attendance System — Full Audit Report
Summary
Category
Screen Issues
UI Issues
Functionality Issues
Total
SCREEN ISSUES
#001 — Missing dispute resolution screen in mobile app
- Category: Screen
- Location: mobile/lib/features/attendance/screens/flagged_detail_screen.dart
- Description: The /flagged/:attendanceId route in the router expects FlaggedDetailScreen but this screen is missing a "Submit Dispute" flow that integrates with the backend. The backend has a full dispute submission endpoint (POST /student/attendance/{id}/dispute) but the mobile screen only shows details without allowing the user to submit a dispute with proof photo and reason.
- Root Cause: The FlaggedDetailScreen was never wired to call the dispute API despite the backend and student API client both supporting it.
- Fix: Add a "Submit Dispute" button in FlaggedDetailScreen that navigates to a new flow collecting reason text and optional proof photo, then calls studentApi.submitDispute().
#002 — Missing teacher WebSocket live-update integration
- Category: Screen
- Location: frontend/src/app/(dashboard)/teacher/sessions/[id]/roster/page.tsx
- Description: The teacher's session roster page does not connect to the WebSocket for real-time attendance updates. The backend broadcasts attendance_updated events via WebSocket (in ws.py), but the frontend roster page uses only REST polling (if at all), meaning teachers don't see live updates when students submit attendance.
- Root Cause: The frontend has no WebSocket connection logic; the roster page likely just fetches once or relies on manual refresh.
- Fix: Implement a WebSocket client in the frontend that connects to ws://backend/api/v1/ws/connect?token=... and listens for attendance_updated events for the current session, then updates the roster state.
#003 — Mobile splash screen navigation timing issue
- Category: Screen
- Location: mobile/lib/features/auth/screens/splash_screen.dart
- Description: The splash screen has a 500ms delay before calling checkInitialAuth(). If the token is valid, the router fires redirects during this delay, potentially causing a flicker or brief flash of the splash screen before navigation. More critically, if checkInitialAuth() throws an error, the auth state remains AuthStatus.loading and the splash screen shows forever with the loading spinner.
- Root Cause: No timeout/fallback mechanism for the auth check.
- Fix: Add a timeout to checkInitialAuth() (e.g., 10 seconds) and fall back to unauthenticated state if it doesn't complete.
#004 — Frontend root route "/" not handled for authenticated users
- Category: Screen
- Location: frontend/src/middleware.ts
- Description: The middleware only handles public paths and redirects / to /login. It does NOT check authentication or role-based routing. An authenticated user visiting / would always be redirected to /login, then the dashboard layout would re-check auth and redirect to the correct page — causing unnecessary navigation flicker.
- Root Cause: The middleware doesn't inspect cookies/local storage for existing auth tokens before redirecting.
- Fix: Add auth token check in middleware; if token exists, redirect authenticated users to their role-specific dashboard (/admin/dashboard or /teacher/classes) instead of /login.
UI ISSUES
#005 — Mobile: emoji in streak counter text
- Category: UI
- Location: mobile/lib/features/home/screens/home_screen.dart:663
- Description: Line 663 uses '$streak 🔥' with a fire emoji. This causes an text overflow warning on devices with small font scales or when streak is multi-digit, as emojis have unpredictable rendering width across platforms. No TextOverflow handling or sizing constraints.
- Root Cause: Hardcoded emoji in dynamic string without overflow handling.
- Fix: Move the fire emoji to a separate Icon widget with fixed size, or wrap in FittedBox.
#006 — Mobile: missing SizedBox.shrink() import assertion
- Category: UI
- Location: mobile/lib/app/router.dart:128
- Description: When route data is invalid for /flagged/:attendanceId, the router shows a SizedBox.shrink() briefly before redirecting. This produces a blank white flash. The user sees an empty screen momentarily.
- Root Cause: No full-screen loading/error placeholder before the redirect completes.
- Fix: Use a GlassLoader or shimmer placeholder instead of SizedBox.shrink().
#007 — Frontend: GlassButton disables incorrectly during loading
- Category: UI
- Location: frontend/src/components/ui/GlassButton.tsx (and login page usage at line 114)
- Description: loading prop shows a spinner but the button is still clickable if onClick is not null-checked. The login page does check isLoading ? null : _handleLogin, but other pages may not follow this pattern. The button component itself should prevent click events during loading state.
- Root Cause: The GlassButton component does not internally disable itself when loading=true.
- Fix: Inside GlassButton, when loading is true, set pointer-events: none on the button element and apply opacity styling.
#008 — Frontend: login page has incorrect gradient color syntax
- Category: UI
- Location: frontend/src/app/(auth)/login/page.tsx:66
- Description: Line 66 uses from-white/10/20 which is invalid Tailwind CSS syntax. The correct syntax would be from-white/10 or set a specific hex value. This will cause the gradient to not render, making the icon container background invisible.
- Root Cause: Invalid Tailwind CSS arbitrary value syntax (/10/20 is not a valid opacity format).
- Fix: Change bg-gradient-to-tr from-white/10/20 to-purple-500/10 to bg-gradient-to-tr from-white/[0.10] to-purple-500/10.
#009 — Mobile: calendar GridView may overflow on small screens
- Category: UI
- Location: mobile/lib/features/history/screens/history_screen.dart:411-415
- Description: The calendar grid uses GridView.count(crossAxisCount: 7, childAspectRatio: 1.0) with fixed margins. On very small screens or with system font scaling, the day cells may overflow because the aspect ratio doesn't account for the "dot" indicator below the day number.
- Root Cause: Fixed childAspectRatio without accounting for content above/below the day number.
- Fix: Use childAspectRatio: 0.85 or calculate based on available width to provide more vertical space for dots.
FUNCTIONALITY ISSUES
#010 — Backend AI: _run_background_inference always returns 1.0 (hardcoded)
- Category: Functionality
- Location: backend/app/services/ai_orchestrator.py:269-271
- Description: The _run_background_inference method unconditionally returns 1.0 without loading or running the background validation model. The background model IS properly loaded and available at final_background_path, but the inference function never uses it. This means the background score is always perfect, making the BACKGROUND_WEIGHT (20%) weight useless and potentially allowing outdoor/non-classroom attendance submissions to pass.
- Root Cause: The function was stubbed out and never implemented. The background model is downloaded and cached but the actual inference pipeline was never written.
- Fix: Implement actual background inference using the loaded background_model:
def _run_background_inference(self, img: np.ndarray) -> float:
    if img is None:
        return 0.0
    img_batch = self._preprocess_background(img)
    with background_lock:
        prediction = background_model.predict(img_batch, verbose=0)[0]
    return float(prediction[0])
#011 — Mobile: attendance submit() doesn't mark session as submitted after completion
- Category: Functionality
- Location: mobile/lib/features/attendance/providers/attendance_provider.dart:67-95
- Description: After a successful attendance submission, the AttendanceNotifier sets step to VerificationStep.done but does NOT call sessionProvider.notifier.markSessionSubmitted(sessionId). The home screen therefore does NOT update the markedSessionIds set, so the "Mark Attendance" button remains visible even after the student has already submitted for that session. Only a refresh would update it.
- Root Cause: The AttendanceNotifier doesn't have access to SessionNotifier and doesn't call markSessionSubmitted.
- Fix: Pass sessionId through the submission flow and call markSessionSubmitted after successful submit. Either through ref in the notifier or by having the VerificationScreen listen for completion and call it externally.
#012 — Backend security: hardcoded JWT secret in config
- Category: Functionality
- Location: backend/app/core/config.py:21
- Description: The JWT_SECRET is hardcoded as "supersecretkeychangeinproduction". This is a critical security issue — anyone who reads the source code can forge JWT tokens, impersonate any user, and gain full access to the system. The .env file overrides this but config.py provides a fallback that is insecure.
- Root Cause: The default value in Settings class is a placeholder that was never changed.
- Fix: Remove the default value or set it to an environment variable with no fallback:
JWT_SECRET: str = Field(..., description="JWT signing secret (must be set via env)")
#013 — Backend teacher: resolve_dispute allows changing status to non-standard value
- Category: Functionality
- Location: backend/app/api/teacher.py:491-553
- Description: The PUT /disputes/{attendance_id}/resolve endpoint accepts status as a free string parameter without validation. It should only accept "RESOLVED" or "REJECTED" (matching the DisputeStatus enum). Additionally, the resolvedAt field is always set even when the dispute is rejected, which is semantically incorrect.
- Root Cause: No Pydantic validation on the status field for this endpoint.
- Fix: Use a Pydantic model with status: Literal["RESOLVED", "REJECTED"] instead of a raw string parameter.
#014 — Mobile WebSocket passes token as query parameter (security)
- Category: Functionality
- Location: mobile/lib/data/api/websocket_service.dart:78
- Description: The WebSocket connection appends the JWT token as a query parameter (?token=$token). This exposes the token in server logs, proxy logs, and browser history. JWT tokens in URLs are a well-known security anti-pattern.
- Root Cause: Lack of a proper WebSocket auth handshake mechanism.
- Fix: Send the token as the first WebSocket message after connection (protocol-level auth), or use a short-lived WebSocket-specific token. The backend must also be updated accordingly.
#015 — Backend student.py: _save_uploaded_image uses upload_file.filename without null check
- Category: Functionality
- Location: backend/app/api/student.py:41
- Description: os.path.splitext(upload_file.filename or "")[1] — while the or "" handles None, the file could be saved without an extension, causing downstream issues. More critically, the function returns a local path, but the backend later serves static files via /static mount. The saved path is stored as a local filesystem path, not a URL path, causing static file serving to potentially fail.
- Root Cause: Missing conversion of local paths to URL paths for static serving.
- Fix: Return a server-relative URL path like /static/attendance/{filename} instead of an absolute filesystem path, and store URL paths in the database.
#016 — Mobile: _computeImageQuality does not affect submission — UI-only decoration
- Category: Functionality
- Location: mobile/lib/features/attendance/screens/verification_screen.dart:27-73, 172-180
- Description: The _computeImageQuality function calculates brightness and blur metrics, displays them in the preview step as "Quality Check", but these values are NEVER sent to the backend or used to prevent low-quality submissions. A student could submit a completely blurry or dark photo and the quality bars would just show "Suboptimal" — but submission proceeds anyway.
- Root Cause: Quality check is display-only with no enforcement.
- Fix: Block the "Submit" button when brightness is below 0.15 or sharpness is below 0.1, showing a message "Photo too dark/blurry — please retake".
#017 — Backend: teacher.py update_data dictionary type error
- Category: Functionality
- Location: backend/app/api/teacher.py:525-543
- Description: In the resolve_dispute function, update_data is declared as dict but the type hint doesn't match the actual usage. The update_data dictionary is typed implicitly as dict but contains mixed types. More critically, if status is not "RESOLVED", new_attendance_status would be set but status (the dispute status) would be a non-standard value. Also, line 537 tries to add new_attendance_status to update_data["status"] which would overwrite the dispute status instead of setting the attendance status field.
- Root Cause: Logic error: the attendance status field is being overwritten instead of setting a separate field. The correct attendance field in the Prisma schema is status but this is already being used for Present/Flagged. The dispute status is stored in disputeStatus (Prisma field).
- Fix: The update should be:
update_data = {"disputeStatus": status, "remarks": remarks}
if status == "RESOLVED":
    update_data["resolvedAt"] = datetime.now(timezone.utc)
if status == "RESOLVED" and new_attendance_status:
    update_data["status"] = new_attendance_status
#018 — Mobile: onFaceRegistered() updates auth state but FaceRegistrationScreen still visible
- Category: Functionality
- Location: mobile/lib/features/registration/screens/face_registration_screen.dart:126-130
- Description: After successful face registration, the code calls ref.read(authProvider.notifier).onFaceRegistered() which sets status to authenticated. The router redirect should then trigger to /home. However, there's a 1.5-second delay before calling Navigator.pop(). If the router redirect fires before the pop, the user sees a brief flash of the home screen overlaid on the dialog before the dialog is dismissed.
- Root Cause: Race condition between Navigator.pop() and GoRouter redirect.
- Fix: Remove the explicit Navigator.pop() and let GoRouter's redirect logic handle the navigation after the auth state changes. Or replace with a listener-based approach.
#019 — Frontend: teacher/page.tsx root redirects but not properly handling role
- Category: Functionality
- Location: frontend/src/app/(dashboard)/teacher/page.tsx (and similarly admin/dashboard/page.tsx)
- Description: The teacher route group's root page likely just redirects. If it redirects via router.push('/teacher/dashboard') but the user already has a redirect from the dashboard layout, this can cause a double-redirect. Additionally, the dashboard layout redirects TEACHER users away from /admin routes, but a teacher could still access admin pages if they manually navigate before the layout effect fires.
- Root Cause: Client-side redirects in both the layout effect and the page content can conflict.
- Fix: Consolidate all route guarding in the dashboard layout effect only; remove redundant redirects from individual pages.
Issues Summary
Issue ID	Category
#001	Screen
#002	Screen
#003	Screen
#004	Screen
#005	UI
#006	UI
#007	UI
#008	UI
#009	UI
#010	Functionality
#011	Functionality
#012	Functionality
#013	Functionality
#014	Functionality
#015	Functionality
#016	Functionality
#017	Functionality
#018	Functionality
#019	Functionality
Critical Issues: 2 (#010 - background AI always perfect, #012 - hardcoded JWT secret)
High Issues: 4 (#001, #011, #014, #017)
Medium Issues: 6 (#002, #007, #008, #013, #015, #016)
Low Issues: 7 (#003, #004, #005, #006, #009, #018, #019)
All 19 issues are fixable with the code changes described above. No external API keys or assets are required (the AI models auto-download from Hugging Face).