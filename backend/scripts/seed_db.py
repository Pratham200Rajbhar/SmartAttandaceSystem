"""
Smart Attendance System — Database Seed Script
================================================

Generates realistic Indian college data:
  • 1  Admin account
  • 50 Teachers with realistic profiles
  • 300+ Students with enrollment numbers, departments, batches
  • 9  Academic Departments
  • 7  Designations
  • 30+ Subjects across departments & semesters
  • 20 Classrooms across multiple buildings
  • 80+ Academic Classes with geofences
  • ~1 month of Sessions (+Attendance records)
  • Enrollments, Leaves, Device Change Requests, Audit Logs

Idempotent: safe to re-run (clears all existing data first).

Usage
-----
    cd backend
    python prisma/seed.py

    # or directly:
    python -c "from scripts.seed_db import seed_all; import asyncio; asyncio.run(seed_all())"

Pre-requisites
--------------
    pip install -r requirements.txt
    prisma generate
    Ensure DATABASE_URL in .env is pointing to the target PostgreSQL instance.
    The `vector` extension must be enabled on the database:
        CREATE EXTENSION IF NOT EXISTS vector;
"""

from __future__ import annotations

import asyncio
import random
import uuid
from datetime import date, datetime, timedelta, timezone
from typing import Any, TypeVar

import bcrypt
from prisma import Json
from app.db.client import db

T = TypeVar("T")

# ==============================================================================
# PASSWORD HASHING (mirrors app/core/security.py to avoid app import)
# ==============================================================================

def _hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12)).decode()

# ==============================================================================
# REALISTIC INDIAN DATA POOLS
# ==============================================================================

MALE_FIRST_NAMES = [
    "Aarav", "Vihaan", "Vivaan", "Advik", "Kabir", "Arjun", "Rohan", "Ishaan",
    "Ayaan", "Dhruv", "Krish", "Reyansh", "Shiv", "Yash", "Dev", "Pranav",
    "Manav", "Karan", "Vikram", "Rahul", "Amit", "Suresh", "Ravi", "Deepak",
    "Sanjay", "Vijay", "Rajesh", "Nikhil", "Abhishek", "Harsh", "Varun",
    "Aditya", "Saurabh", "Akash", "Sachin", "Pradeep", "Ganesh", "Mahesh",
    "Naresh", "Rakesh", "Dinesh", "Sagar", "Lokesh", "Ajay", "Anil", "Sunil",
    "Manoj", "Ashish", "Tushar", "Kunal", "Chetan", "Rishabh", "Siddharth",
    "Ankur", "Pankaj", "Gaurav", "Vishal", "Shubham", "Mohit", "Rohit",
    "Sumit", "Manish", "Alok", "Chandan", "Jatin", "Hitesh", "Vinod",
    "Mukesh", "Rajat", "Vivek", "Lalit", "Akshay", "Sandeep", "Nitin",
    "Amitabh", "Hemant", "Tarun", "Umesh", "Nilesh", "Kamlesh", "Gopal",
    "Harish", "Kishore", "Mohan", "Navneet", "Om", "Prakash", "Ramesh",
    "Shekhar", "Tejas", "Uday", "Vimal", "Wasim", "Yogesh", "Zubin",
    "Amol", "Bhavesh", "Chirag", "Darshan", "Eknath", "Faisal", "Girish",
    "Himanshu", "Iqbal", "Jagdish", "Kaushik", "Laxman", "Mithun", "Neeraj",
    "Omprakash", "Parag", "Quasim", "Ranjit", "Sameer", "Tanmay", "Utkarsh",
    "Vaibhav", "Waman", "Yashwant", "Anurag", "Bharat", "Chandrashekhar",
    "Dhananjay", "Eshwar", "Fateh", "Gautam", "Harshad", "Ishwar", "Jitendra",
    "Kartik", "Lalit", "Madhav", "Nandkishore", "Ojas", "Parth", "Raghav",
]

FEMALE_FIRST_NAMES = [
    "Ananya", "Priya", "Aditi", "Aisha", "Diya", "Kavya", "Anjali", "Shreya",
    "Neha", "Pooja", "Riya", "Meera", "Ishita", "Nandini", "Tanvi", "Sakshi",
    "Vaishali", "Swati", "Divya", "Pallavi", "Shweta", "Aparna", "Deepa",
    "Kavita", "Sunita", "Rekha", "Asha", "Usha", "Geeta", "Radha", "Laxmi",
    "Jyoti", "Madhu", "Nidhi", "Poonam", "Rashmi", "Shilpa", "Ritu", "Anju",
    "Suman", "Archana", "Bhavna", "Chitra", "Ekta", "Garima", "Hema",
    "Kamala", "Lata", "Manju", "Namrata", "Pratibha", "Rajni", "Sarita",
    "Tripti", "Uma", "Vandana", "Yamini", "Zara", "Aparajita", "Bindiya",
    "Charulata", "Damini", "Gargi", "Harini", "Jaya", "Kirti", "Lavanya",
    "Mala", "Navya", "Ojal", "Parvati", "Rukmini", "Savitri", "Tanushree",
    "Ankita", "Bhavika", "Chaitali", "Devika", "Gauri", "Hansika", "Ira",
    "Jhanvi", "Kiara", "Lipika", "Mitali", "Nayana", "Parnika", "Rupali",
    "Samiksha", "Tulika", "Varsha", "Aarushi", "Barkha", "Charvi", "Disha",
    "Esha", "Falguni", "Gomati", "Harshita", "Ipsita", "Jyotsna", "Kritika",
    "Lopamudra", "Moushumi", "Nirmala", "Oindrila", "Pragya", "Roshni",
    "Shikha", "Trisha", "Upasana", "Vidya", "Yoshita", "Zeenat",
]

LAST_NAMES = [
    "Sharma", "Verma", "Patel", "Singh", "Gupta", "Reddy", "Nair", "Joshi",
    "Kumar", "Das", "Sen", "Bose", "Mukherjee", "Banerjee", "Chatterjee",
    "Ganguly", "Iyer", "Menon", "Pillai", "Rao", "Naidu", "Prasad", "Mishra",
    "Tiwari", "Dubey", "Pandey", "Chauhan", "Yadav", "Rajput", "Thakur",
    "Solanki", "Rathore", "Shekhawat", "Mehta", "Shah", "Desai", "Trivedi",
    "Acharya", "Bhat", "Hegde", "Shetty", "Pai", "Nayak", "Swain", "Behera",
    "Mahapatra", "Kaur", "Gill", "Dhillon", "Bedi", "Kapoor", "Khanna",
    "Malhotra", "Chopra", "Bhatia", "Sethi", "Aggarwal", "Jain", "Saxena",
    "Srivastava", "Sinha", "Mathur", "Bajaj", "Rana", "Biswas", "Ghosh",
    "Dutta", "Majumdar", "Saha", "Acharya", "Krishnan", "Bharadwaj", "Mani",
    "Subramaniam", "Venkatesh", "Kulkarni", "Deshpande", "Gokhale", "Tendulkar",
    "Rajan", "Varma", "Philip", "George", "Thomas", "Jacob", "Mathew", "Cherian",
]

# ==============================================================================
# INSTITUTIONAL DATA
# ==============================================================================

DEPARTMENTS = [
    ("Computer Science & Engineering", "CSE", "Dr. Rajesh Sharma", "Focus on computing, algorithms, AI, and software engineering"),
    ("Information Technology", "IT", "Dr. Sunita Verma", "Focus on IT infrastructure, networking, and cybersecurity"),
    ("Electronics & Communication Engineering", "ECE", "Dr. Anil Kumar", "Focus on electronics, communications, and signal processing"),
    ("Mechanical Engineering", "ME", "Dr. Vikram Singh", "Focus on mechanics, thermodynamics, and manufacturing"),
    ("Civil Engineering", "CE", "Dr. Priya Patel", "Focus on structures, construction, and environmental engineering"),
    ("Electrical Engineering", "EE", "Dr. Suresh Reddy", "Focus on power systems, machines, and renewable energy"),
    ("Business Administration", "MBA", "Dr. Meera Nair", "Focus on management, finance, and organizational behavior"),
    ("Pharmacy", "PHARM", "Dr. Anjali Joshi", "Focus on pharmaceutical sciences and drug discovery"),
    ("Biotechnology", "BT", "Dr. Ravi Gupta", "Focus on molecular biology, genetics, and bioinformatics"),
]

DESIGNATIONS = [
    ("Professor", "PROF", "Senior-most faculty with extensive research and teaching experience"),
    ("Associate Professor", "APROF", "Mid-career faculty with significant academic contributions"),
    ("Assistant Professor", "ASPROF", "Early-career faculty building their academic portfolio"),
    ("Senior Lecturer", "SLECT", "Experienced lecturer with specialized domain expertise"),
    ("Lecturer", "LECT", "Teaching-focused faculty member"),
    ("Head of Department", "HOD", "Department head overseeing academic and administrative functions"),
    ("Dean", "DEAN", "Dean of the faculty overseeing multiple departments"),
]

# Subject definitions: department_key -> list of (name, code, semester)
SUBJECT_DEFS: dict[str, list[tuple[str, str, int]]] = {
    "CSE": [
        ("Programming in C", "CSE201", 2),
        ("Discrete Mathematics", "CSE202", 2),
        ("Digital Logic Design", "CSE203", 2),
        ("Data Structures", "CSE301", 4),
        ("Database Management Systems", "CSE302", 4),
        ("Computer Organization & Architecture", "CSE303", 4),
        ("Operating Systems", "CSE304", 4),
        ("Computer Networks", "CSE401", 6),
        ("Software Engineering", "CSE402", 6),
        ("Web Technologies", "CSE403", 6),
        ("Design & Analysis of Algorithms", "CSE404", 6),
        ("Machine Learning", "CSE501", 8),
        ("Cloud Computing", "CSE502", 8),
        ("Cyber Security", "CSE503", 8),
    ],
    "IT": [
        ("Fundamentals of IT", "IT201", 2),
        ("Web Development Basics", "IT202", 2),
        ("Database Systems", "IT301", 4),
        ("Data Communication & Networking", "IT302", 4),
        ("Object-Oriented Programming", "IT303", 4),
        ("Network Security", "IT401", 6),
        ("Cloud Infrastructure", "IT402", 6),
        ("Mobile Application Development", "IT403", 6),
        ("Big Data Analytics", "IT501", 8),
        ("Blockchain Technology", "IT502", 8),
    ],
    "ECE": [
        ("Basic Electronics", "ECE201", 2),
        ("Network Analysis & Synthesis", "ECE202", 2),
        ("Analog Electronics", "ECE301", 4),
        ("Digital Electronics", "ECE302", 4),
        ("Signals & Systems", "ECE303", 4),
        ("Analog Communication", "ECE304", 4),
        ("Microprocessors & Microcontrollers", "ECE401", 6),
        ("Digital Signal Processing", "ECE402", 6),
        ("VLSI Design", "ECE403", 6),
        ("Wireless Communication", "ECE501", 8),
        ("Embedded Systems", "ECE502", 8),
        ("Internet of Things", "ECE503", 8),
    ],
    "ME": [
        ("Engineering Mechanics", "ME201", 2),
        ("Thermodynamics", "ME202", 2),
        ("Fluid Mechanics & Hydraulic Machines", "ME301", 4),
        ("Strength of Materials", "ME302", 4),
        ("Manufacturing Processes", "ME303", 4),
        ("Heat & Mass Transfer", "ME401", 6),
        ("Machine Design", "ME402", 6),
        ("CAD / CAM", "ME403", 6),
        ("Robotics & Automation", "ME501", 8),
        ("Automobile Engineering", "ME502", 8),
        ("Power Plant Engineering", "ME503", 8),
    ],
    "CE": [
        ("Building Materials & Construction", "CE201", 2),
        ("Surveying & Levelling", "CE202", 2),
        ("Structural Analysis", "CE301", 4),
        ("Fluid Mechanics", "CE302", 4),
        ("Geotechnical Engineering", "CE303", 4),
        ("Design of Steel Structures", "CE401", 6),
        ("Transportation Engineering", "CE402", 6),
        ("Environmental Engineering", "CE403", 6),
        ("Earthquake Resistant Structures", "CE501", 8),
        ("Construction Project Management", "CE502", 8),
    ],
    "EE": [
        ("Basic Electrical Engineering", "EE201", 2),
        ("Network Theory", "EE202", 2),
        ("Electrical Machines", "EE301", 4),
        ("Power Systems", "EE302", 4),
        ("Control Systems", "EE303", 4),
        ("Power Electronics", "EE401", 6),
        ("Renewable Energy Systems", "EE402", 6),
        ("Switchgear & Protection", "EE403", 6),
        ("Smart Grid Technology", "EE501", 8),
        ("Electric Vehicle Engineering", "EE502", 8),
    ],
    "MBA": [
        ("Principles of Management", "MBA201", 2),
        ("Financial Accounting", "MBA202", 2),
        ("Marketing Management", "MBA301", 4),
        ("Human Resource Management", "MBA302", 4),
        ("Operations Research", "MBA303", 4),
        ("Corporate Finance", "MBA401", 6),
        ("Business Analytics", "MBA402", 6),
        ("Organizational Behavior", "MBA403", 6),
        ("Strategic Management", "MBA501", 8),
        ("Entrepreneurship & Innovation", "MBA502", 8),
    ],
    "PHARM": [
        ("Pharmaceutical Chemistry", "PH201", 2),
        ("Pharmacology I", "PH202", 2),
        ("Pharmaceutics I", "PH301", 4),
        ("Pharmacognosy", "PH302", 4),
        ("Pharmaceutical Biochemistry", "PH303", 4),
        ("Pharmaceutical Analysis", "PH401", 6),
        ("Pharmacology II", "PH402", 6),
        ("Medicinal Chemistry", "PH403", 6),
        ("Drug Regulatory Affairs", "PH501", 8),
        ("Clinical Pharmacy", "PH502", 8),
    ],
    "BT": [
        ("Cell Biology", "BT201", 2),
        ("Biochemistry", "BT202", 2),
        ("Molecular Biology", "BT301", 4),
        ("Genetic Engineering", "BT302", 4),
        ("Bioprocess Engineering", "BT303", 4),
        ("Immunology", "BT401", 6),
        ("Bioinformatics", "BT402", 6),
        ("Environmental Biotechnology", "BT403", 6),
        ("Pharmaceutical Biotechnology", "BT501", 8),
        ("Nanobiotechnology", "BT502", 8),
    ],
}

CLASSROOMS = [
    ("A-101", "A-Block", 60),
    ("A-102", "A-Block", 60),
    ("A-201", "A-Block", 50),
    ("A-202", "A-Block", 50),
    ("B-101", "B-Block", 80),
    ("B-102", "B-Block", 80),
    ("B-201", "B-Block", 40),
    ("B-202", "B-Block", 40),
    ("C-101", "C-Block", 70),
    ("C-102", "C-Block", 70),
    ("C-201", "C-Block", 45),
    ("C-301", "C-Block", 45),
    ("D-101", "D-Block", 90),
    ("D-102", "D-Block", 90),
    ("D-201", "D-Block", 55),
    ("Engineering Lab 1", "Engineering Block", 30),
    ("Engineering Lab 2", "Engineering Block", 30),
    ("Computer Lab 1", "IT Block", 40),
    ("Computer Lab 2", "IT Block", 40),
    ("Seminar Hall", "Admin Block", 120),
]

# Teacher distribution: (dept_code, count, designation_indices)
TEACHER_DEPT_DIST: list[tuple[str, int]] = [
    ("CSE", 8),
    ("IT", 5),
    ("ECE", 7),
    ("ME", 6),
    ("CE", 5),
    ("EE", 5),
    ("MBA", 5),
    ("PHARM", 5),
    ("BT", 4),
]

DESIGNATION_WEIGHTS = [0.10, 0.20, 0.35, 0.10, 0.15, 0.05, 0.05]  # must sum to 1.0

# Student distribution per department per batch
# (dept_code, sem_2_count, sem_4_count, sem_6_count, sem_8_count)
STUDENT_DEPT_DIST: list[tuple[str, int, int, int, int]] = [
    ("CSE", 18, 17, 16, 14),     # 65
    ("IT", 12, 11, 10, 9),       # 42
    ("ECE", 14, 13, 12, 11),     # 50
    ("ME", 12, 11, 10, 9),       # 42
    ("CE", 9, 8, 8, 7),          # 32
    ("EE", 9, 8, 8, 7),          # 32
    ("MBA", 8, 7, 7, 6),         # 28
    ("PHARM", 5, 4, 4, 4),       # 17
    ("BT", 3, 3, 3, 3),          # 12
]

BATCH_MAP: dict[int, str] = {2: "2025-2029", 4: "2024-2028", 6: "2023-2027", 8: "2022-2026"}

# Campus GPS (approximate centre of IIT Bombay campus)
CAMPUS_LAT = 19.1334
CAMPUS_LNG = 72.9133

# Attendance scoring weights (mirroring app config)
FACE_WEIGHT = 0.50
LIVENESS_WEIGHT = 0.30
BACKGROUND_WEIGHT = 0.20
PASS_THRESHOLD = 0.75

# ==============================================================================
# HELPERS
# ==============================================================================

def random_date(start_dt: date, end_dt: date) -> datetime:
    delta = end_dt - start_dt
    offset_days = random.random() * delta.days
    offset_seconds = random.random() * 86400.0
    result = datetime.combine(start_dt, datetime.min.time()) + timedelta(days=offset_days, seconds=offset_seconds)
    return result.replace(tzinfo=timezone.utc)


def _to_datetime(d: date | datetime) -> datetime:
    if isinstance(d, datetime):
        return d
    return datetime.combine(d, datetime.min.time()).replace(tzinfo=timezone.utc)


def _pick(items: list[T]) -> T:
    return random.choice(items)


def _pick_n(items: list[T], n: int) -> list[T]:
    return random.sample(items, min(n, len(items)))


def _weighted_choice(items: list[Any], weights: list[float]) -> Any:
    return random.choices(items, weights=weights, k=1)[0]


def jitter_gps(base_lat: float, base_lng: float, radius_deg: float = 0.002) -> tuple[float, float]:
    lat = base_lat + random.uniform(-radius_deg, radius_deg)
    lng = base_lng + random.uniform(-radius_deg, radius_deg)
    return (round(lat, 6), round(lng, 6))


def compute_final_score(face: float, liveness: float, background: float) -> float:
    return round(face * FACE_WEIGHT + liveness * LIVENESS_WEIGHT + background * BACKGROUND_WEIGHT, 4)


def generate_present_scores() -> dict[str, float]:
    face = round(random.uniform(0.82, 0.99), 4)
    liveness = round(random.uniform(0.80, 0.99), 4)
    background = round(random.uniform(0.78, 0.99), 4)
    final = compute_final_score(face, liveness, background)
    return {"face_score": face, "liveness_score": liveness, "background_score": background, "final_ai_score": final}


def generate_flagged_scores() -> dict[str, float]:
    face = round(random.uniform(0.30, 0.70), 4)
    liveness = round(random.uniform(0.25, 0.68), 4)
    background = round(random.uniform(0.20, 0.65), 4)
    final = compute_final_score(face, liveness, background)
    return {"face_score": face, "liveness_score": liveness, "background_score": background, "final_ai_score": final}


def make_name_pool() -> list[tuple[str, str, str]]:
    """Returns list of (first_name, last_name, gender) tuples."""
    pool: list[tuple[str, str, str]] = []
    for name in MALE_FIRST_NAMES:
        pool.append((name, _pick(LAST_NAMES), "Male"))
    for name in FEMALE_FIRST_NAMES:
        pool.append((name, _pick(LAST_NAMES), "Female"))
    random.shuffle(pool)
    return pool


def make_phone() -> str:
    return f"+91{random.randint(7000000000, 9999999999)}"


def make_dob_for_semester(semester: int) -> date:
    if semester <= 2:
        return date(random.randint(2003, 2006), random.randint(1, 12), random.randint(1, 28))
    elif semester <= 4:
        return date(random.randint(2002, 2005), random.randint(1, 12), random.randint(1, 28))
    elif semester <= 6:
        return date(random.randint(2001, 2004), random.randint(1, 12), random.randint(1, 28))
    else:
        return date(random.randint(2000, 2003), random.randint(1, 12), random.randint(1, 28))

# ==============================================================================
# MAIN SEED FUNCTION
# ==============================================================================

async def seed_all() -> None:
    await db.connect()
    print("=" * 72)
    print("  SMART ATTENDANCE SYSTEM — DATABASE SEED")
    print("=" * 72)

    try:
        # ------------------------------------------------------------------
        # 1. CLEAR ALL EXISTING DATA (reverse FK dependency order)
        # ------------------------------------------------------------------
        print("\n[1/16] Clearing existing data …")
        await db.attendance.delete_many()
        await db.devicechangerequest.delete_many()
        await db.leaverequest.delete_many()
        await db.enrollment.delete_many()
        await db.geofence.delete_many()
        await db.session.delete_many()
        await db.academicclass.delete_many()
        await db.teacher.delete_many()
        await db.student.delete_many()
        await db.user.delete_many()
        await db.subject.delete_many()
        await db.classroom.delete_many()
        await db.designation.delete_many()
        await db.department.delete_many()
        await db.auditlog.delete_many()
        await db.systemconfiguration.delete_many()
        print("  ✓ All database tables cleared")

        # Clear Redis leaderboard cache
        try:
            from app.db.redis import connect_redis, disconnect_redis
            redis = await connect_redis()
            if redis:
                await redis.delete("leaderboard:points")
                print("  ✓ Redis leaderboard cache cleared")
                await disconnect_redis()
        except Exception as re:
            print(f"  [WARNING] Failed to clear Redis cache: {re}")

        # ------------------------------------------------------------------
        # 2. SYSTEM CONFIGURATION
        # ------------------------------------------------------------------
        print("\n[2/16] Seeding System Configuration …")
        sys_cfg = await db.systemconfiguration.create(data={
            "isFaceRecognitionEnabled": True,
            "isGpsVerificationEnabled": True,
            "isAiBackgroundValidationEnabled": True,
        })
        print(f"  ✓ System configuration (id={sys_cfg.id[:8]}…)")

        # ------------------------------------------------------------------
        # 3. DEPARTMENTS
        # ------------------------------------------------------------------
        print("\n[3/16] Seeding Departments …")
        dept_map: dict[str, str] = {}  # code -> id
        for name, code, head, desc in DEPARTMENTS:
            dept = await db.department.create(data={
                "name": name,
                "code": code,
                "head": head,
                "description": desc,
            })
            dept_map[code] = dept.id
        print(f"  ✓ {len(DEPARTMENTS)} departments created")

        # ------------------------------------------------------------------
        # 4. DESIGNATIONS
        # ------------------------------------------------------------------
        print("\n[4/16] Seeding Designations …")
        desig_map: dict[str, str] = {}  # code -> id
        for name, code, desc in DESIGNATIONS:
            desig = await db.designation.create(data={
                "name": name,
                "code": code,
                "description": desc,
            })
            desig_map[code] = desig.id
        print(f"  ✓ {len(DESIGNATIONS)} designations created")

        # ------------------------------------------------------------------
        # 5. SUBJECTS
        # ------------------------------------------------------------------
        print("\n[5/16] Seeding Subjects …")
        subject_map: dict[str, str] = {}  # code -> id
        for dept_code, subjects in SUBJECT_DEFS.items():
            for name, code, sem in subjects:
                subj = await db.subject.create(data={
                    "name": name,
                    "code": code,
                    "description": f"{name} — {dept_code} Semester {sem}",
                })
                subject_map[code] = subj.id
        print(f"  ✓ {len(subject_map)} subjects created")

        # ------------------------------------------------------------------
        # 6. CLASSROOMS
        # ------------------------------------------------------------------
        print("\n[6/16] Seeding Classrooms …")
        classroom_map: dict[str, str] = {}  # name -> id
        for name, building, capacity in CLASSROOMS:
            cr = await db.classroom.create(data={
                "name": name,
                "building": building,
                "capacity": capacity,
            })
            classroom_map[name] = cr.id
        print(f"  ✓ {len(CLASSROOMS)} classrooms created")

        # ------------------------------------------------------------------
        # 7. USERS & PROFILES
        # ------------------------------------------------------------------
        print("\n[7/16] Creating user accounts …")

        admin_user = await db.user.create(data={
            "email": "admin@smartattendance.edu.in",
            "hashedPassword": _hash_password("Admin@123"),
            "role": "ADMIN",
        })
        print("  ✓ Admin user created (admin@smartattendance.edu.in / Admin@123)")

        # Generate name pools
        random.seed(42)
        name_pool = make_name_pool()
        random.shuffle(name_pool)

        # ----- Teachers -----
        print("\n[8/16] Seeding Teachers …")
        teacher_name_pool = name_pool[:60]  # extra names for teachers
        teacher_ids: list[str] = []
        teacher_user_ids: list[str] = []
        teacher_dept_map: dict[str, list[dict]] = {code: [] for code, _ in TEACHER_DEPT_DIST}
        teacher_counter: dict[str, int] = {}

        emp_serial = 1
        for dept_code, count in TEACHER_DEPT_DIST:
            teacher_counter[dept_code] = 0
            for i in range(count):
                first, last, gender = teacher_name_pool.pop(0)
                emp_id = f"EMP{emp_serial:03d}"
                emp_serial += 1
                email = f"{emp_id.lower()}@smartattendance.edu.in"

                user = await db.user.create(data={
                    "email": email,
                    "hashedPassword": _hash_password("Teacher@123"),
                    "role": "TEACHER",
                })
                teacher_user_ids.append(user.id)

                # Pick a realistic designation (weighted)
                desig_code = _weighted_choice(
                    [d[1] for d in DESIGNATIONS],
                    DESIGNATION_WEIGHTS,
                )
                # HOD / Dean only for senior faculty (1 per dept)
                if i == 0 and count >= 3:
                    desig_code = "HOD"
                elif i == 1 and dept_code == "CSE":
                    desig_code = "DEAN"

                desig_id = desig_map[desig_code]
                phone = make_phone()
                qual_options = ["Ph.D.", "M.Tech", "M.Sc.", "M.E.", "B.Tech + M.Tech (Dual)"]
                spec = f"{_pick(['Advanced ', 'Applied ', '', 'Industrial '])}{SUBJECT_DEFS[dept_code][i % len(SUBJECT_DEFS[dept_code])][0]}"
                exp = random.randint(3, 28)
                join_year = 2026 - exp
                join_dt = date(join_year, random.randint(6, 8), random.randint(1, 28))

                teacher = await db.teacher.create(data={
                    "userId": user.id,
                    "employeeId": emp_id,
                    "firstName": first,
                    "lastName": last,
                    "phone": phone,
                    "qualification": _pick(qual_options),
                    "specialization": spec,
                    "experienceYears": exp,
                    "joiningDate": _to_datetime(join_dt),
                    "departmentId": dept_map[dept_code],
                    "designationId": desig_id,
                })
                teacher_ids.append(teacher.id)
                teacher_counter[dept_code] += 1
                teacher_dept_map[dept_code].append({
                    "id": teacher.id,
                    "first_name": first,
                    "last_name": last,
                    "email": email,
                    "dept_code": dept_code,
                })

        print(f"  ✓ {len(teacher_ids)} teachers created")

        # ----- Students -----
        # Update name pool: add back any unused teacher names + remaining pool
        remaining_names = name_pool[60:]
        # If we need more names, generate additional ones
        total_students_needed = sum(s2 + s4 + s6 + s8 for _, s2, s4, s6, s8 in STUDENT_DEPT_DIST)
        while len(remaining_names) < total_students_needed:
            remaining_names.append((
                _pick(MALE_FIRST_NAMES + FEMALE_FIRST_NAMES),
                _pick(LAST_NAMES),
                _pick(["Male", "Female"]),
            ))

        print(f"\n[9/16] Seeding {total_students_needed} Students …")
        student_ids: list[str] = []
        student_info: list[dict] = []  # for use in enrollments & attendance

        enrollment_serial: dict[str, int] = {}
        for code, _, _, _, _ in STUDENT_DEPT_DIST:
            enrollment_serial[code] = 1

        def make_enrollment(dept_code: str, batch_start: str) -> str:
            serial = enrollment_serial[dept_code]
            enrollment_serial[dept_code] += 1
            return f"{dept_code}{batch_start}{serial:03d}"

        for dept_code, sem_2, sem_4, sem_6, sem_8 in STUDENT_DEPT_DIST:
            dept_id = dept_map[dept_code]
            for sem, count in [(2, sem_2), (4, sem_4), (6, sem_6), (8, sem_8)]:
                batch_str = BATCH_MAP[sem]
                batch_start = batch_str.split("-")[0]
                for _ in range(count):
                    first, last, gender = remaining_names.pop(0)
                    enroll_no = make_enrollment(dept_code, batch_start)
                    email = f"{enroll_no.lower()}@smartattendance.edu.in"

                    user = await db.user.create(data={
                        "email": email,
                        "hashedPassword": _hash_password("Student@123"),
                        "role": "STUDENT",
                    })
                    dob = make_dob_for_semester(sem)
                    phone = make_phone()
                    device_uuid = str(uuid.uuid4())

                    student = await db.student.create(data={
                        "userId": user.id,
                        "enrollmentNumber": enroll_no,
                        "firstName": first,
                        "lastName": last,
                        "phone": phone,
                        "gender": gender,
                        "dateOfBirth": _to_datetime(dob),
                        "semester": sem,
                        "batch": batch_str,
                        "departmentId": dept_id,
                        "deviceUuid": device_uuid,
                        "currentStreak": random.choices([0, 1, 2, 3, 5, 7, 10, 14], weights=[30, 20, 15, 10, 10, 8, 5, 2])[0],
                        "highestStreak": 0,  # will update below or leave as is
                    })
                    student_ids.append(student.id)
                    student_info.append({
                        "id": student.id,
                        "dept_code": dept_code,
                        "semester": sem,
                        "batch": batch_str,
                        "first_name": first,
                        "last_name": last,
                        "email": email,
                        "enroll_no": enroll_no,
                    })

        # Set highest streak for some students
        for s_info in random.sample(student_info, min(50, len(student_info))):
            sid = s_info["id"]
            hs = random.randint(3, 20)
            await db.student.update(where={"id": sid}, data={"highestStreak": hs})

        print(f"  ✓ {len(student_ids)} students created")

        # ------------------------------------------------------------------
        # 10. ACADEMIC CLASSES
        # ------------------------------------------------------------------
        print("\n[10/16] Seeding Academic Classes …")
        class_ids: list[str] = []
        class_info: list[dict] = []

        # Build a map: (dept_code, semester) -> list of subject codes
        dept_sem_subjects: dict[tuple[str, int], list[str]] = {}
        for dept_code, subjects in SUBJECT_DEFS.items():
            for name, code, sem in subjects:
                dept_sem_subjects.setdefault((dept_code, sem), []).append(code)

        classroom_names = [c[0] for c in CLASSROOMS]
        class_serial = 0

        for t_info in [item for sublist in teacher_dept_map.values() for item in sublist]:
            t_dept = t_info["dept_code"]
            # Find available subjects for this teacher's department
            # Teacher teaches across 2 semesters (pick 2 subjects from 2 different semesters)
            available_sems = sorted(set(sem for _, _, sem in SUBJECT_DEFS[t_dept]))
            if len(available_sems) < 2:
                continue

            sem1, sem2 = _pick_n(available_sems, 2)
            subs_for_sem1 = dept_sem_subjects.get((t_dept, sem1), [])
            subs_for_sem2 = dept_sem_subjects.get((t_dept, sem2), [])

            chosen_subs = []
            if subs_for_sem1:
                chosen_subs.append((_pick(subs_for_sem1), sem1))
            if subs_for_sem2:
                chosen_subs.append((_pick(subs_for_sem2), sem2))

            for sub_code, sem in chosen_subs:
                class_serial += 1
                sub_id = subject_map[sub_code]
                sub_name = next(n for n, c, _ in SUBJECT_DEFS[t_dept] if c == sub_code)
                cr_name = _pick(classroom_names)
                cr_id = classroom_map[cr_name]
                batch_str = BATCH_MAP[sem]
                class_name = f"{sub_name} ({batch_str})"

                cls = await db.academicclass.create(data={
                    "name": class_name,
                    "subjectId": sub_id,
                    "classroomId": cr_id,
                    "teacherId": t_info["id"],
                    "semester": sem,
                    "batch": batch_str,
                    "maxStudents": 60,
                })
                class_ids.append(cls.id)
                class_info.append({
                    "id": cls.id,
                    "name": class_name,
                    "subject_code": sub_code,
                    "dept_code": t_dept,
                    "semester": sem,
                    "batch": batch_str,
                    "teacher_id": t_info["id"],
                    "classroom_id": cr_id,
                })

        print(f"  ✓ {len(class_ids)} academic classes created")

        # ------------------------------------------------------------------
        # 11. GEOFENCES (one per class)
        # ------------------------------------------------------------------
        print("\n[11/16] Seeding Geofences …")
        geofence_class_ids: set[str] = set()
        for cl in class_info:
            lat, lng = jitter_gps(CAMPUS_LAT, CAMPUS_LNG, 0.003)
            radius = round(random.uniform(15.0, 50.0), 1)
            await db.geofence.create(data={
                "academicClassId": cl["id"],
                "latitude": lat,
                "longitude": lng,
                "radiusMeters": radius,
            })
            geofence_class_ids.add(cl["id"])
        print(f"  ✓ {len(geofence_class_ids)} geofences created")

        # ------------------------------------------------------------------
        # 12. ENROLLMENTS
        # ------------------------------------------------------------------
        print("\n[12/16] Seeding Enrollments …")
        enrollment_count = 0
        # For each student, enroll them in classes matching their dept & semester
        # Each student gets 4-6 classes
        for s_info in student_info:
            dept = s_info["dept_code"]
            sem = s_info["semester"]
            matching_classes = [cl for cl in class_info if cl["dept_code"] == dept and cl["semester"] == sem]
            available = _pick_n(matching_classes, min(len(matching_classes), random.randint(4, 6)))
            for cl in available:
                try:
                    await db.enrollment.create(data={
                        "studentId": s_info["id"],
                        "academicClassId": cl["id"],
                    })
                    enrollment_count += 1
                except Exception:
                    pass  # skip duplicate
        print(f"  ✓ {enrollment_count} enrollments created")

        # ------------------------------------------------------------------
        # 13. SESSIONS (1 month of activity)
        # ------------------------------------------------------------------
        print("\n[13/16] Seeding Sessions (~1 month: April 2026) …")

        session_ids: list[str] = []
        session_info: list[dict] = []

        for cl in class_info:
            # Each class meets 3-5 times per week over the month => ~12-20 sessions
            num_sessions = random.randint(12, 20)
            used_slots: set[tuple[int, int]] = set()  # (day_of_month, hour)

            for _ in range(num_sessions):
                for attempt in range(50):
                    day = random.randint(1, 30)
                    # Skip weekends (Saturday=5, Sunday=6 if Monday=0)
                    session_date = date(2026, 4, day)
                    wd = session_date.weekday()
                    if wd >= 5:
                        continue
                    hour = random.choice([8, 9, 10, 11, 14, 15, 16])
                    slot = (day, hour)
                    if slot not in used_slots:
                        used_slots.add(slot)
                        break
                else:
                    continue

                start_dt = datetime(2026, 4, day, hour, random.choice([0, 15, 30]), tzinfo=timezone.utc)
                duration = random.choice([45, 50, 55, 60])
                end_dt = start_dt + timedelta(minutes=duration)

                sess = await db.session.create(data={
                    "academicClassId": cl["id"],
                    "startTime": start_dt,
                    "endTime": end_dt,
                    "isActive": False,  # past sessions
                })
                session_ids.append(sess.id)
                session_info.append({
                    "id": sess.id,
                    "class_id": cl["id"],
                    "start": start_dt,
                    "end": end_dt,
                })

        print(f"  ✓ {len(session_ids)} sessions created")

        # ------------------------------------------------------------------
        # 14. ATTENDANCE RECORDS
        # ------------------------------------------------------------------
        print("\n[14/16] Seeding Attendance records …")
        attendance_count = 0

        # Pre-group enrollments by class_id for fast lookup
        enrollments_by_class: dict[str, list[str]] = {}
        for s_info in student_info:
            sid = s_info["id"]
            matching_classes = [cl for cl in class_info if cl["dept_code"] == s_info["dept_code"] and cl["semester"] == s_info["semester"]]
            for cl in matching_classes:
                enrollments_by_class.setdefault(cl["id"], []).append(sid)

        # Build attendance_pool per student: how likely they are to attend
        # 70% regular (85-95% attendance), 20% average (65-85%), 7% irregular (40-65%), 3% very irregular (<40%)
        student_attendance_pattern: dict[str, float] = {}
        for s_info in student_info:
            r = random.random()
            if r < 0.70:
                student_attendance_pattern[s_info["id"]] = random.uniform(0.85, 0.98)
            elif r < 0.90:
                student_attendance_pattern[s_info["id"]] = random.uniform(0.65, 0.84)
            elif r < 0.97:
                student_attendance_pattern[s_info["id"]] = random.uniform(0.40, 0.64)
            else:
                student_attendance_pattern[s_info["id"]] = random.uniform(0.10, 0.39)

        # Also pre-group students by class for attendance
        for sess in session_info:
            cl_id = sess["class_id"]
            enrolled_students = enrollments_by_class.get(cl_id, [])
            if not enrolled_students:
                continue

            for sid in enrolled_students:
                attend_prob = student_attendance_pattern.get(sid, 0.75)
                if random.random() > attend_prob:
                    continue  # student was absent — no record

                # Decide if present, flagged, or absent-marked
                status_roll = random.random()
                if status_roll < 0.82:
                    status = "Present"
                    scores = generate_present_scores()
                elif status_roll < 0.95:
                    status = "Flagged"
                    scores = generate_flagged_scores()
                else:
                    status = "Absent"
                    scores = {"face_score": 0.0, "liveness_score": 0.0, "background_score": 0.0, "final_ai_score": 0.0}

                gps_lat, gps_lng = jitter_gps(CAMPUS_LAT, CAMPUS_LNG, 0.005)

                remarks = None
                if status == "Flagged":
                    remarks = _pick([
                        "Low face confidence", "Lighting conditions poor",
                        "Background mismatch detected", "Face partially occluded",
                        "Liveness check inconclusive",
                    ])

                try:
                    await db.attendance.create(data={
                        "studentId": sid,
                        "sessionId": sess["id"],
                        "status": status,
                        "faceScore": scores["face_score"],
                        "livenessScore": scores["liveness_score"],
                        "backgroundScore": scores["background_score"],
                        "finalAiScore": scores["final_ai_score"],
                        "gpsLatitude": gps_lat,
                        "gpsLongitude": gps_lng,
                        "remarks": remarks,
                    })
                    attendance_count += 1
                except Exception:
                    pass  # skip duplicate

        print(f"  ✓ {attendance_count} attendance records created")

        # ------------------------------------------------------------------
        # 15. LEAVE REQUESTS
        # ------------------------------------------------------------------
        print("\n[15/16] Seeding Leave Requests …")
        leave_reasons = [
            "Medical appointment with specialist",
            "Family wedding function at hometown",
            "Fever and throat infection",
            "Attending a technical workshop in Bangalore",
            "Personal family emergency at home",
            "Eye check-up and consultation",
            "Higher studies counselling session",
            "Participating in college sports tournament",
            "Dental surgery recovery",
            "Sibling's marriage ceremony",
            "Preparation for competitive exam at coaching centre",
            "Travel for college industrial visit",
        ]
        leave_count = 0
        # Create leaves for ~40 students
        for s_info in random.sample(student_info, min(40, len(student_info))):
            start = date(2026, 4, random.randint(5, 25))
            duration = random.randint(1, 3)
            end = start + timedelta(days=duration)
            if end > date(2026, 4, 30):
                end = date(2026, 4, 30)

            status = _weighted_choice(["PENDING", "APPROVED", "REJECTED"], [0.25, 0.60, 0.15])
            approved_by = None
            approver_note = None
            if status == "APPROVED":
                approved_by = _pick(teacher_ids) if teacher_ids else None
                approver_note = _pick(["Approved", "Leave granted", "Ensure you catch up on missed classes"])
            elif status == "REJECTED":
                approved_by = _pick(teacher_ids) if teacher_ids else None
                approver_note = _pick(["Not enough supporting documents", "Attendance already below minimum"])

            await db.leaverequest.create(data={
                "studentId": s_info["id"],
                "startDate": _to_datetime(start),
                "endDate": _to_datetime(end),
                "reason": _pick(leave_reasons),
                "status": status,
                "approvedBy": approved_by,
                "approverNote": approver_note,
            })
            leave_count += 1
        print(f"  ✓ {leave_count} leave requests created")

        # ------------------------------------------------------------------
        # 16. DEVICE CHANGE REQUESTS
        # ------------------------------------------------------------------
        print("\n[16/16] Seeding Device Change Requests …")
        device_count = 0
        for s_info in random.sample(student_info, min(15, len(student_info))):
            new_uuid = str(uuid.uuid4())
            status = _weighted_choice(["PENDING", "APPROVED", "REJECTED"], [0.30, 0.55, 0.15])
            approved_by = None
            if status in ("APPROVED", "REJECTED"):
                approved_by = _pick(teacher_ids) if teacher_ids else None

            await db.devicechangerequest.create(data={
                "studentId": s_info["id"],
                "newDeviceUuid": new_uuid,
                "reason": _pick([
                    "Phone damaged, new device", "Lost previous phone",
                    "Upgraded to new phone", "Battery issue in old device",
                    "Old device stolen",
                ]),
                "status": status,
                "approvedBy": approved_by,
            })
            device_count += 1
        print(f"  ✓ {device_count} device change requests created")

        # ------------------------------------------------------------------
        # 17. AUDIT LOGS
        # ------------------------------------------------------------------
        print("\n  ✓ Seeding Audit Logs …")
        admin_id = admin_user.id
        audit_events = [
            ("USER_CREATED", "INFO", "System", f"Admin account created: {admin_user.id}", None),
            ("SYSTEM_CONFIG_UPDATED", "INFO", admin_id, "Initial system configuration set", None),
        ]
        for s_info in student_info[:5]:  # log first 5 student creations
            audit_events.append((
                "STUDENT_CREATED", "INFO", admin_id,
                f"Student {s_info['first_name']} {s_info['last_name']} ({s_info['enroll_no']}) registered",
                {"student_id": s_info["id"]},
            ))
        for t_info in teacher_dept_map["CSE"][:3]:
            audit_events.append((
                "TEACHER_CREATED", "INFO", admin_id,
                f"Teacher {t_info['first_name']} {t_info['last_name']} ({t_info['email']}) registered",
                {"teacher_id": t_info["id"]},
            ))

        for event_type, severity, actor, description, metadata in audit_events:
            log_data = {
                "eventType": event_type,
                "severity": severity,
                "actor": actor,
                "target": actor,
                "description": description,
                "ipAddress": "127.0.0.1",
            }
            if metadata:
                log_data["metadata"] = Json(metadata)
            await db.auditlog.create(data=log_data)
        print("  ✓ Audit logs created")

        # Recalculate streaks and build Redis leaderboard
        try:
            from app.db.redis import connect_redis, disconnect_redis
            from app.services.gamification_service import GamificationService
            await connect_redis()
            print("\nUpdating student streaks and Redis leaderboard...")
            gamification_service = GamificationService()
            for idx, s_id in enumerate(student_ids):
                await gamification_service.recalculate_student_streak(s_id)
            print("  ✓ Recalculated and synchronized all streaks/leaderboard scores")
        except Exception as re:
            print(f"  [WARNING] Failed to recalculate streaks/leaderboard: {re}")
        finally:
            try:
                await disconnect_redis()
            except Exception:
                pass

        # ======================================================================
        # SUMMARY
        # ======================================================================
        print("\n" + "=" * 72)
        print("  SEED COMPLETE — SUMMARY")
        print("=" * 72)
        print(f"  Departments      : {len(DEPARTMENTS)}")
        print(f"  Designations     : {len(DESIGNATIONS)}")
        print(f"  Subjects         : {len(subject_map)}")
        print(f"  Classrooms       : {len(CLASSROOMS)}")
        print("  Admins           : 1")
        print(f"  Teachers         : {len(teacher_ids)}")
        print(f"  Students         : {len(student_ids)}")
        print(f"  Academic Classes : {len(class_ids)}")
        print(f"  Geofences        : {len(geofence_class_ids)}")
        print(f"  Enrollments      : {enrollment_count}")
        print(f"  Sessions         : {len(session_ids)}")
        print(f"  Attendance       : {attendance_count}")
        print(f"  Leaves           : {leave_count}")
        print(f"  Device Changes   : {device_count}")
        print()

        # ---- CREDENTIALS ----
        sample_teacher = None
        for t_list in teacher_dept_map.values():
            if t_list:
                sample_teacher = t_list[0]
                break
        sample_student = student_info[0] if student_info else None

        print("-" * 72)
        print("  LOGIN CREDENTIALS")
        print("-" * 72)
        print("  ADMIN  →  admin@smartattendance.edu.in  /  Admin@123")
        if sample_teacher:
            print(f"  TEACHER →  {sample_teacher['email']}  /  Teacher@123")
        if sample_student:
            print(f"  STUDENT →  {sample_student['email']}  /  Student@123")
        print()

        print("  All student accounts: password = Student@123")
        print("  All teacher accounts: password = Teacher@123")
        print("=" * 72)

    finally:
        await db.disconnect()
        print("\nDatabase connection closed.")


# ==============================================================================
# SANDBOX SEED FOR PRATHAM RAJBHAR
# ==============================================================================

async def seed_all_pratham() -> None:
    """
    Seeds a sandbox database with exactly one student (Pratham Rajbhar)
    and 30+ days of historical attendance, leave requests, and device logs.
    """
    await db.connect()
    print("=" * 72)
    print("  SMART ATTENDANCE SYSTEM — PRATHAM RAJBHAR SEED")
    print("=" * 72)

    try:
        # 1. Clear tables
        print("\n[1/16] Clearing existing data …")
        await db.attendance.delete_many()
        await db.devicechangerequest.delete_many()
        await db.leaverequest.delete_many()
        await db.enrollment.delete_many()
        await db.geofence.delete_many()
        await db.session.delete_many()
        await db.academicclass.delete_many()
        await db.teacher.delete_many()
        await db.student.delete_many()
        await db.user.delete_many()
        await db.subject.delete_many()
        await db.classroom.delete_many()
        await db.designation.delete_many()
        await db.department.delete_many()
        await db.auditlog.delete_many()
        await db.systemconfiguration.delete_many()
        print("  ✓ All database tables cleared")

        # Clear Redis leaderboard cache
        try:
            from app.db.redis import connect_redis, disconnect_redis
            redis = await connect_redis()
            if redis:
                await redis.delete("leaderboard:points")
                print("  ✓ Redis leaderboard cache cleared")
                await disconnect_redis()
        except Exception as re:
            print(f"  [WARNING] Failed to clear Redis cache: {re}")

        # 2. System Configuration
        print("\n[2/16] Seeding System Configuration …")
        await db.systemconfiguration.create(data={
            "isFaceRecognitionEnabled": True,
            "isGpsVerificationEnabled": True,
            "isAiBackgroundValidationEnabled": True,
        })
        print("  ✓ System configuration initialized")

        # 3. Departments (Only CSE)
        print("\n[3/16] Seeding CSE Department …")
        dept = await db.department.create(data={
            "name": "Computer Science & Engineering",
            "code": "CSE",
            "head": "Dr. Rajesh Sharma",
            "description": "Department of Computer Science & Engineering",
        })
        print("  ✓ CSE department created")

        # 4. Designations
        print("\n[4/16] Seeding Designations …")
        desig_map = {}
        for name, code, desc in DESIGNATIONS:
            desig = await db.designation.create(data={
                "name": name,
                "code": code,
                "description": desc,
            })
            desig_map[code] = desig.id
        print(f"  ✓ {len(DESIGNATIONS)} designations created")

        # 5. Subjects (Only CSE 6th Sem subjects)
        print("\n[5/16] Seeding Subjects …")
        subject_map = {}
        cse_subs = [
            ("Computer Networks", "CSE401"),
            ("Software Engineering", "CSE402"),
            ("Web Technologies", "CSE403"),
            ("Design & Analysis of Algorithms", "CSE404"),
        ]
        for name, code in cse_subs:
            subj = await db.subject.create(data={
                "name": name,
                "code": code,
                "description": f"{name} core course",
            })
            subject_map[code] = subj.id
        print("  ✓ CSE Semester 6 subjects created")

        # 6. Classrooms
        print("\n[6/16] Seeding Classrooms …")
        classroom_map = {}
        for name, building, capacity in CLASSROOMS[:3]:  # pick first 3
            cr = await db.classroom.create(data={
                "name": name,
                "building": building,
                "capacity": capacity,
            })
            classroom_map[name] = cr.id
        print(f"  ✓ {len(classroom_map)} classrooms created")

        # 7. Admin User
        print("\n[7/16] Creating admin user …")
        admin_user = await db.user.create(data={
            "email": "admin@smartattendance.edu.in",
            "hashedPassword": _hash_password("Admin@123"),
            "role": "ADMIN",
        })
        print("  ✓ Admin user created")

        # 8. Teachers
        print("\n[8/16] Seeding Teachers …")
        teacher_defs = [
            ("Amit", "Patel", "EMP001", "PROF"),
            ("Sanjay", "Sharma", "EMP002", "APROF"),
            ("Neha", "Gupta", "EMP003", "ASPROF"),
        ]
        teacher_ids = []
        for first, last, emp_id, desig_code in teacher_defs:
            user = await db.user.create(data={
                "email": f"{emp_id.lower()}@smartattendance.edu.in",
                "hashedPassword": _hash_password("Teacher@123"),
                "role": "TEACHER",
            })
            teacher = await db.teacher.create(data={
                "userId": user.id,
                "employeeId": emp_id,
                "firstName": first,
                "lastName": last,
                "phone": make_phone(),
                "qualification": "Ph.D.",
                "specialization": "Computer Science",
                "experienceYears": 10,
                "joiningDate": _to_datetime(date(2018, 7, 1)),
                "departmentId": dept.id,
                "designationId": desig_map[desig_code],
            })
            teacher_ids.append(teacher.id)
        print(f"  ✓ {len(teacher_ids)} teachers created")

        # 9. Student (Pratham Rajbhar)
        print("\n[9/16] Seeding Student Pratham Rajbhar …")
        student_user = await db.user.create(data={
            "email": "pratham.rajbhar@smartattendance.edu.in",
            "hashedPassword": _hash_password("Student@123"),
            "role": "STUDENT",
        })
        student = await db.student.create(data={
            "userId": student_user.id,
            "enrollmentNumber": "CSE2023068",
            "firstName": "Pratham",
            "lastName": "Rajbhar",
            "phone": "+919988776655",
            "gender": "Male",
            "dateOfBirth": _to_datetime(date(2004, 8, 15)),
            "semester": 6,
            "batch": "2023-2027",
            "departmentId": dept.id,
            "deviceUuid": "d8f8a1a8-c2cb-4449-b71e-3bcadfc00b68",
            "currentStreak": 5,
            "highestStreak": 12,
        })
        print("  ✓ Student profile created")

        # 10. Academic Classes
        print("\n[10/16] Seeding Academic Classes …")
        cr_id = list(classroom_map.values())[0]
        class_defs = [
            ("Web Technologies (2023-2027)", "CSE403", teacher_ids[0]),
            ("Design & Analysis of Algorithms (2023-2027)", "CSE404", teacher_ids[1]),
            ("Computer Networks (2023-2027)", "CSE401", teacher_ids[2]),
            ("Software Engineering (2023-2027)", "CSE402", teacher_ids[0]),
        ]
        classes = []
        for name, code, t_id in class_defs:
            cls = await db.academicclass.create(data={
                "name": name,
                "subjectId": subject_map[code],
                "classroomId": cr_id,
                "teacherId": t_id,
                "semester": 6,
                "batch": "2023-2027",
                "maxStudents": 60,
            })
            classes.append({"id": cls.id, "code": code})
        print(f"  ✓ {len(classes)} academic classes created")

        # 11. Geofences
        print("\n[11/16] Seeding Geofences …")
        for idx, cl in enumerate(classes):
            cl_lat = CAMPUS_LAT + (idx * 0.0005)
            cl_lng = CAMPUS_LNG - (idx * 0.0005)
            await db.geofence.create(data={
                "academicClassId": cl["id"],
                "latitude": cl_lat,
                "longitude": cl_lng,
                "radiusMeters": 50.0,
            })
        print("  ✓ Geofences configured around campus")

        # 12. Enrollments
        print("\n[12/16] Seeding Enrollments …")
        for cl in classes:
            await db.enrollment.create(data={
                "studentId": student.id,
                "academicClassId": cl["id"],
            })
        print("  ✓ Enrolled student in all classes")

        # 13. Sessions & Attendance (35 Days)
        print("\n[13/16] Seeding 30+ Days of Sessions & Attendance …")
        session_count = 0
        attendance_count = 0
        
        # We loop back 35 days and seed weekday sessions
        today = datetime.now(timezone.utc).date()
        for offset in range(35, 0, -1):
            day_date = today - timedelta(days=offset)
            weekday = day_date.weekday()
            if weekday >= 5:  # skip weekends
                continue

            # Class schedules: Mon/Wed/Fri (CSE403, CSE404), Tue/Thu (CSE401, CSE402)
            scheduled_codes = ["CSE403", "CSE404"] if weekday in (0, 2, 4) else ["CSE401", "CSE402"]
            for code in scheduled_codes:
                cl_id = next(c["id"] for c in classes if c["code"] == code)
                hour = 10 if code in ("CSE403", "CSE401") else 14
                start_dt = datetime(day_date.year, day_date.month, day_date.day, hour, 0, tzinfo=timezone.utc)
                end_dt = start_dt + timedelta(hours=1)

                sess = await db.session.create(data={
                    "academicClassId": cl_id,
                    "startTime": start_dt,
                    "endTime": end_dt,
                    "isActive": False,
                })
                session_count += 1

                # Generate status distribution: Present (85%), Flagged (8%), Absent (7%)
                roll = random.random()
                if roll < 0.85:
                    status = "Present"
                    scores = generate_present_scores()
                elif roll < 0.93:
                    status = "Flagged"
                    scores = generate_flagged_scores()
                else:
                    status = "Absent"
                    scores = {"face_score": 0.0, "liveness_score": 0.0, "background_score": 0.0, "final_ai_score": 0.0}

                gps_lat, gps_lng = jitter_gps(CAMPUS_LAT, CAMPUS_LNG, 0.0001)

                await db.attendance.create(data={
                    "studentId": student.id,
                    "sessionId": sess.id,
                    "status": status,
                    "faceScore": scores["face_score"],
                    "livenessScore": scores["liveness_score"],
                    "backgroundScore": scores["background_score"],
                    "finalAiScore": scores["final_ai_score"],
                    "gpsLatitude": gps_lat,
                    "gpsLongitude": gps_lng,
                    "remarks": "Low face confidence" if status == "Flagged" else None,
                })
                attendance_count += 1

        print(f"  ✓ {session_count} sessions created")
        print(f"  ✓ {attendance_count} attendance records created")

        # 14. Leave Request
        print("\n[14/16] Seeding Leave Request …")
        await db.leaverequest.create(data={
            "studentId": student.id,
            "startDate": _to_datetime(today - timedelta(days=12)),
            "endDate": _to_datetime(today - timedelta(days=10)),
            "reason": "Recovering from viral fever and throat infection",
            "status": "APPROVED",
            "approvedBy": teacher_ids[0],
            "approverNote": "Get well soon. Make sure to complete pending assignments.",
        })
        print("  ✓ Approved leave request seeded")

        # 15. Device Change Request
        print("\n[15/16] Seeding Device Change Request …")
        await db.devicechangerequest.create(data={
            "studentId": student.id,
            "reason": "Phone screen damaged, upgraded to a new device",
            "newDeviceUuid": str(uuid.uuid4()),
            "status": "APPROVED",
            "approvedBy": teacher_ids[0],
        })
        print("  ✓ Approved device change request seeded")

        # 16. Audit Logs
        print("\n[16/16] Seeding Audit Logs …")
        await db.auditlog.create(data={
            "eventType": "STUDENT_CREATED",
            "severity": "INFO",
            "actor": admin_user.id,
            "target": student.id,
            "description": f"Student Pratham Rajbhar ({student.enrollmentNumber}) registered by admin",
            "ipAddress": "127.0.0.1",
        })
        print("  ✓ Administrative audit logs created")

        # Recalculate streaks and build Redis leaderboard
        try:
            from app.db.redis import connect_redis, disconnect_redis
            from app.services.gamification_service import GamificationService
            await connect_redis()
            print("\nUpdating student streaks and Redis leaderboard...")
            gamification_service = GamificationService()
            await gamification_service.recalculate_student_streak(student.id)
            print("  ✓ Recalculated and synchronized all streaks/leaderboard scores")
        except Exception as re:
            print(f"  [WARNING] Failed to recalculate streaks/leaderboard: {re}")
        finally:
            try:
                await disconnect_redis()
            except Exception:
                pass

        # Summary Printout
        print("\n" + "=" * 72)
        print("  SEED COMPLETE — SUMMARY")
        print("=" * 72)
        print("  Departments      : 1")
        print(f"  Designations     : {len(DESIGNATIONS)}")
        print("  Subjects         : 4")
        print(f"  Classrooms       : {len(classroom_map)}")
        print("  Admins           : 1")
        print(f"  Teachers         : {len(teacher_ids)}")
        print("  Students         : 1 (Pratham Rajbhar)")
        print(f"  Academic Classes : {len(classes)}")
        print(f"  Geofences        : {len(classes)}")
        print(f"  Enrollments      : {len(classes)}")
        print(f"  Sessions         : {session_count}")
        print(f"  Attendance       : {attendance_count}")
        print("  Leaves           : 1")
        print("  Device Changes   : 1")
        print("-" * 72)
        print("  LOGIN CREDENTIALS")
        print("-" * 72)
        print("  ADMIN  →  admin@smartattendance.edu.in  /  Admin@123")
        print("  TEACHER →  emp001@smartattendance.edu.in  /  Teacher@123")
        print("  STUDENT →  pratham.rajbhar@smartattendance.edu.in  /  Student@123")
        print("=" * 72)

    finally:
        await db.disconnect()
        print("\nDatabase connection closed.")


# ==============================================================================
# ENTRY POINT
# ==============================================================================

if __name__ == "__main__":
    asyncio.run(seed_all())

