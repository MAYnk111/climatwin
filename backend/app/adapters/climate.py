from typing import List, Optional
from app.adapters.base import BaseAdapter, BaseDataRecord


class ClimateHazardAdapter(BaseAdapter):
    """Adapter for climate events and geospatial hazard feeds."""

    def __init__(self, api_key: Optional[str] = None):
        super().__init__(
            source_name="Open-Meteo / Global Hazard Feed",
            source_uri="https://api.open-meteo.com/v1/forecast",
        )
        self.api_key = api_key
        self.is_connected = False  # Mark unverified until actual credentials/integration verified

    async def fetch(self, region_code: Optional[str] = None, **kwargs) -> List[BaseDataRecord]:
        """Fetches hazard data. If integration is not yet connected/configured, returns empty list with status."""
        if not self.is_connected:
            # Integration stub awaiting live API connection/keys
            return []
        return []
