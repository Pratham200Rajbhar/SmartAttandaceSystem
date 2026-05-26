
import json
from app.core.logging_config import get_logger
from typing import Dict, Set, Optional
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.api.dependencies import get_current_user_from_token

logger = get_logger("app.websocket")

router = APIRouter(prefix="/ws", tags=["WebSocket"])

class ConnectionManager:

    def __init__(self):

        self.student_connections: Dict[str, Set[WebSocket]] = {}

        self.teacher_connections: Dict[str, Set[WebSocket]] = {}

    async def connect_student(self, websocket: WebSocket, student_id: str):

        await websocket.accept()

        if student_id not in self.student_connections:

            self.student_connections[student_id] = set()

        self.student_connections[student_id].add(websocket)

        logger.info("WebSocket student connected: %s", student_id)

    async def connect_teacher(self, websocket: WebSocket, teacher_id: str):

        await websocket.accept()

        if teacher_id not in self.teacher_connections:

            self.teacher_connections[teacher_id] = set()

        self.teacher_connections[teacher_id].add(websocket)

        logger.info("WebSocket teacher connected: %s", teacher_id)

    def disconnect(self, websocket: WebSocket, user_type: str, user_id: str):

        connections = self.student_connections if user_type == "student" else self.teacher_connections

        if user_id in connections:

            connections[user_id].discard(websocket)

            if not connections[user_id]:

                del connections[user_id]

        logger.info("WebSocket %s disconnected: %s", user_type, user_id)

    async def send_personal_message(self, message: dict, student_id: str):

        if student_id not in self.student_connections:

            return

        disconnected = set()

        for connection in self.student_connections[student_id]:

            try:

                await connection.send_json(message)

            except Exception as e:

                logger.warning("Failed to send message to %s: %s", student_id, e)

                disconnected.add(connection)

        for conn in disconnected:

            self.student_connections[student_id].discard(conn)

    async def broadcast_to_teachers(self, message: dict):

        disconnected = set()
        for teacher_id, conns in self.teacher_connections.items():
            for conn in conns:
                try:
                    await conn.send_json(message)
                except Exception as e:
                    logger.warning("Failed to send to teacher %s: %s", teacher_id, e)
                    disconnected.add(conn)

        for conn in disconnected:
            for teacher_id, conns in self.teacher_connections.items():
                conns.discard(conn)
                if not conns:
                    del self.teacher_connections[teacher_id]

    async def broadcast_to_class(self, message: dict, student_ids: list[str]):

        for student_id in student_ids:

            await self.send_personal_message(message, student_id)

manager = ConnectionManager()

@router.websocket("/connect")

async def websocket_endpoint(

    websocket: WebSocket,

):

    try:

        await websocket.accept()

        auth_data = await websocket.receive_text()
        auth_json = json.loads(auth_data)

        if auth_json.get("type") != "auth" or not auth_json.get("token"):
            await websocket.close(code=1008, reason="Authentication required")
            return

        token = auth_json["token"]
        user = await get_current_user_from_token(token)

        if not user:
            await websocket.close(code=1008, reason="Unauthorized")
            return

        if user.role == "STUDENT" and user.student:

            student_id = user.student.id
            await manager.connect_student(websocket, student_id)
            await websocket.send_json({
                "type": "connected",
                "message": "WebSocket connection established",
                "user_id": student_id,
                "role": "student"
            })

            try:
                while True:
                    await websocket.receive_text()
            except WebSocketDisconnect:
                manager.disconnect(websocket, "student", student_id)

        elif user.role == "TEACHER" and user.teacher:

            teacher_id = user.teacher.id
            await manager.connect_teacher(websocket, teacher_id)
            await websocket.send_json({
                "type": "connected",
                "message": "WebSocket connection established",
                "user_id": teacher_id,
                "role": "teacher"
            })

            try:
                while True:
                    await websocket.receive_text()
            except WebSocketDisconnect:
                manager.disconnect(websocket, "teacher", teacher_id)

        else:
            await websocket.close(code=1008, reason="Unauthorized: Student or Teacher profile required")

    except Exception as e:

        logger.error("WebSocket error: %s", e, exc_info=True)

        try:

            await websocket.close(code=1011, reason="Internal server error")

        except Exception:

            pass

def get_connection_manager() -> ConnectionManager:

    return manager

