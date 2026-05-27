import asyncio
import json
from typing import Dict, Set

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.api.dependencies import get_current_user_from_token
from app.core.logging_config import get_logger

logger = get_logger("app.websocket")

router = APIRouter(prefix="/ws", tags=["WebSocket"])

_PING_INTERVAL = 25
_PONG_TIMEOUT = 15


class ConnectionManager:
    def __init__(self):
        self.student_connections: Dict[str, Set[WebSocket]] = {}
        self.teacher_connections: Dict[str, Set[WebSocket]] = {}
        self._heartbeat_task: asyncio.Task | None = None

    async def connect_student(self, websocket: WebSocket, student_id: str):
        await websocket.accept()
        self.student_connections.setdefault(student_id, set()).add(websocket)
        logger.info("WebSocket student connected: %s", student_id)

    async def connect_teacher(self, websocket: WebSocket, teacher_id: str):
        await websocket.accept()
        self.teacher_connections.setdefault(teacher_id, set()).add(websocket)
        logger.info("WebSocket teacher connected: %s", teacher_id)

    def disconnect(self, websocket: WebSocket, user_type: str, user_id: str):
        connections = self.student_connections if user_type == "student" else self.teacher_connections
        if user_id in connections:
            connections[user_id].discard(websocket)
            if not connections[user_id]:
                del connections[user_id]
        logger.info("WebSocket %s disconnected: %s", user_type, user_id)

    async def send_personal_message(self, message: dict, student_id: str):
        conns = self.student_connections.get(student_id)
        if not conns:
            return
        disconnected = set()
        for connection in conns:
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

    async def _heartbeat_loop(self):
        while True:
            await asyncio.sleep(_PING_INTERVAL)
            ping = {"type": "ping"}
            disconnected = set()

            for sid, conns in list(self.student_connections.items()):
                for conn in list(conns):
                    try:
                        await asyncio.wait_for(
                            conn.send_json(ping), timeout=_PONG_TIMEOUT
                        )
                    except Exception:
                        disconnected.add((conn, "student", sid))

            for tid, conns in list(self.teacher_connections.items()):
                for conn in list(conns):
                    try:
                        await asyncio.wait_for(
                            conn.send_json(ping), timeout=_PONG_TIMEOUT
                        )
                    except Exception:
                        disconnected.add((conn, "teacher", tid))

            for conn, utype, uid in disconnected:
                self.disconnect(conn, utype, uid)

            if disconnected:
                logger.info(
                    "Heartbeat cleaned %d stale connections", len(disconnected)
                )

    def start_heartbeat(self):
        if self._heartbeat_task is None:
            self._heartbeat_task = asyncio.create_task(self._heartbeat_loop())
            logger.info("WebSocket heartbeat started")

    def stop_heartbeat(self):
        if self._heartbeat_task is not None:
            self._heartbeat_task.cancel()
            self._heartbeat_task = None
            logger.info("WebSocket heartbeat stopped")

    @property
    def total_connections(self) -> int:
        student_count = sum(len(c) for c in self.student_connections.values())
        teacher_count = sum(len(c) for c in self.teacher_connections.values())
        return student_count + teacher_count

manager = ConnectionManager()


@router.websocket("/connect")
async def websocket_endpoint(websocket: WebSocket):
    try:
        await websocket.accept()
        auth_data = await websocket.receive_text()
        auth_json = json.loads(auth_data)

        if auth_json.get("type") != "auth" or not auth_json.get("token"):
            await websocket.close(code=1008, reason="Authentication required")
            return

        user = await get_current_user_from_token(auth_json["token"])
        if not user:
            await websocket.close(code=1008, reason="Unauthorized")
            return

        if user.role == "STUDENT" and user.student:
            student_id = user.student.id
            await manager.connect_student(websocket, student_id)
            await websocket.send_json({"type": "connected", "message": "WebSocket connection established", "user_id": student_id, "role": "student"})
            try:
                while True:
                    data = await asyncio.wait_for(websocket.receive_text(), timeout=_PING_INTERVAL)
                    if data == "ping":
                        await websocket.send_json({"type": "pong"})
            except asyncio.TimeoutError:
                logger.info("WebSocket ping timeout for student %s", student_id)
            except WebSocketDisconnect:
                manager.disconnect(websocket, "student", student_id)

        elif user.role == "TEACHER" and user.teacher:
            teacher_id = user.teacher.id
            await manager.connect_teacher(websocket, teacher_id)
            await websocket.send_json({"type": "connected", "message": "WebSocket connection established", "user_id": teacher_id, "role": "teacher"})
            try:
                while True:
                    data = await asyncio.wait_for(websocket.receive_text(), timeout=_PING_INTERVAL)
                    if data == "ping":
                        await websocket.send_json({"type": "pong"})
            except asyncio.TimeoutError:
                logger.info("WebSocket ping timeout for teacher %s", teacher_id)
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


