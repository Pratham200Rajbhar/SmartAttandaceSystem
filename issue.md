Complete Audit & Fix Plan — Smart Attendance System
Phase 1: Discovery Summary
Files scanned: 68 Dart (mobile) + 32 Python (backend) + 40+ TSX/TS (frontend) = 140+ files  
Total issues identified: 23 distinct features/connections that are broken, missing, or partially implemented
Phase 2: Issues Ranked by Severity
🔴 CRITICAL (Runtime failures / data corruption)
#	Feature	Issue
1	Teacher Registration	AuthService.register_teacher() passes data.department/data.designation but schema fields are department_id/designation_id. TeacherRepository.create() maps to wrong Prisma fields (department/designation vs departmentId/designationId). Admin "Add Teacher" form always fails or corrupts data.
2	CORS Configuration	allow_origins=["*"] with allow_credentials=True — browsers reject credentialed requests per CORS spec. Frontend auth cookie breaks in production.
3	Audit Logging — Never Written	AuditLog table exists, GET /admin/audit returns empty results. No code ever writes audit logs for admin operations (create user, reset password, etc.).
4	GPS Geofence Validation Unused	Mobile LocationService.isWithinGeofence() is defined but never called. Students can mark attendance from anywhere. Backend validates geofence server-side, but mobile never shows user they're out of bounds before submit.
Plan·DeepSeek V4 Flash FreeOpenCode Zen
esc interrupt
🟠 HIGH (Broken or missing connections)
#	Feature	Issue
5	Frontend Empty Catch Blocks	6 files have catch { } — no error toast, no fallback: teacher/dashboard, teacher/classes/[id], teacher/history, teacher/sessions/[id]/roster, admin/departments/[id]/edit, admin/classes/[id]/assign-teacher. Silent failures.
6	Frontend List-then-Filter Pattern	Student/Teacher/Class detail pages fetch ALL records then .find() client-side. No GET /admin/users/students/{id}, GET /admin/users/teachers/{id}, GET /admin/classes/{id} endpoints exist.
7	Mobile Firebase Silent Crashes	main.dart has empty catch (_) {} for Firebase.initializeApp(), registerFcmToken(), and onTokenRefresh. FCM failures are completely invisible.
8	Teacher Profile Field Mismatch	Frontend UserProfile.teacher_profile expects employee_id, first_name, last_name. Backend /auth/me returns only id, department, designation.
9	Classroom Edit Bug	admin/classes/[id]/edit/page.tsx never sets classroomId state from existing data, so classroom dropdown always resets.
10	Mobile Student Stats Not Consumed	GET /student/stats endpoint and StudentApi.getMyStats() exist, but AnalyticsScreen never calls it. rank, highest_streak from server ignored.
11	Native confirm() Dialog	teacher/sessions/[id]/roster/page.tsx:80 uses confirm() instead of GlassConfirmDialog. Blocks UI, unstyled.
🟡 MEDIUM (Partial implementations / missing edges)
#	Feature	Issue
12	Mobile Notification Preferences — Local Only	Saved in SharedPreferences only. No API endpoint or sync. Lost on device change.
13	Mobile Leave History — Dead Code	leave_provider.dart (LeaveNotifier) is defined but never used. leave_history_screen.dart uses its own inline FutureProvider.
14	Flagged Detail — No Loading on Note Submit	FlaggedDetailScreen._submitNote() has _isSubmitting state but GlassButton never passes isLoading: _isSubmitting. No spinner.
15	Review Detail — Fetch Pattern	teacher/review/[id]/page.tsx fetches ALL flagged records and .find()s the one matching id. Should use single-item endpoint or at least filter server-side.
16	WebSocket No Server-Side Heartbeat	Backend ws.py has no ping/pong mechanism. Stale connections accumulate in memory.
17	Mobile datetime.utcnow() Used	3 places in backend use timezone-naive datetime.utcnow() instead of datetime.now(timezone.utc). PostgreSQL comparison issues.
18	Attendance Percentage — Edge Case	student_service.py:47 — overall_percentage defaults to 100.0 when total_sessions == 0. Misleading. Should be 0.0 or None.
19	Dead Repository Methods	7 methods defined but never called: class_repo.create(), class_repo.update_teacher(), class_repo.get_by_teacher_id(), session_repo.get_by_class_id(), student_repo.get_by_enrollment(), student_repo.get_all_active(), attendance_repo.get_by_session_id(). Some have bugs (wrong field names).
20	Notification Screen — No Loading State	notifications_screen.dart has no shimmer/loading indicator during initial load.
🟢 LOW (Minor / Nice-to-have)
#	Feature	Issue
21	/health Endpoint — Always Returns Healthy	Doesn't check DB/Redis connectivity.
22	No STUDENT Role Handling in Frontend	Middleware only handles ADMIN/TEACHER. Web frontend has zero student pages. Not a bug per se (students use mobile), but middleware should block student access to admin/teacher routes.
23	No Rate Limiting on Auth	Login/register endpoints lack rate limiting. Vulnerable to brute force.
Phase 3: Implementation Plan
Here is my recommended execution order and approach for each fix:
Sprint 1: Critical Runtime Fixes
1. Fix Teacher Registration (auth_service.py:55, teacher_repo.py:12-13)
- Edit auth_service.py: change data.department → data.department_id, data.designation → data.designation_id
- Edit teacher_repo.py: change department → departmentId, designation → designationId
2. Fix CORS (main.py:49-55)
- Use allow_origins=[settings.FRONTEND_URL] or split with env var
- If wildcard needed, set allow_credentials=False
3. Wire Audit Logging (admin_service.py + admin.py)
- Create an async def _log_action(...) utility
- Call it from every admin mutation endpoint (create student, teacher, class, department, reset-password, etc.)
4. Wire GPS Geofence Validation in Mobile (verification_screen.dart + location_service.dart)
- The mobile app needs to know the class geofence coordinates. Currently GET /student/classes returns active_session_id but not geofence data.
- Add geofence data to GET /student/classes response in backend
- In mobile verification screen, after GPS acquisition, call isWithinGeofence() before proceeding
- Show error state if outside geofence
Sprint 2: High-Priority Connection Fixes
 5. Fix 6 empty catch blocks in frontend — Add toast.error(getApiErrorMessage(err)) to each
 6. Add single-item GET endpoints to backend + update frontend
- GET /admin/users/students/{id}
- GET /admin/users/teachers/{id}  
- GET /admin/classes/{id}
- GET /teacher/attendance/{id} (for review detail page)
- Update frontend pages to use these instead of list-then-filter
 7. Fix Firebase error handling in mobile — Replace empty catches with logger.error()
 8. Fix teacher profile in /auth/me — Include firstName, lastName, employeeId fields
 9. Fix classroom edit bug — Add classroomId to loaded state in edit page
10. Wire student stats in mobile — Add API call to analytics provider
11. Replace confirm() with GlassConfirmDialog in roster page
Sprint 3: Medium-Priority Fixes
12-20. Implement remaining medium-priority items