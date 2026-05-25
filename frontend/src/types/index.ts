
export interface LoginRequest {
  email: string;
  password: string;
}

export interface TokenResponse {
  access_token: string;
  token_type: string;
  role: "STUDENT" | "TEACHER" | "ADMIN";
}

export interface UserProfile {
  id: string;
  email: string;
  role: "STUDENT" | "TEACHER" | "ADMIN";
  is_active: boolean;
  student_profile: { id: string; enrollment_number: string } | null;
  teacher_profile: {
    id: string;
    employee_id: string;
    first_name: string;
    last_name: string;
    department: string;
    designation: string;
  } | null;
}

export interface StudentCreate {
  email: string;
  password: string;
  enrollment_number: string;
  first_name: string;
  last_name: string;
  phone?: string;
  gender?: string;
  date_of_birth?: string;
  semester?: number;
  batch?: string;
  department_id?: string;
}

export interface StudentResponse {
  id: string;
  user_id: string;
  enrollment_number: string;
  email: string;
  first_name?: string | null;
  last_name?: string | null;
  phone?: string | null;
  gender?: string | null;
  date_of_birth?: string | null;
  department_id?: string | null;
  department_name?: string | null;
  semester?: number | null;
  batch?: string | null;
  device_reset_requested?: boolean;
}

export interface TeacherCreate {
  email: string;
  password: string;
  employee_id: string;
  first_name: string;
  last_name: string;
  department_id: string;
  designation_id: string;
  phone?: string;
  qualification?: string;
  specialization?: string;
  experience_years?: number;
  joining_date?: string;
}

export interface TeacherResponse {
  id: string;
  user_id: string;
  email: string;
  employee_id: string;
  first_name: string;
  last_name: string;
  department_id: string;
  designation_id: string;
  
  department: string;
  
  designation: string;
  phone?: string | null;
  qualification?: string | null;
  specialization?: string | null;
  experience_years?: number | null;
  joining_date?: string | null;
}

export interface ClassCreate {
  name: string;
  subject_id: string;
  teacher_id: string;
  classroom_id?: string;
  semester?: number;
  batch?: string;
  max_students?: number;
}

export interface ClassUpdate {
  name?: string;
  subject_id?: string;
  teacher_id?: string;
  classroom_id?: string;
  semester?: number;
  batch?: string;
  max_students?: number;
}

export interface ClassResponse {
  id: string;
  name: string;
  
  subject_name: string;
  
  subject_code: string;
  teacherId: string;
  classroom_name?: string | null;
  semester?: number | null;
  batch?: string | null;
  max_students?: number | null;
  enrolled_count: number;
}

export interface AssignTeacherRequest {
  teacher_id: string;
}

export interface EnrollRequest {
  student_ids: string[];
}

export interface DepartmentCreate {
  name: string;
  code: string;
  head?: string;
  description?: string;
}

export interface DepartmentUpdate {
  name?: string;
  code?: string;
  head?: string;
  description?: string;
}

export interface DepartmentResponse {
  id: string;
  name: string;
  code: string;
  head: string | null;
  description: string | null;
  classCount: number;
}

export interface SubjectCreate {
  name: string;
  code: string;
  description?: string;
}

export interface SubjectUpdate {
  name?: string;
  code?: string;
  description?: string;
}

export interface SubjectResponse {
  id: string;
  name: string;
  code: string;
  description: string | null;
}

export interface ClassroomCreate {
  name: string;
  building?: string;
  capacity?: number;
}

export interface ClassroomUpdate {
  name?: string;
  building?: string;
  capacity?: number;
}

export interface ClassroomResponse {
  id: string;
  name: string;
  building: string | null;
  capacity: number | null;
}

export interface DesignationCreate {
  name: string;
  code: string;
  description?: string;
}

export interface DesignationUpdate {
  name?: string;
  code?: string;
  description?: string;
}

export interface DesignationResponse {
  id: string;
  name: string;
  code: string;
  description: string | null;
}

export interface AuditLogResponse {
  id: string;
  timestamp: string;
  eventType: string;
  severity: string;
  actor: string;
  target: string;
  description: string;
  ip: string | null;
  meta: Record<string, unknown> | null;
}

export interface AdminStatsResponse {
  studentCount: number;
  teacherCount: number;
  classCount: number;
}

export interface GeofenceUpsert {
  latitude: number;
  longitude: number;
  radius_meters: number;
}

export interface GeofenceResponse {
  id: string;
  academicClassId: string;
  latitude: number;
  longitude: number;
  radiusMeters: number;
  createdAt: string;
  updatedAt: string;
}

export interface AcademicClassWithGeofence {
  id: string;
  name: string;
  
  subject: string;
  teacherId: string;
  geofence: GeofenceResponse | null;
}

export interface SessionStart {
  academic_class_id: string;
  duration_minutes: number;
}

export interface SessionResponse {
  id: string;
  academicClassId: string;
  startTime: string;
  endTime: string;
  isActive: boolean;
}

export interface SessionWithClassResponse {
  id: string;
  academicClassId: string;
  class_name: string;
  
  subject: string;
  startTime: string;
  endTime: string;
  isActive: boolean;
}

export interface StudentRosterItem {
  student_id: string;
  enrollment_number: string;
  full_name: string;
  email: string;
  status: "Present" | "Flagged" | "Absent" | "Approved";
  final_score: number;
  marked_at: string | null;
}

export interface SessionAttendanceResponse {
  session_id: string;
  class_name: string;
  roster: StudentRosterItem[];
}

export interface AbsentStudentItem {
  student_id: string;
  enrollment_number: string;
  full_name: string;
  email: string;
}

export interface BulkMarkRecord {
  student_id: string;
  status: "Present" | "Absent";
}

export interface BulkMarkRequest {
  records: BulkMarkRecord[];
}

export interface AttendanceExportRow {
  enrollment_number: string;
  first_name: string;
  last_name: string;
  email: string;
  session_date: string;
  class_name: string;
  subject: string;
  status: string;
  final_ai_score: number;
  remarks?: string;
}

export interface FlaggedAttendanceResponse {
  id: string;
  enrollment_number: string;
  student_name: string;
  class_name: string;
  subject: string;
  face_score: number;
  liveness_score: number;
  background_score: number;
  final_ai_score: number;
  gps_latitude: number;
  gps_longitude: number;
  created_at: string;
}

export interface AttendanceReview {
  status: "Approved" | "Rejected";
  remarks: string;
}

export interface SessionTrendItem {
  session_id: string;
  session_name: string;
  attendance_percentage: number;
}

export interface ClassStatsResponse {
  class_id: string;
  total_sessions: number;
  total_students: number;
  overall_attendance_percentage: number;
  history?: SessionTrendItem[];
}

export interface AnomalyResult {
  student_id: string;
  anomaly_score: number;
  total_absences: number;
  [key: string]: unknown;
}
