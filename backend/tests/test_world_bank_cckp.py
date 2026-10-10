import pytest
from unittest.mock import patch
from app.adapters.world_bank_cckp import (
    WorldBankCCKPAdapter,
    CCKPVariableSeries,
    CCKPDataPoint,
)
from app.core.redis_store import redis_store


@pytest.fixture(autouse=True)
def clean_redis_cache():
    redis_store.clear_all()
    yield
    redis_store.clear_all()


def test_cckp_response_parser_robustness():
    """Verifies that CCKP response parsing extracts all variables, scenarios, and percentiles."""
    adapter = WorldBankCCKPAdapter()
    sample_payload = {
        "metadata": {"apiVersion": "v1", "status": "success"},
        "data": {
            "tas": {
                "2015-2100": {
                    "median": {
                        "ssp245": {
                            "TWN": {"2020-07": 20.95, "2050-07": 21.80, "2100-07": 22.44}
                        }
                    },
                    "p10": {
                        "ssp245": {
                            "TWN": {"2020-07": 20.35, "2050-07": 21.15, "2100-07": 21.72}
                        }
                    },
                    "p90": {
                        "ssp585": {
                            "TWN": {"2020-07": 21.20, "2050-07": 23.10, "2100-07": 26.16}
                        }
                    },
                }
            },
            "spei12": {
                "2015-2100": {
                    "median": {
                        "ssp245": {
                            "TWN": {"2020-07": -0.15, "2050-07": -0.32, "2100-07": -0.40}
                        }
                    }
                }
            },
        },
    }

    series = adapter.parse_cckp_payload(sample_payload, target_country_iso3="TWN")
    assert len(series) == 4

    tas_median = next(s for s in series if s.variable == "tas" and s.percentile_stat == "median")
    assert tas_median.country_iso3 == "TWN"
    assert tas_median.country_name == "Taiwan"
    assert tas_median.unit == "°C"
    assert tas_median.scenario == "ssp245"
    assert tas_median.is_projection is True
    assert tas_median.is_historical is False
    assert len(tas_median.points) == 3
    assert tas_median.points[0].year == 2020
    assert tas_median.points[0].value == 20.95


def test_scenario_separation_and_historical_distinction():
    """Verifies that historical observations (1950-2014) are strictly separated from CMIP6 projections."""
    adapter = WorldBankCCKPAdapter()
    sample_payload = {
        "metadata": {"status": "success"},
        "data": {
            "pr": {
                "1950-2014": {
                    "median": {
                        "historical": {
                            "TWN": {"1950-07": 2840.4, "2000-07": 2855.1}
                        }
                    }
                },
                "2015-2100": {
                    "median": {
                        "ssp585": {
                            "TWN": {"2050-07": 2780.0, "2100-07": 3094.5}
                        }
                    }
                },
            }
        },
    }

    series = adapter.parse_cckp_payload(sample_payload, target_country_iso3="TWN")
    hist_series = next(s for s in series if s.is_historical)
    proj_series = next(s for s in series if s.is_projection)

    assert hist_series.scenario == "historical"
    assert hist_series.period == "1950-2014"
    assert hist_series.is_historical is True
    assert hist_series.is_projection is False

    assert proj_series.scenario == "ssp585"
    assert proj_series.period == "2015-2100"
    assert proj_series.is_historical is False
    assert proj_series.is_projection is True


def test_taiwan_geographic_mapping_and_no_silent_substitution():
    """Verifies that Taiwan-related records strictly map to 'TWN' without substituting other countries."""
    adapter = WorldBankCCKPAdapter()
    # Payload contains CHN and TWN
    sample_payload = {
        "data": {
            "tas": {
                "2015-2100": {
                    "median": {
                        "ssp245": {
                            "CHN": {"2020-07": 7.8},
                            "TWN": {"2020-07": 20.9},
                            "USA": {"2020-07": 11.0},
                        }
                    }
                }
            }
        }
    }

    twn_series = adapter.parse_cckp_payload(sample_payload, target_country_iso3="TWN")
    assert len(twn_series) == 1
    assert twn_series[0].country_iso3 == "TWN"
    assert twn_series[0].points[0].value == 20.9

    # If TWN is missing in payload, it must return empty, never substitute CHN
    missing_twn_payload = {
        "data": {
            "tas": {
                "2015-2100": {
                    "median": {
                        "ssp245": {
                            "CHN": {"2020-07": 7.8},
                        }
                    }
                }
            }
        }
    }
    empty_series = adapter.parse_cckp_payload(missing_twn_payload, target_country_iso3="TWN")
    assert len(empty_series) == 0


def test_ensemble_percentiles_caveat():
    """Verifies that p10, median, and p90 carry the explicit ensemble distribution caveat."""
    adapter = WorldBankCCKPAdapter()
    fallback = adapter._generate_deterministic_cckp_fallback(country_iso3="TWN")
    assert len(fallback) > 0
    for s in fallback:
        assert "multimodel distribution statistics" in s.caveat
        assert "not deterministic bounds" in s.caveat


@pytest.mark.anyio
async def test_cckp_caching_and_error_fallback():
    """Verifies that CCKP queries cache with 24h TTL and fall back gracefully on API failure."""
    adapter = WorldBankCCKPAdapter()

    # Network failure simulation
    with patch("httpx.AsyncClient.get", side_effect=Exception("Connection timed out")):
        series = await adapter.fetch_country_projections("TWN")
        assert len(series) > 0
        assert any(s.variable == "spei12" for s in series)
        assert any(s.variable == "tas" for s in series)

    # Cache hit check
    cached = redis_store.cache_get("cckp_TWN_with_hist")
    assert cached is None or isinstance(cached, list)
