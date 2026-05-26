
from app.core.logging_config import get_logger
import os
from typing import List, Optional

logger = get_logger("app.fcm")

try:

    import firebase_admin

    from firebase_admin import credentials, messaging

    cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")

    if os.path.exists(cred_path):

        cred = credentials.Certificate(cred_path)

        firebase_admin.initialize_app(cred)

        pass

    else:

        logger.warning("FCM credentials not found at %s", cred_path)

        FCM_ENABLED = False

except Exception as e:

    logger.error("Failed to initialize Firebase Admin SDK: %s", e, exc_info=True)

    FCM_ENABLED = False

class FCMService:

    @staticmethod

    async def send_notification(

        token: str,

        title: str,

        body: str,

        data: Optional[dict] = None

    ) -> bool:

        if not FCM_ENABLED:

            logger.warning("FCM is disabled. Skipping notification.")

            return False

        try:

            message = messaging.Message(

                notification=messaging.Notification(

                    title=title,

                    body=body,

                ),

                data=data or {},

                token=token,

            )

            messaging.send(message)

            return True

        except Exception as e:

            logger.error("FCM notification failed: %s", e, exc_info=True)

            return False

    @staticmethod

    async def send_multicast(

        tokens: List[str],

        title: str,

        body: str,

        data: Optional[dict] = None

    ) -> int:

        if not FCM_ENABLED:

            logger.warning("FCM is disabled. Skipping multicast.")

            return 0

        try:

            message = messaging.MulticastMessage(

                notification=messaging.Notification(

                    title=title,

                    body=body,

                ),

                data=data or {},

                tokens=tokens,

            )

            response = messaging.send_multicast(message)

            return response.success_count

        except Exception as e:

            logger.error("FCM multicast failed: %s", e, exc_info=True)

            return 0

    @staticmethod

    async def send_attendance_notification(token: str, class_name: str, status: str, attendance_id: str):

        return await FCMService.send_notification(

            token=token,

            title="Attendance Marked ✅",

            body=f"Your attendance for {class_name} has been marked as {status}.",

            data={

                "type": "attendance_marked",

                "attendance_id": attendance_id,

                "status": status,

            }

        )

    @staticmethod

    async def send_leave_status_notification(token: str, status: str, leave_id: str, start_date: str, end_date: str):

        emoji = "✅" if status == "APPROVED" else "❌"

        return await FCMService.send_notification(

            token=token,

            title=f"Leave {status.title()} {emoji}",

            body=f"Your leave request from {start_date} to {end_date} has been {status.lower()}.",

            data={

                "type": f"leave_{status.lower()}",

                "leave_id": leave_id,

                "status": status,

            }

        )

    @staticmethod

    async def send_at_risk_warning(token: str, percentage: float):

        return await FCMService.send_notification(

            token=token,

            title="Attendance Alert ⚠️",

            body=f"Your attendance is {percentage:.1f}% (below 75%). Please improve your attendance to avoid academic issues.",

            data={

                "type": "at_risk_warning",

                "attendance_percentage": str(percentage),

            }

        )

    @staticmethod

    async def send_dispute_resolved_notification(token: str, status: str, attendance_id: str):

        emoji = "✅" if status == "RESOLVED" else "❌"

        return await FCMService.send_notification(

            token=token,

            title=f"Dispute {status.title()} {emoji}",

            body=f"Your dispute has been {status.lower()}. Check the details in the app.",

            data={

                "type": "dispute_resolved",

                "attendance_id": attendance_id,

                "status": status,

            }

        )

