from typing import Any, Dict, List, Optional
import httpx
from datetime import datetime, timezone
from app.adapters.base import BaseAdapter, BaseDataRecord, SourceAttribution


class MarketPortfolioAdapter(BaseAdapter):
    """Adapter for financial market rates, live FX rates, and portfolio valuations.
    
    Provides live USD/INR FX rates from open currency exchange rate API.
    Tracks currency, timestamp, source attribution, and distinguishes live vs fallback.
    """

    BENCHMARK_USD_INR = 83.50

    def __init__(self, api_key: Optional[str] = None):
        super().__init__(
            source_name="Open Exchange Rates & Global Market Feeds",
            source_uri="https://open.er-api.com/v6/latest/USD",
        )
        self.api_key = api_key

    async def fetch_live_fx_rate(self) -> BaseDataRecord:
        """Fetches live USD/INR exchange rate with full attribution."""
        from app.core.redis_store import redis_store
        cached = redis_store.cache_get("fx_usd_inr")
        if cached:
            return BaseDataRecord(**cached)

        url = "https://open.er-api.com/v6/latest/USD"
        try:
            async with httpx.AsyncClient(timeout=4.0) as client:
                resp = await client.get(url)
                if resp.status_code == 200:
                    data = resp.json()
                    rates = data.get("rates", {})
                    inr_rate = rates.get("INR")
                    if inr_rate:
                        rec = BaseDataRecord(
                            record_id="fx_usd_inr_live",
                            record_type="live_fx_quote",
                            attribution=SourceAttribution(
                                source_name="Open Exchange Rates Service",
                                source_uri=url,
                                retrieved_at=datetime.now(timezone.utc).isoformat(),
                                reliability_score=0.99,
                                data_vintage=data.get("time_last_update_utc", "latest"),
                            ),
                            payload={
                                "base_currency": "USD",
                                "target_currency": "INR",
                                "exchange_rate": round(float(inr_rate), 4),
                                "is_live_rate": True,
                                "source_provider": "open.er-api.com",
                                "last_update_utc": data.get("time_last_update_utc"),
                            },
                            status="live_verified",
                        )
                        redis_store.cache_set("fx_usd_inr", rec.model_dump(), ttl_seconds=3600)
                        return rec
        except Exception:
            pass

        # Deterministic benchmark fallback with explicit status
        return BaseDataRecord(
            record_id="fx_usd_inr_benchmark",
            record_type="benchmark_fx_quote",
            attribution=SourceAttribution(
                source_name="CLIMATWIN Standard Financial Benchmark FX",
                source_uri="https://climatwin.internal/benchmarks/fx",
                retrieved_at=datetime.now(timezone.utc).isoformat(),
                reliability_score=0.85,
                data_vintage="Fixed Benchmark",
            ),
            payload={
                "base_currency": "USD",
                "target_currency": "INR",
                "exchange_rate": self.BENCHMARK_USD_INR,
                "is_live_rate": False,
                "note": "Standard benchmark FX rate used as deterministic fallback.",
            },
            status="benchmark_fallback",
        )

    async def fetch(self, portfolio_id: Optional[str] = None, **kwargs) -> List[BaseDataRecord]:
        """Fetch market rates and live FX record."""
        fx_rec = await self.fetch_live_fx_rate()
        return [fx_rec]
