import asyncio
from typing import Optional

from app.core.logging_config import get_logger

logger = get_logger("app.notification")

try:
    import firebase_admin
    from firebase_admin import credentials, messaging

    _cred_path = "firebase-credentials.json"
    try:
        if not firebase_admin._apps:
            cred = credentials.Certificate(_cred_path)
            firebase_admin.initialize_app(cred)
        _fcm_available = True
        logger.info("Firebase Admin SDK initialized successfully")
    except Exception as e:
        _fcm_available = False
        logger.warning("Firebase Admin SDK not available: %s. Push notifications disabled.", e)

except ImportError:
    _fcm_available = False
    logger.info("firebase-admin not installed. Push notifications disabled.")


async def send_push_notification(token: str, title: str, body: str, data: Optional[dict] = None) -> bool:
    if not _fcm_available or not token:
        return False

    try:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            token=token,
        )
        response = await asyncio.to_thread(messaging.send, message)
        logger.info("FCM sent: %s", response)
        return True
    except Exception as e:
        logger.warning("FCM send failed: %s", e)
        return False


async def notify_student_attendance_flagged(student_fcm_token: str, student_name: str, class_name: str, attendance_id: str):
    await send_push_notification(
        token=student_fcm_token,
        title="Attendance Flagged",
        body=f"Hi {student_name}, your attendance for {class_name} has been flagged and requires review.",
        data={"route": "/flagged_detail", "attendance_id": attendance_id},
    )


async def notify_student_attendance_reviewed(student_fcm_token: str, status: str, class_name: str):
    await send_push_notification(
        token=student_fcm_token,
        title=f"Attendance {status}",
        body=f"Your attendance for {class_name} has been reviewed and marked as {status}.",
        data={"route": "/history"},
    )


async def notify_student_leave_status(student_fcm_token: str, status: str):
    await send_push_notification(
        token=student_fcm_token,
        title=f"Leave {status}",
        body=f"Your leave request has been {status.lower()}.",
        data={"route": "/leave/history"},
    )
