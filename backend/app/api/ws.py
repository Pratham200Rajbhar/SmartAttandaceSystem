"""
WebSocket endpoint for real-time attendance updates.
Broadcasts session status changes and attendance notifications to connected students.
"""
import logging
from typing import Dict, Set
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from app.api.dependencies import get_current_user_from_token

logger = logging.getLogger("app.websocket")

router = APIRouter(prefix="/ws", tags=["WebSocket"])


class ConnectionManager:
    """Manages WebSocket connections mapped by student ID."""
    
    def __init__(self):
        # Map: student_id -> Set of WebSocket connections
        self.active_connections: Dict[str, Set[WebSocket]] = {}
    
    async def connect(self, websocket: WebSocket, student_id: str):
        """Accept and register a new WebSocket connection."""
        await websocket.accept()
        if student_id not in self.active_connections:
            self.active_connections[student_id] = set()
        self.active_connections[student_id].add(websocket)
        logger.info(f"✅ WebSocket connected: student_id={student_id}, total={len(self.active_connections[student_id])}")
    
    def disconnect(self, websocket: WebSocket, student_id: str):
        """Remove a WebSocket connection."""
        if student_id in self.active_connections:
            self.active_connections[student_id].discard(websocket)
            if not self.active_connections[student_id]:
                del self.active_connections[student_id]
        logger.info(f"❌ WebSocket disconnected: student_id={student_id}")
    
    async def send_personal_message(self, message: dict, student_id: str):
        """Send a message to all connections of a specific student."""
        if student_id not in self.active_connections:
            return
        
        disconnected = set()
        for connection in self.active_connections[student_id]:
            try:
                await connection.send_json(message)
            except Exception as e:
                logger.warning(f"Failed to send message to {student_id}: {e}")
                disconnected.add(connection)
        
        # Clean up dead connections
        for conn in disconnected:
            self.active_connections[student_id].discard(conn)
    
    async def broadcast_to_class(self, message: dict, student_ids: list[str]):
        """Broadcast a message to multiple students (e.g., all enrolled in a class)."""
        for student_id in student_ids:
            await self.send_personal_message(message, student_id)


# Global connection manager instance
manager = ConnectionManager()


@router.websocket("/connect")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(..., description="JWT token for authentication")
):
    """
    WebSocket endpoint for real-time updates.
    Client must provide JWT token as query parameter: /ws/connect?token=<jwt>
    """
    try:
        # Authenticate the user from token
        user = await get_current_user_from_token(token)
        
        if not user or not user.student:
            await websocket.close(code=1008, reason="Unauthorized: Student profile required")
            return
        
        student_id = user.student.id
        await manager.connect(websocket, student_id)
        
        # Send welcome message
        await websocket.send_json({
            "type": "connected",
            "message": "WebSocket connection established",
            "student_id": student_id
        })
        
        # Keep connection alive and listen for client messages (optional)
        try:
            while True:
                data = await websocket.receive_text()
                # Echo back for heartbeat/ping-pong
                await websocket.send_json({
                    "type": "pong",
                    "received": data
                })
        except WebSocketDisconnect:
            manager.disconnect(websocket, student_id)
    
    except Exception as e:
        logger.error(f"WebSocket error: {e}", exc_info=True)
        try:
            await websocket.close(code=1011, reason="Internal server error")
        except Exception:
            pass


def get_connection_manager() -> ConnectionManager:
    """Dependency to get the global connection manager."""
    return manager
