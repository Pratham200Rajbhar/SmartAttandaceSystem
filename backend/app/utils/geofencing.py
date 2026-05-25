import math

from dataclasses import dataclass

@dataclass(frozen=True)

class GPSCoordinate:

    latitude: float

    longitude: float

def calculate_haversine_distance(

    coord_a: GPSCoordinate,

    coord_b: GPSCoordinate

) -> float:

    earth_radius = 6371000.0

    lat_rad_a = math.radians(coord_a.latitude)

    lat_rad_b = math.radians(coord_b.latitude)

    delta_lat = math.radians(coord_b.latitude - coord_a.latitude)

    delta_lon = math.radians(coord_b.longitude - coord_a.longitude)

    haversine_term = (

        math.sin(delta_lat / 2.0) ** 2 +

        math.cos(lat_rad_a) * math.cos(lat_rad_b) * (math.sin(delta_lon / 2.0) ** 2)

    )

    angular_distance = 2.0 * math.atan2(

        math.sqrt(haversine_term),

        math.sqrt(1.0 - haversine_term)

    )

    return earth_radius * angular_distance

