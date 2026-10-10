import pytest
from app.adapters.climate import ClimateHazardAdapter
from app.adapters.market import MarketPortfolioAdapter


@pytest.mark.anyio
async def test_climate_hazard_adapter_live_or_fallback():
    adapter = ClimateHazardAdapter()
    record = await adapter.fetch_live_weather(latitude=24.78, longitude=120.99, location_name="Hsinchu, Taiwan")
    
    assert record is not None
    assert record.record_type in ["live_climate_weather", "modeled_climate_weather"]
    assert "temperature_celsius" in record.payload
    assert "precipitation_mm" in record.payload
    assert record.attribution.source_name is not None
    assert record.attribution.retrieved_at is not None
    assert record.status in ["live_verified", "demo_fallback"]


@pytest.mark.anyio
async def test_market_fx_adapter_live_or_fallback():
    adapter = MarketPortfolioAdapter()
    record = await adapter.fetch_live_fx_rate()
    
    assert record is not None
    assert record.record_type in ["live_fx_quote", "benchmark_fx_quote"]
    assert record.payload["base_currency"] == "USD"
    assert record.payload["target_currency"] == "INR"
    assert record.payload["exchange_rate"] > 0
    assert record.attribution.source_name is not None
    assert record.status in ["live_verified", "benchmark_fallback"]
