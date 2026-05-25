import asyncio
import logging
import sys
import os
from datetime import datetime, timedelta, timezone

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.db.client import db, connect_db, disconnect_db
from app.core.security import hash_password

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("prisma.seed")

async def main() -> None:
    logger.info("Connecting to the database for seeding operations...")
    await connect_db()

    try:
        # Clear existing data first in reverse dependency order
        logger.info("Clearing existing database tables...")
        await db.attendance.delete_many()
        await db.enrollment.delete_many()
        await db.session.delete_many()
        await db.geofence.delete_many()
        await db.academicclass.delete_many()
        await db.teacher.delete_many()
        await db.student.delete_many()
        await db.user.delete_many()
        await db.department.delete_many()
        await db.subject.delete_many()
        await db.classroom.delete_many()
        await db.designation.delete_many()

        # 1. Admin User Seeding (Indian Origin Name Concept in logging, standard email)
        default_admin_email = "admin@example.com"
        default_admin_pass = "admin123"
        hashed_admin = hash_password(default_admin_pass)

        logger.info(f"Creating default admin account: {default_admin_email}...")
        admin_user = await db.user.create(
            data={
                "email": default_admin_email,
                "hashedPassword": hashed_admin,
                "role": "ADMIN",
                "isActive": True
            }
        )
        logger.info(f"Created Admin user: {admin_user.email}")

        # 2. Departments Seeding
        departments_data = [
            {"name": "Computer Science & Engineering", "code": "CSE", "head": "Dr. Ramesh Sharma", "description": "Department of CSE"},
            {"name": "Information Technology", "code": "IT", "head": "Dr. Anita Roy", "description": "Department of IT"},
        ]

        logger.info("Seeding departments...")
        depts = {}
        for dept in departments_data:
            record = await db.department.create(data=dept)
            depts[dept["code"]] = record
            logger.info(f"Seeded Department: {dept['code']}")

        # 3. Subjects Seeding
        subjects_data = [
            {"name": "Data Structures & Algorithms", "code": "CS101", "description": "Fundamental course on data structures"},
            {"name": "Web Development", "code": "CS102", "description": "Full stack web development basics"},
        ]

        logger.info("Seeding subjects...")
        subs = {}
        for sub in subjects_data:
            record = await db.subject.create(data=sub)
            subs[sub["code"]] = record
            logger.info(f"Seeded Subject: {sub['code']}")

        # 4. Classrooms Seeding
        classrooms_data = [
            {"name": "Lab 1", "building": "Block A", "capacity": 40},
            {"name": "Seminar Hall 1", "building": "Block B", "capacity": 120},
        ]

        logger.info("Seeding classrooms...")
        rooms = {}
        for room in classrooms_data:
            record = await db.classroom.create(data=room)
            rooms[room["name"]] = record
            logger.info(f"Seeded Classroom: {room['name']}")

        # 5. Designations Seeding
        designations_data = [
            {"name": "Professor", "code": "PROF", "description": "Senior faculty head position"},
            {"name": "Assistant Professor", "code": "ASST", "description": "Entry-level tenure faculty"},
        ]

        logger.info("Seeding designations...")
        desigs = {}
        for desig in designations_data:
            record = await db.designation.create(data=desig)
            desigs[desig["code"]] = record
            logger.info(f"Seeded Designation: {desig['code']}")

        # 6. Teachers Seeding (Indian Names)
        teachers_data = [
            {
                "email": "rajesh@example.com",
                "password": "teacher123",
                "firstName": "Rajesh",
                "lastName": "Kumar",
                "employeeId": "T001",
                "dept_code": "CSE",
                "desig_code": "PROF"
            },
            {
                "email": "anita@example.com",
                "password": "teacher123",
                "firstName": "Anita",
                "lastName": "Roy",
                "employeeId": "T002",
                "dept_code": "IT",
                "desig_code": "ASST"
            }
        ]

        logger.info("Seeding Teachers...")
        teachers = {}
        for teacher in teachers_data:
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

        # 7. Students Seeding (Indian Names, Short Enrollment Numbers)
        students_data = [
            {"email": "aarav@example.com", "firstName": "Aarav", "lastName": "Patel", "enroll": "S001", "dept_code": "CSE", "gender": "MALE"},
            {"email": "priya@example.com", "firstName": "Priya", "lastName": "Sharma", "enroll": "S002", "dept_code": "CSE", "gender": "FEMALE"},
            {"email": "rahul@example.com", "firstName": "Rahul", "lastName": "Verma", "enroll": "S003", "dept_code": "CSE", "gender": "MALE"},
            {"email": "sneha@example.com", "firstName": "Sneha", "lastName": "Gupta", "enroll": "S004", "dept_code": "IT", "gender": "FEMALE"},
            {"email": "amit@example.com", "firstName": "Amit", "lastName": "Singh", "enroll": "S005", "dept_code": "IT", "gender": "MALE"},
        ]

        logger.info("Seeding Students...")
        students = {}
        for student in students_data:
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

        # 8. Academic Classes Seeding
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
                "teacher_emp": "T002",
                "semester": 4,
                "batch": "2026"
            }
        ]

        logger.info("Seeding Academic Classes...")
        classes = {}
        for cls in classes_data:
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

        # 9. Geofences Seeding
        logger.info("Seeding Geofences...")
        for name, cls_rec in classes.items():
            await db.geofence.create(
                data={
                    "academicClassId": cls_rec.id,
                    "latitude": 19.0760,
                    "longitude": 72.8777,
                    "radiusMeters": 100.0
                }
            )
            logger.info(f"Seeded Geofence for class: {name}")

        # 10. Enrollments Seeding
        logger.info("Seeding Student Enrollments...")
        # CSE class has Aarav, Priya, Rahul
        cse_class = classes["CSE-DSA-4A"]
        for enroll_no in ["S001", "S002", "S003"]:
            await db.enrollment.create(
                data={
                    "studentId": students[enroll_no].id,
                    "academicClassId": cse_class.id
                }
            )
        
        # IT class has Sneha, Amit
        it_class = classes["IT-WEBDEV-4B"]
        for enroll_no in ["S004", "S005"]:
            await db.enrollment.create(
                data={
                    "studentId": students[enroll_no].id,
                    "academicClassId": it_class.id
                }
            )
        logger.info("Successfully enrolled students.")

        # 11. Sessions Seeding (1 active session per class for easy UI testing)
        logger.info("Seeding active Class Sessions...")
        now = datetime.now(timezone.utc)
        end = now + timedelta(hours=1)
        
        for name, cls_rec in classes.items():
            await db.session.create(
                data={
                    "academicClassId": cls_rec.id,
                    "startTime": now,
                    "endTime": end,
                    "isActive": True
                }
            )
            logger.info(f"Seeded Active Session for class: {name}")

        logger.info("Database seeding completed successfully.")

    except Exception as err:
        logger.error(f"Failed database seeding execution: {err}", exc_info=True)
        raise err
    finally:
        logger.info("Disconnecting from the database...")
        await disconnect_db()


if __name__ == "__main__":
    asyncio.run(main())
