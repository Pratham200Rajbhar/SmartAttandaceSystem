import asyncio
import logging
import sys
import os
from datetime import datetime, timedelta, timezone

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.db.client import db, connect_db, disconnect_db  # noqa: E402
from app.core.security import hash_password  # noqa: E402

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("seed")


async def clear_database() -> None:
    logger.info("Clearing database...")
    tables = [
        db.attendance, db.enrollment, db.session, db.geofence,
        db.academicclass, db.teacher, db.student, db.leaverequest,
        db.auditlog, db.user, db.department, db.subject, db.classroom, db.designation,
    ]
    for table in tables:
        try:
            await table.delete_many()
        except Exception as err:
            logger.error("Failed to clear table %s: %s", table.__class__.__name__, err, exc_info=True)


async def seed_admin() -> None:
    await db.user.create(data={
        "email": "admin@example.com", "hashedPassword": hash_password("admin123"),
        "role": "ADMIN", "isActive": True,
    })


async def seed_from_list(table, items: list[dict]) -> dict:
    result = {}
    for item in items:
        try:
            record = await table.create(data={k: v for k, v in item.items() if k != "_key"})
            result[item.get("_key", item.get("code") or item.get("name"))] = record
        except Exception as err:
            logger.error("Failed to seed %s: %s", item.get("name", item), err, exc_info=True)
            raise
    return result


async def seed_departments() -> dict:
    return await seed_from_list(db.department, [
        {"name": "Computer Science & Engineering", "code": "CSE", "head": "Dr. Ramesh Sharma", "description": "Department of CSE"},
        {"name": "Information Technology", "code": "IT", "head": "Dr. Anita Roy", "description": "Department of IT"},
        {"name": "Electronics & Communication Engineering", "code": "ECE", "head": "Dr. Sunil Verma", "description": "Department of ECE"},
    ])


async def seed_designations() -> dict:
    return await seed_from_list(db.designation, [
        {"name": "Professor", "code": "PROF", "description": "Senior faculty head position"},
        {"name": "Assistant Professor", "code": "ASST", "description": "Tenure-track faculty"},
        {"name": "Lecturer", "code": "LECT", "description": "Contractual/entry teaching position"},
    ])


async def seed_subjects() -> dict:
    return await seed_from_list(db.subject, [
        {"name": "Data Structures & Algorithms", "code": "CS101", "description": "Fundamental course on data structures"},
        {"name": "Web Development", "code": "CS102", "description": "Full stack web development basics"},
        {"name": "Digital Electronics", "code": "EC101", "description": "Fundamentals of logic gates and circuits"},
    ])


async def seed_classrooms() -> dict:
    return await seed_from_list(db.classroom, [
        {"name": "Lab 1", "building": "Block A", "capacity": 40, "_key": "Lab 1"},
        {"name": "Seminar Hall 1", "building": "Block B", "capacity": 120, "_key": "Seminar Hall 1"},
        {"name": "Room 301", "building": "Block C", "capacity": 60, "_key": "Room 301"},
    ])


async def seed_teachers(depts: dict, desigs: dict) -> dict:
    teachers_data = [
        {"email": "rajesh.kumar@example.com", "password": "teacher123", "firstName": "Rajesh", "lastName": "Kumar", "employeeId": "T001", "dept_code": "CSE", "desig_code": "PROF"},
        {"email": "sunita.rao@example.com", "password": "teacher123", "firstName": "Sunita", "lastName": "Rao", "employeeId": "T002", "dept_code": "CSE", "desig_code": "ASST"},
        {"email": "anil.deshmukh@example.com", "password": "teacher123", "firstName": "Anil", "lastName": "Deshmukh", "employeeId": "T003", "dept_code": "IT", "desig_code": "PROF"},
        {"email": "meera.nair@example.com", "password": "teacher123", "firstName": "Meera", "lastName": "Nair", "employeeId": "T004", "dept_code": "IT", "desig_code": "ASST"},
        {"email": "vikram.singh@example.com", "password": "teacher123", "firstName": "Vikram", "lastName": "Singh", "employeeId": "T005", "dept_code": "ECE", "desig_code": "LECT"},
    ]
    teachers = {}
    for t in teachers_data:
        try:
            user = await db.user.create(data={
                "email": t["email"], "hashedPassword": hash_password(t["password"]),
                "role": "TEACHER", "isActive": True,
            })
            teacher = await db.teacher.create(data={
                "userId": user.id, "firstName": t["firstName"], "lastName": t["lastName"],
                "employeeId": t["employeeId"], "departmentId": depts[t["dept_code"]].id,
                "designationId": desigs[t["desig_code"]].id,
            })
            teachers[t["employeeId"]] = teacher
        except Exception as err:
            logger.error("Failed to seed teacher %s: %s", t["email"], err, exc_info=True)
            raise
    return teachers


async def seed_students(depts: dict) -> dict:
    students_data = [
        {"email": "aarav.patel@example.com", "firstName": "Aarav", "lastName": "Patel", "enroll": "S001", "dept_code": "CSE", "gender": "MALE"},
        {"email": "priya.sharma@example.com", "firstName": "Priya", "lastName": "Sharma", "enroll": "S002", "dept_code": "CSE", "gender": "FEMALE"},
        {"email": "rohan.verma@example.com", "firstName": "Rohan", "lastName": "Verma", "enroll": "S003", "dept_code": "IT", "gender": "MALE"},
        {"email": "ananya.gupta@example.com", "firstName": "Ananya", "lastName": "Gupta", "enroll": "S004", "dept_code": "IT", "gender": "FEMALE"},
        {"email": "arjun.reddy@example.com", "firstName": "Arjun", "lastName": "Reddy", "enroll": "S005", "dept_code": "ECE", "gender": "MALE"},
    ]
    students = {}
    for s in students_data:
        try:
            user = await db.user.create(data={
                "email": s["email"], "hashedPassword": hash_password("student123"),
                "role": "STUDENT", "isActive": True,
            })
            student = await db.student.create(data={
                "userId": user.id, "enrollmentNumber": s["enroll"],
                "firstName": s["firstName"], "lastName": s["lastName"],
                "semester": 4, "batch": "2026", "gender": s["gender"],
                "departmentId": depts[s["dept_code"]].id,
            })
            students[s["enroll"]] = student
        except Exception as err:
            logger.error("Failed to seed student %s: %s", s["email"], err, exc_info=True)
            raise
    return students


async def seed_academic_classes(subs: dict, rooms: dict, teachers: dict) -> dict:
    classes_data = [
        {"name": "CSE-DSA-4A", "sub_code": "CS101", "room_name": "Lab 1", "teacher_emp": "T001", "semester": 4, "batch": "2026"},
        {"name": "IT-WEBDEV-4B", "sub_code": "CS102", "room_name": "Seminar Hall 1", "teacher_emp": "T003", "semester": 4, "batch": "2026"},
        {"name": "ECE-DE-4C", "sub_code": "EC101", "room_name": "Room 301", "teacher_emp": "T005", "semester": 4, "batch": "2026"},
    ]
    classes = {}
    for c in classes_data:
        try:
            cls = await db.academicclass.create(data={
                "name": c["name"], "subjectId": subs[c["sub_code"]].id,
                "classroomId": rooms[c["room_name"]].id, "teacherId": teachers[c["teacher_emp"]].id,
                "semester": c["semester"], "batch": c["batch"], "maxStudents": 40,
            })
            classes[c["name"]] = cls
        except Exception as err:
            logger.error("Failed to seed class %s: %s", c["name"], err, exc_info=True)
            raise
    return classes


async def seed_geofences(classes: dict) -> None:
    for name, cls in classes.items():
        try:
            await db.geofence.create(data={
                "academicClassId": cls.id, "latitude": 19.0760, "longitude": 72.8777, "radiusMeters": 100.0,
            })
        except Exception as err:
            logger.error("Failed to seed geofence for %s: %s", name, err, exc_info=True)
            raise


async def seed_enrollments(students: dict, classes: dict) -> None:
    try:
        for enroll_no in ["S001", "S002"]:
            await db.enrollment.create(data={"studentId": students[enroll_no].id, "academicClassId": classes["CSE-DSA-4A"].id})
            await db.enrollment.create(data={"studentId": students[enroll_no].id, "academicClassId": classes["IT-WEBDEV-4B"].id})
        for enroll_no in ["S003", "S004"]:
            await db.enrollment.create(data={"studentId": students[enroll_no].id, "academicClassId": classes["IT-WEBDEV-4B"].id})
        await db.enrollment.create(data={"studentId": students["S005"].id, "academicClassId": classes["ECE-DE-4C"].id})
    except Exception as err:
        logger.error("Failed to seed enrollments: %s", err, exc_info=True)
        raise


async def seed_active_sessions(classes: dict) -> None:
    now = datetime.now(timezone.utc)
    end = now + timedelta(hours=1)
    for name, cls in classes.items():
        try:
            await db.session.create(data={
                "academicClassId": cls.id, "startTime": now, "endTime": end, "isActive": True,
            })
        except Exception as err:
            logger.error("Failed to seed session for %s: %s", name, err, exc_info=True)
            raise


async def seed_all() -> None:
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
        logger.info("Database seeded successfully")
    except Exception as err:
        logger.error("Seeding failed: %s", err, exc_info=True)
        raise
    finally:
        await disconnect_db()


if __name__ == "__main__":
    asyncio.run(seed_all())
