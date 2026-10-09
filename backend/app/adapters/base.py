from abc import ABC, abstractmethod
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class SourceAttribution(BaseModel):
    source_name: str
    source_uri: Optional[str] = None
    retrieved_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
    reliability_score: float = Field(default=1.0, ge=0.0, le=1.0)
    data_vintage: Optional[str] = None


class BaseDataRecord(BaseModel):
    record_id: str
    record_type: str
    attribution: SourceAttribution
    payload: Dict[str, Any]
    status: str = "verified"


class BaseAdapter(ABC):
    """Abstract base class for all external data adapters with attribution and timestamps."""

    def __init__(self, source_name: str, source_uri: Optional[str] = None):
        self.source_name = source_name
        self.source_uri = source_uri

    def create_attribution(
        self, reliability_score: float = 1.0, data_vintage: Optional[str] = None
    ) -> SourceAttribution:
        return SourceAttribution(
            source_name=self.source_name,
            source_uri=self.source_uri,
            reliability_score=reliability_score,
            data_vintage=data_vintage,
        )

    @abstractmethod
    async def fetch(self, **kwargs) -> List[BaseDataRecord]:
        """Fetch and normalize records with complete attribution and timestamps."""
        pass
