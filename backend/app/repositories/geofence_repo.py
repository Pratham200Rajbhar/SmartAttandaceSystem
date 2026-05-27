from prisma.models import Geofence
from app.db.client import db


class GeofenceRepository:
    async def get_by_class_id(self, class_id: str) -> Geofence | None:
        return await db.geofence.find_unique(where={"academicClassId": class_id})

    async def upsert_geofence(self, class_id: str, latitude: float, longitude: float, radius: float) -> Geofence:
        existing = await self.get_by_class_id(class_id)
        if existing:
            return await db.geofence.update(
                where={"academicClassId": class_id},
                data={"latitude": latitude, "longitude": longitude, "radiusMeters": radius},
            )
        return await db.geofence.create(
            data={"academicClassId": class_id, "latitude": latitude, "longitude": longitude, "radiusMeters": radius}
        )
