I've now read every file that needs modification. Here is the complete execution plan with exact file paths and changes, ready to execute once the mode permits.
EXECUTION PLAN — All 23 Fixes
🔴 CRITICAL FIXES (4)
FIX 1: Teacher Registration Field Mapping Bug
- File: backend/app/services/auth_service.py:55
- Change: data.department → data.department_id, data.designation → data.designation_id
- File: backend/app/repositories/teacher_repo.py:12-13
- Change: "department": department, "designation": designation → "departmentId": department, "designationId": designation
FIX 2: CORS Configuration
- File: backend/main.py:49-55
- Change: Either add settings.FRONTEND_URL from config, or set allow_origins=["*"] with allow_credentials=False. Need to add FRONTEND_URL: str = "http://localhost:3000" to config.py.
FIX 3: Audit Logging
- File: backend/app/services/admin_service.py
- Add: _log_action(event_type, severity, actor, target, description, ip=None) static method
- Wire into: create_student, create_teacher, create_class, update_student, update_teacher, update_class, reset_user_password, assign_teacher, enroll_students, delete_department, delete_subject, delete_classroom, delete_designation
FIX 4: Mobile GPS Geofence Validation
- File: mobile/lib/features/attendance/screens/verification_screen.dart
- Add: After GPS acquisition, check if class has geofence data, call isWithinGeofence() before showing camera step
- File: backend/app/schemas/student.py — Add geofence field to StudentClassResponse
- File: backend/app/services/student_service.py — Include geofence in get_student_classes response
🟠 HIGH FIXES (7)
FIX 5: Frontend Empty Catch Blocks
- File: frontend/src/app/(dashboard)/teacher/dashboard/page.tsx:36 — Add toast.error(getApiErrorMessage(err, "Failed to load dashboard"))
- File: frontend/src/app/(dashboard)/teacher/classes/[id]/page.tsx:79-81 — Add toast.error("Failed to load class details")
- File: frontend/src/app/(dashboard)/teacher/history/page.tsx:50-51 — Add toast.error("Failed to load history")
- File: frontend/src/app/(dashboard)/teacher/sessions/[id]/roster/page.tsx:32-34 — Add toast.error("Failed to load roster")
- File: frontend/src/app/(dashboard)/admin/departments/[id]/edit/page.tsx:33 — Add toast.error
- File: frontend/src/app/(dashboard)/admin/classes/[id]/assign-teacher/page.tsx:26 — Add toast.error
FIX 6: Single-Item GET Endpoints + Frontend Update
- Add to backend:
- GET /admin/users/students/{id} in admin.py
- GET /admin/users/teachers/{id} in admin.py
- GET /admin/classes/{id} in admin.py
- GET /teacher/attendance/{id} in teacher.py
- Update frontend pages to use direct endpoints instead of list-then-filter:
- admin/users/students/[id]/page.tsx
- admin/users/teachers/[id]/page.tsx
- admin/classes/[id]/page.tsx
- teacher/review/[id]/page.tsx
- admin/classes/[id]/edit/page.tsx
FIX 7: Mobile Firebase Error Handling
- File: mobile/lib/main.dart:103,163,169,184 — Replace empty catch (_) {} with logger.error(...) or debugPrint and graceful fallback
FIX 8: Teacher Profile in /auth/me
- File: backend/app/api/auth.py:66-70 — Add firstName, lastName, employeeId to teacher_profile dict
FIX 9: Classroom Edit Bug
- File: frontend/src/app/(dashboard)/admin/classes/[id]/edit/page.tsx — After setCls(found) block, find the matching classroom by name and set classroomId
FIX 10: Mobile Student Stats
- File: mobile/lib/features/analytics/screens/analytics_screen.dart — Wire getMyStats() API call into analytics provider to populate StudentStats model
FIX 11: Replace confirm() with GlassConfirmDialog
- File: frontend/src/app/(dashboard)/teacher/sessions/[id]/roster/page.tsx:80 — Replace if (!confirm(...)) with GlassConfirmDialog component
🟡 MEDIUM FIXES (8)
FIX 12-20: Remaining items as documented in the plan: notification prefs API, leave provider dead code removal, flagged detail loading state, review detail fetch optimization, WebSocket heartbeat, datetime.utcnow() fixes, attendance percentage edge case, dead code removal, notification screen loading state
🟢 LOW FIXES (4)
FIX 21-23: Health check, STUDENT middleware role handling, rate limiting
The plan covers 23 issues across ~35 files in all three layers. I am ready to execute as soon as write mode is available — please confirm you'd like to proceed, or if the environment constraint can be lifted.