import asyncio
import logging
import sys
import os
from datetime import datetime, timedelta, timezone

# Ensure the parent directory is in the path so we can import from `app`
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.db.client import db, connect_db, disconnect_db
from app.core.security import hash_password

# Set up logging for the seed operations
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("prisma.seed_db")


async def clear_database() -> None:
    """
    Clears all existing tables in correct dependency order to prevent foreign key constraint violations.
    """
    logger.info("Clearing existing database tables...")
    try:
        # Clear child/relation tables first
        await db.attendance.delete_many()
        await db.enrollment.delete_many()
        await db.session.delete_many()
        await db.geofence.delete_many()
        await db.academicclass.delete_many()
        await db.teacher.delete_many()
        await db.student.delete_many()
        await db.leaveplaylog.delete_many() if hasattr(db, "leaveplaylog") else None
        await db.leaverequest.delete_many()
        await db.auditlog.delete_many()
        
        # Clear main entity tables
        await db.user.delete_many()
        await db.department.delete_many()
        await db.subject.delete_many()
        await db.classroom.delete_many()
        await db.designation.delete_many()
        logger.info("Database tables cleared successfully.")
    except Exception as err:
        logger.error(f"Error occurred while clearing database: {err}", exc_info=True)
        raise err


async def seed_departments() -> dict:
    """
    Seeds department records and returns a mapping of code to department objects.
    """
    departments_data = [
        {"name": "Computer Science & Engineering", "code": "CSE", "head": "Dr. Ramesh Sharma", "description": "Department of CSE"},
        {"name": "Information Technology", "code": "IT", "head": "Dr. Anita Roy", "description": "Department of IT"},
        {"name": "Electronics & Communication Engineering", "code": "ECE", "head": "Dr. Sunil Verma", "description": "Department of ECE"},
    ]
    logger.info("Seeding departments...")
    depts = {}
    for dept in departments_data:
        try:
            record = await db.department.create(data=dept)
            depts[dept["code"]] = record
            logger.info(f"Seeded Department: {dept['code']}")
        except Exception as err:
            logger.error(f"Failed to seed department {dept['code']}: {err}", exc_info=True)
            raise err
    return depts


async def seed_designations() -> dict:
    """
    Seeds designation records and returns a mapping of code to designation objects.
    """
    designations_data = [
        {"name": "Professor", "code": "PROF", "description": "Senior faculty head position"},
        {"name": "Assistant Professor", "code": "ASST", "description": "Tenure-track faculty"},
        {"name": "Lecturer", "code": "LECT", "description": "Contractual/entry teaching position"},
    ]
    logger.info("Seeding designations...")
    desigs = {}
    for desig in designations_data:
        try:
            record = await db.designation.create(data=desig)
            desigs[desig["code"]] = record
            logger.info(f"Seeded Designation: {desig['code']}")
        except Exception as err:
            logger.error(f"Failed to seed designation {desig['code']}: {err}", exc_info=True)
            raise err
    return desigs


async def seed_subjects() -> dict:
    """
    Seeds subjects and returns a mapping of code to subject objects.
    """
    subjects_data = [
        {"name": "Data Structures & Algorithms", "code": "CS101", "description": "Fundamental course on data structures"},
        {"name": "Web Development", "code": "CS102", "description": "Full stack web development basics"},
        {"name": "Digital Electronics", "code": "EC101", "description": "Fundamentals of logic gates and circuits"},
    ]
    logger.info("Seeding subjects...")
    subs = {}
    for sub in subjects_data:
        try:
            record = await db.subject.create(data=sub)
            subs[sub["code"]] = record
            logger.info(f"Seeded Subject: {sub['code']}")
        except Exception as err:
            logger.error(f"Failed to seed subject {sub['code']}: {err}", exc_info=True)
            raise err
    return subs


async def seed_classrooms() -> dict:
    """
    Seeds classrooms and returns a mapping of name to classroom objects.
    """
    classrooms_data = [
        {"name": "Lab 1", "building": "Block A", "capacity": 40},
        {"name": "Seminar Hall 1", "building": "Block B", "capacity": 120},
        {"name": "Room 301", "building": "Block C", "capacity": 60},
    ]
    logger.info("Seeding classrooms...")
    rooms = {}
    for room in classrooms_data:
        try:
            record = await db.classroom.create(data=room)
            rooms[room["name"]] = record
            logger.info(f"Seeded Classroom: {room['name']}")
        except Exception as err:
            logger.error(f"Failed to seed classroom {room['name']}: {err}", exc_info=True)
            raise err
    return rooms


async def seed_admin() -> None:
    """
    Seeds 1 default administrator user.
    """
    admin_email = "admin@example.com"
    admin_pass = "admin123"
    hashed_pass = hash_password(admin_pass)
    logger.info(f"Creating default admin account: {admin_email}...")
    try:
        admin_user = await db.user.create(
            data={
                "email": admin_email,
                "hashedPassword": hashed_pass,
                "role": "ADMIN",
                "isActive": True
            }
        )
        logger.info(f"Created Admin user: {admin_user.email}")
    except Exception as err:
        logger.error(f"Failed to seed Admin user: {err}", exc_info=True)
        raise err


async def seed_teachers(depts: dict, desigs: dict) -> dict:
    """
    Seeds 5 teachers using real-life Indian names. Returns mapping of employeeId to teacher objects.
    """
    teachers_data = [
        {
            "email": "rajesh.kumar@example.com",
            "password": "teacher123",
            "firstName": "Rajesh",
            "lastName": "Kumar",
            "employeeId": "T001",
            "dept_code": "CSE",
            "desig_code": "PROF"
        },
        {
            "email": "sunita.rao@example.com",
            "password": "teacher123",
            "firstName": "Sunita",
            "lastName": "Rao",
            "employeeId": "T002",
            "dept_code": "CSE",
            "desig_code": "ASST"
        },
        {
            "email": "anil.deshmukh@example.com",
            "password": "teacher123",
            "firstName": "Anil",
            "lastName": "Deshmukh",
            "employeeId": "T003",
            "dept_code": "IT",
            "desig_code": "PROF"
        },
        {
            "email": "meera.nair@example.com",
            "password": "teacher123",
            "firstName": "Meera",
            "lastName": "Nair",
            "employeeId": "T004",
            "dept_code": "IT",
            "desig_code": "ASST"
        },
        {
            "email": "vikram.singh@example.com",
            "password": "teacher123",
            "firstName": "Vikram",
            "lastName": "Singh",
            "employeeId": "T005",
            "dept_code": "ECE",
            "desig_code": "LECT"
        }
    ]
    
    logger.info("Seeding Teachers...")
    teachers = {}
    for teacher in teachers_data:
        try:
            hashed_pass = hash_password(teacher["password"])
            user_rec = await db.user.create(
                data={
                    "email": teacher["email"],
                    "hashedPassword": hashed_pass,
                    "role": "TEACHER",
                    "isActive": True
                }
            )
            teacher_rec = await db.teacher.create(
                data={
                    "userId": user_rec.id,
                    "firstName": teacher["firstName"],
                    "lastName": teacher["lastName"],
                    "employeeId": teacher["employeeId"],
                    "departmentId": depts[teacher["dept_code"]].id,
                    "designationId": desigs[teacher["desig_code"]].id
                }
            )
            teachers[teacher["employeeId"]] = teacher_rec
            logger.info(f"Seeded Teacher: {teacher['firstName']} {teacher['lastName']} ({teacher['email']})")
        except Exception as err:
            logger.error(f"Failed to seed teacher {teacher['email']}: {err}", exc_info=True)
            raise err
    return teachers


async def seed_students(depts: dict) -> dict:
    """
    Seeds 5 students using real-life Indian names. Returns mapping of enrollmentNumber to student objects.
    """
    students_data = [
        {"email": "aarav.patel@example.com", "firstName": "Aarav", "lastName": "Patel", "enroll": "S001", "dept_code": "CSE", "gender": "MALE"},
        {"email": "priya.sharma@example.com", "firstName": "Priya", "lastName": "Sharma", "enroll": "S002", "dept_code": "CSE", "gender": "FEMALE"},
        {"email": "rohan.verma@example.com", "firstName": "Rohan", "lastName": "Verma", "enroll": "S003", "dept_code": "IT", "gender": "MALE"},
        {"email": "ananya.gupta@example.com", "firstName": "Ananya", "lastName": "Gupta", "enroll": "S004", "dept_code": "IT", "gender": "FEMALE"},
        {"email": "arjun.reddy@example.com", "firstName": "Arjun", "lastName": "Reddy", "enroll": "S005", "dept_code": "ECE", "gender": "MALE"},
    ]
    
    logger.info("Seeding Students...")
    students = {}
    for student in students_data:
        try:
            hashed_pass = hash_password("student123")
            user_rec = await db.user.create(
                data={
                    "email": student["email"],
                    "hashedPassword": hashed_pass,
                    "role": "STUDENT",
                    "isActive": True
                }
            )
            student_rec = await db.student.create(
                data={
                    "userId": user_rec.id,
                    "enrollmentNumber": student["enroll"],
                    "firstName": student["firstName"],
                    "lastName": student["lastName"],
                    "semester": 4,
                    "batch": "2026",
                    "gender": student["gender"],
                    "departmentId": depts[student["dept_code"]].id
                }
            )
            students[student["enroll"]] = student_rec
            logger.info(f"Seeded Student: {student['firstName']} {student['lastName']} ({student['enroll']})")
        except Exception as err:
            logger.error(f"Failed to seed student {student['email']}: {err}", exc_info=True)
            raise err
    return students


async def seed_academic_classes(subs: dict, rooms: dict, teachers: dict) -> dict:
    """
    Seeds academic classes and links them with teachers, subjects, and classrooms.
    """
    classes_data = [
        {
            "name": "CSE-DSA-4A",
            "sub_code": "CS101",
            "room_name": "Lab 1",
            "teacher_emp": "T001",
            "semester": 4,
            "batch": "2026"
        },
        {
            "name": "IT-WEBDEV-4B",
            "sub_code": "CS102",
            "room_name": "Seminar Hall 1",
            "teacher_emp": "T003",
            "semester": 4,
            "batch": "2026"
        },
        {
            "name": "ECE-DE-4C",
            "sub_code": "EC101",
            "room_name": "Room 301",
            "teacher_emp": "T005",
            "semester": 4,
            "batch": "2026"
        }
    ]
    
    logger.info("Seeding Academic Classes...")
    classes = {}
    for cls in classes_data:
        try:
            class_rec = await db.academicclass.create(
                data={
                    "name": cls["name"],
                    "subjectId": subs[cls["sub_code"]].id,
                    "classroomId": rooms[cls["room_name"]].id,
                    "teacherId": teachers[cls["teacher_emp"]].id,
                    "semester": cls["semester"],
                    "batch": cls["batch"],
                    "maxStudents": 40
                }
            )
            classes[cls["name"]] = class_rec
            logger.info(f"Seeded Class: {cls['name']}")
        except Exception as err:
            logger.error(f"Failed to seed class {cls['name']}: {err}", exc_info=True)
            raise err
    return classes


async def seed_geofences(classes: dict) -> None:
    """
    Seeds Geofences for each academic class.
    """
    logger.info("Seeding Geofences...")
    for name, cls_rec in classes.items():
        try:
            await db.geofence.create(
                data={
                    "academicClassId": cls_rec.id,
                    "latitude": 19.0760,
                    "longitude": 72.8777,
                    "radiusMeters": 100.0
                }
            )
            logger.info(f"Seeded Geofence for class: {name}")
        except Exception as err:
            logger.error(f"Failed to seed geofence for class {name}: {err}", exc_info=True)
            raise err


async def seed_enrollments(students: dict, classes: dict) -> None:
    """
    Enrolls students into academic classes.
    """
    logger.info("Seeding Student Enrollments...")
    try:
        # Enroll Aarav and Priya in CSE and IT classes
        cse_class = classes["CSE-DSA-4A"]
        it_class = classes["IT-WEBDEV-4B"]
        ece_class = classes["ECE-DE-4C"]
        
        for enroll_no in ["S001", "S002"]:
            await db.enrollment.create(data={"studentId": students[enroll_no].id, "academicClassId": cse_class.id})
            await db.enrollment.create(data={"studentId": students[enroll_no].id, "academicClassId": it_class.id})
            
        # Enroll Rohan and Ananya in IT class
        for enroll_no in ["S003", "S004"]:
            await db.enrollment.create(data={"studentId": students[enroll_no].id, "academicClassId": it_class.id})
            
        # Enroll Arjun in ECE class
        await db.enrollment.create(data={"studentId": students["S005"].id, "academicClassId": ece_class.id})
        logger.info("Successfully enrolled students.")
    except Exception as err:
        logger.error(f"Failed to seed enrollments: {err}", exc_info=True)
        raise err


async def seed_active_sessions(classes: dict) -> None:
    """
    Seeds active sessions starting now and ending in 1 hour.
    """
    logger.info("Seeding active Class Sessions...")
    now = datetime.now(timezone.utc)
    end = now + timedelta(hours=1)
    for name, cls_rec in classes.items():
        try:
            await db.session.create(
                data={
                    "academicClassId": cls_rec.id,
                    "startTime": now,
                    "endTime": end,
                    "isActive": True
                }
            )
            logger.info(f"Seeded Active Session for class: {name}")
        except Exception as err:
            logger.error(f"Failed to seed active session for class {name}: {err}", exc_info=True)
            raise err


async def seed_all() -> None:
    """
    Orchestrates the entire DB seeding process.
    """
    logger.info("Connecting to the database for seeding operations...")
    await connect_db()
    try:
        await clear_database()
        await seed_admin()
        depts = await seed_departments()
        desigs = await seed_designations()
        subs = await seed_subjects()
        rooms = await seed_classrooms()
        teachers = await seed_teachers(depts, desigs)
        students = await seed_students(depts)
        classes = await seed_academic_classes(subs, rooms, teachers)
        await seed_geofences(classes)
        await seed_enrollments(students, classes)
        await seed_active_sessions(classes)
        logger.info("Database seeding completed successfully.")
    except Exception as err:
        logger.error(f"Failed database seeding execution: {err}", exc_info=True)
        raise err
    finally:
        logger.info("Disconnecting from the database...")
        await disconnect_db()


if __name__ == "__main__":
    asyncio.run(seed_all())
