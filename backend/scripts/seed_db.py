import asyncio
import logging
import sys
import os
from datetime import datetime, timedelta, timezone

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.db.client import db, connect_db, disconnect_db
from app.core.security import hash_password

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("seed")


async def clear_database() -> None:
    logger.info("Clearing database...")
    try:
        await db.attendance.delete_many()
        await db.enrollment.delete_many()
        await db.session.delete_many()
        await db.geofence.delete_many()
        await db.academicclass.delete_many()
        await db.teacher.delete_many()
        await db.student.delete_many()
        await db.leaverequest.delete_many()
        await db.auditlog.delete_many()
        await db.user.delete_many()
        await db.department.delete_many()
        await db.subject.delete_many()
        await db.classroom.delete_many()
        await db.designation.delete_many()
    except Exception as err:
        logger.error("Failed to clear database: %s", err, exc_info=True)
        raise err


async def seed_departments() -> dict:
    departments_data = [
        {"name": "Computer Science & Engineering", "code": "CSE", "head": "Dr. Ramesh Sharma", "description": "Department of CSE"},
        {"name": "Information Technology", "code": "IT", "head": "Dr. Anita Roy", "description": "Department of IT"},
        {"name": "Electronics & Communication Engineering", "code": "ECE", "head": "Dr. Sunil Verma", "description": "Department of ECE"},
    ]
    depts = {}
    for dept in departments_data:
        try:
            record = await db.department.create(data=dept)
            depts[dept["code"]] = record
        except Exception as err:
            logger.error("Failed to seed department %s: %s", dept["code"], err, exc_info=True)
            raise err
    return depts


async def seed_designations() -> dict:
    designations_data = [
        {"name": "Professor", "code": "PROF", "description": "Senior faculty head position"},
        {"name": "Assistant Professor", "code": "ASST", "description": "Tenure-track faculty"},
        {"name": "Lecturer", "code": "LECT", "description": "Contractual/entry teaching position"},
    ]
    desigs = {}
    for desig in designations_data:
        try:
            record = await db.designation.create(data=desig)
            desigs[desig["code"]] = record
        except Exception as err:
            logger.error("Failed to seed designation %s: %s", desig["code"], err, exc_info=True)
            raise err
    return desigs


async def seed_subjects() -> dict:
    subjects_data = [
        {"name": "Data Structures & Algorithms", "code": "CS101", "description": "Fundamental course on data structures"},
        {"name": "Web Development", "code": "CS102", "description": "Full stack web development basics"},
        {"name": "Digital Electronics", "code": "EC101", "description": "Fundamentals of logic gates and circuits"},
    ]
    subs = {}
    for sub in subjects_data:
        try:
            record = await db.subject.create(data=sub)
            subs[sub["code"]] = record
        except Exception as err:
            logger.error("Failed to seed subject %s: %s", sub["code"], err, exc_info=True)
            raise err
    return subs


async def seed_classrooms() -> dict:
    classrooms_data = [
        {"name": "Lab 1", "building": "Block A", "capacity": 40},
        {"name": "Seminar Hall 1", "building": "Block B", "capacity": 120},
        {"name": "Room 301", "building": "Block C", "capacity": 60},
    ]
    rooms = {}
    for room in classrooms_data:
        try:
            record = await db.classroom.create(data=room)
            rooms[room["name"]] = record
        except Exception as err:
            logger.error("Failed to seed classroom %s: %s", room["name"], err, exc_info=True)
            raise err
    return rooms


async def seed_admin() -> None:
    try:
        await db.user.create(data={
            "email": "admin@example.com",
            "hashedPassword": hash_password("admin123"),
            "role": "ADMIN",
            "isActive": True,
        })
    except Exception as err:
        logger.error("Failed to seed admin: %s", err, exc_info=True)
        raise err


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
            user_rec = await db.user.create(data={
                "email": t["email"], "hashedPassword": hash_password(t["password"]),
                "role": "TEACHER", "isActive": True,
            })
            teacher_rec = await db.teacher.create(data={
                "userId": user_rec.id, "firstName": t["firstName"], "lastName": t["lastName"],
                "employeeId": t["employeeId"], "departmentId": depts[t["dept_code"]].id,
                "designationId": desigs[t["desig_code"]].id,
            })
            teachers[t["employeeId"]] = teacher_rec
        except Exception as err:
            logger.error("Failed to seed teacher %s: %s", t["email"], err, exc_info=True)
            raise err
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
            user_rec = await db.user.create(data={
                "email": s["email"], "hashedPassword": hash_password("student123"),
                "role": "STUDENT", "isActive": True,
            })
            student_rec = await db.student.create(data={
                "userId": user_rec.id, "enrollmentNumber": s["enroll"],
                "firstName": s["firstName"], "lastName": s["lastName"],
                "semester": 4, "batch": "2026", "gender": s["gender"],
                "departmentId": depts[s["dept_code"]].id,
            })
            students[s["enroll"]] = student_rec
        except Exception as err:
            logger.error("Failed to seed student %s: %s", s["email"], err, exc_info=True)
            raise err
    return students


async def seed_academic_classes(subs: dict, rooms: dict, teachers: dict) -> dict:
    classes_data = [
        {"name": "CSE-DSA-4A", "sub_code": "CS101", "room_name": "Lab 1", "teacher_emp": "T001", "semester": 4, "batch": "2026"},
        {"name": "IT-WEBDEV-4B", "sub_code": "CS102", "room_name": "Seminar Hall 1", "teacher_emp": "T003", "semester": 4, "batch": "2026"},
        {"name": "ECE-DE-4C", "sub_code": "EC101", "room_name": "Room 301", "teacher_emp": "T005", "semester": 4, "batch": "2026"},
    ]
    classes = {}
    for cls in classes_data:
        try:
            class_rec = await db.academicclass.create(data={
                "name": cls["name"], "subjectId": subs[cls["sub_code"]].id,
                "classroomId": rooms[cls["room_name"]].id,
                "teacherId": teachers[cls["teacher_emp"]].id,
                "semester": cls["semester"], "batch": cls["batch"], "maxStudents": 40,
            })
            classes[cls["name"]] = class_rec
        except Exception as err:
            logger.error("Failed to seed class %s: %s", cls["name"], err, exc_info=True)
            raise err
    return classes


async def seed_geofences(classes: dict) -> None:
    for name, cls_rec in classes.items():
        try:
            await db.geofence.create(data={
                "academicClassId": cls_rec.id, "latitude": 19.0760,
                "longitude": 72.8777, "radiusMeters": 100.0,
            })
        except Exception as err:
            logger.error("Failed to seed geofence for %s: %s", name, err, exc_info=True)
            raise err


async def seed_enrollments(students: dict, classes: dict) -> None:
    try:
        cse = classes["CSE-DSA-4A"]
        it = classes["IT-WEBDEV-4B"]
        ece = classes["ECE-DE-4C"]
        for enroll_no in ["S001", "S002"]:
            await db.enrollment.create(data={"studentId": students[enroll_no].id, "academicClassId": cse.id})
            await db.enrollment.create(data={"studentId": students[enroll_no].id, "academicClassId": it.id})
        for enroll_no in ["S003", "S004"]:
            await db.enrollment.create(data={"studentId": students[enroll_no].id, "academicClassId": it.id})
        await db.enrollment.create(data={"studentId": students["S005"].id, "academicClassId": ece.id})
    except Exception as err:
        logger.error("Failed to seed enrollments: %s", err, exc_info=True)
        raise err


async def seed_active_sessions(classes: dict) -> None:
    now = datetime.now(timezone.utc)
    end = now + timedelta(hours=1)
    for name, cls_rec in classes.items():
        try:
            await db.session.create(data={
                "academicClassId": cls_rec.id, "startTime": now, "endTime": end, "isActive": True,
            })
        except Exception as err:
            logger.error("Failed to seed session for %s: %s", name, err, exc_info=True)
            raise err


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
        raise err
    finally:
        await disconnect_db()


if __name__ == "__main__":
    asyncio.run(seed_all())
