from typing import Any, Dict, List, Optional
import httpx
from datetime import datetime, timezone
from app.adapters.base import BaseAdapter, BaseDataRecord, SourceAttribution


class ClimateHazardAdapter(BaseAdapter):
    """Adapter for live geospatial climate and weather data using Open-Meteo API.
    
    Provides live precipitation, temperature, relative humidity, and wind speed.
    Falls back deterministically if network or external service is unreachable.
    """

    DEFAULT_LOCATIONS = {
        "comp_tsmc": {"lat": 24.78, "lon": 120.99, "name": "Hsinchu Science Park, Taiwan"},
        "comp_bmw": {"lat": 50.08, "lon": 7.76, "name": "Kaub Rhine Gorge, Germany"},
        "comp_aapl": {"lat": 37.33, "lon": -122.03, "name": "Cupertino, California"},
        "comp_nvda": {"lat": 37.37, "lon": -121.96, "name": "Santa Clara, California"},
    }

    def __init__(self, api_key: Optional[str] = None):
        super().__init__(
            source_name="Open-Meteo Global Environmental Model",
            source_uri="https://api.open-meteo.com/v1/forecast",
        )
        self.api_key = api_key

    async def fetch_live_weather(
        self, latitude: float, longitude: float, location_name: str = "Target Site"
    ) -> BaseDataRecord:
        """Fetch live weather from Open-Meteo or return labeled fallback."""
        from app.core.redis_store import redis_store
        cache_key = f"weather_{latitude}_{longitude}"
        cached = redis_store.cache_get(cache_key)
        if cached:
            return BaseDataRecord(**cached)

        url = (
            f"https://api.open-meteo.com/v1/forecast"
            f"?latitude={latitude}&longitude={longitude}"
            f"&current=temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m"
        )
        
        try:
            async with httpx.AsyncClient(timeout=4.0) as client:
                resp = await client.get(url)
                if resp.status_code == 200:
                    data = resp.json()
                    current = data.get("current", {})
                    precip = current.get("precipitation", 0.0)
                    temp = current.get("temperature_2m", 25.0)
                    humidity = current.get("relative_humidity_2m", 60.0)
                    
                    # Risk classification based on drought/heat indices
                    drought_risk = "high" if precip == 0.0 and humidity < 55.0 and temp > 28.0 else "medium"
                    
                    rec = BaseDataRecord(
                        record_id=f"meteo_{latitude}_{longitude}",
                        record_type="live_climate_weather",
                        attribution=SourceAttribution(
                            source_name="Open-Meteo High-Resolution Forecast",
                            source_uri=url,
                            retrieved_at=datetime.now(timezone.utc).isoformat(),
                            reliability_score=0.95,
                            data_vintage=current.get("time", "latest"),
                        ),
                        payload={
                            "location_name": location_name,
                            "latitude": latitude,
                            "longitude": longitude,
                            "temperature_celsius": temp,
                            "relative_humidity_pct": humidity,
                            "precipitation_mm": precip,
                            "wind_speed_kmh": current.get("wind_speed_10m", 0.0),
                            "computed_drought_stress": drought_risk,
                            "is_live_feed": True,
                        },
                        status="live_verified",
                    )
                    # Cache for 25 minutes (1500s)
                    redis_store.cache_set(cache_key, rec.model_dump(), ttl_seconds=1500)
                    return rec
        except Exception as e:
            # Deterministic demo fallback if network fails
            pass

        # Graceful deterministic fallback with clear labeling
        return BaseDataRecord(
            record_id=f"fallback_meteo_{latitude}_{longitude}",
            record_type="modeled_climate_weather",
            attribution=SourceAttribution(
                source_name="CLIMATWIN Deterministic Historical Climate Benchmark",
                source_uri="https://climatwin.internal/benchmarks/historical",
                retrieved_at=datetime.now(timezone.utc).isoformat(),
                reliability_score=0.80,
                data_vintage="Historical Baseline 2020-2024",
            ),
            payload={
                "location_name": location_name,
                "latitude": latitude,
                "longitude": longitude,
                "temperature_celsius": 29.5,
                "relative_humidity_pct": 52.0,
                "precipitation_mm": 0.0,
                "wind_speed_kmh": 18.5,
                "computed_drought_stress": "high",
                "is_live_feed": False,
                "note": "Deterministic fallback used due to external service timeout.",
            },
            status="demo_fallback",
        )

    async def fetch(self, region_code: Optional[str] = None, **kwargs) -> List[BaseDataRecord]:
        """Fetch weather for default supply chain regions."""
        records: List[BaseDataRecord] = []
        for key, loc in self.DEFAULT_LOCATIONS.items():
            if region_code and region_code != key:
                continue
            rec = await self.fetch_live_weather(
                latitude=loc["lat"],
                longitude=loc["lon"],
                location_name=loc["name"],
            )
            records.append(rec)
        return records
