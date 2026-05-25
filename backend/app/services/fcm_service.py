"""
Firebase Cloud Messaging service for push notifications.
"""
import logging
import os
from typing import List, Optional

logger = logging.getLogger("app.fcm")

# Try to initialize Firebase Admin SDK
try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    
    cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        logger.info("✅ Firebase Admin SDK initialized successfully")
        FCM_ENABLED = True
    else:
        logger.warning(f"⚠️ Firebase credentials not found at {cred_path}. FCM disabled.")
        FCM_ENABLED = False
except Exception as e:
    logger.error(f"❌ Failed to initialize Firebase Admin SDK: {e}")
    FCM_ENABLED = False


class FCMService:
    """Firebase Cloud Messaging service for push notifications."""
    
    @staticmethod
    async def send_notification(
        token: str,
        title: str,
        body: str,
        data: Optional[dict] = None
    ) -> bool:
        """Send push notification to a single device."""
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
            
            response = messaging.send(message)
            logger.info(f"✅ FCM notification sent: {response}")
            return True
        except Exception as e:
            logger.error(f"❌ FCM notification failed: {e}")
            return False
    
    @staticmethod
    async def send_multicast(
        tokens: List[str],
        title: str,
        body: str,
        data: Optional[dict] = None
    ) -> int:
        """Send push notification to multiple devices."""
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
            logger.info(f"✅ FCM multicast sent: {response.success_count}/{len(tokens)} successful")
            return response.success_count
        except Exception as e:
            logger.error(f"❌ FCM multicast failed: {e}")
            return 0
    
    @staticmethod
    async def send_attendance_notification(token: str, class_name: str, status: str, attendance_id: str):
        """Send attendance marked notification."""
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
        """Send leave approval/rejection notification."""
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
        """Send at-risk warning notification."""
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
        """Send dispute resolution notification."""
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
