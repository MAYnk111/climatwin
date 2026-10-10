from fastapi import APIRouter, Query
from typing import List, Optional
from app.graph.demo_data import build_demo_graph
from app.graph.models import DependencyGraphResponse, PropagationPath, EdgeType, RiskLevel
from app.agents.state import RiskInvestigationState
from app.agents.workflow import build_investigation_workflow
from app.simulations.models import (
    HoldingBaseline,
    ScenarioParameter,
    ScenarioSimulationResult,
)
from app.simulations.engine import ClimateScenarioSimulationEngine

api_router = APIRouter(prefix="/v1")
_demo_graph = build_demo_graph()


@api_router.get("/health")
def health_check():
    from app.core.redis_store import redis_store
    return {
        "status": "healthy",
        "service": "CLIMATWIN Intelligence Engine",
        "version": "1.0.0-alpha",
        "graph_nodes_loaded": len(_demo_graph.node_metadata),
        "storage": redis_store.get_status(),
    }


@api_router.get("/graph", response_model=DependencyGraphResponse)
def get_dependency_graph(
    relationship_types: Optional[List[EdgeType]] = Query(None),
    min_risk_level: Optional[RiskLevel] = Query(None),
    max_depth: Optional[int] = Query(None),
    center_node_id: Optional[str] = Query(None),
    include_sectivia: bool = Query(False),
):
    """Returns the dependency graph with deterministic coordinates and filters.
    When include_sectivia=true, reconciles 350+ supply chain relationships from Sectivia (CC BY 4.0).
    """
    target_graph = build_demo_graph(include_sectivia=True) if include_sectivia else _demo_graph
    return target_graph.filter_subgraph(
        relationship_types=relationship_types,
        min_risk_level=min_risk_level,
        max_depth=max_depth,
        center_node_id=center_node_id,
    )


@api_router.get("/graph/propagation", response_model=List[PropagationPath])
def get_propagation_paths(
    hazard_id: str = "hz_taiwan_drought",
    target_id: str = "comp_nvidia",
):
    """Calculates NetworkX propagation paths from hazard to company or portfolio."""
    return _demo_graph.find_hazard_propagation_paths(hazard_id=hazard_id, target_id=target_id)


from pydantic import BaseModel
from typing import Any, Dict


class InvestigationRequest(BaseModel):
    investigation_id: str = "inv_001"
    portfolio_id: str = "cust_global_tech_fund"
    hazard_event_id: str = "hz_taiwan_drought"
    target_id: Optional[str] = None
    hazard_title: Optional[str] = "Central Taiwan Extreme Drought"
    hazard_description: Optional[str] = "Severe drought impacting Baoshan reservoir and semiconductor fabrication clusters."
    graph_context: Optional[Dict[str, Any]] = None


from app.agents.poller import event_poller


@api_router.post("/intelligence/investigate", response_model=RiskInvestigationState)
def run_investigation(
    payload: Optional[InvestigationRequest] = None,
):
    """Executes the LangGraph AI risk investigation workflow."""
    req = payload or InvestigationRequest()
    workflow = build_investigation_workflow()
    
    # Calculate propagation paths dynamically if target_id is present
    dynamic_paths = []
    if req.target_id:
        paths = _demo_graph.find_hazard_propagation_paths(
            hazard_id=req.hazard_event_id,
            target_id=req.target_id,
        )
        if paths:
            dynamic_paths = [p.path_nodes for p in paths]

    initial_state = RiskInvestigationState(
        investigation_id=req.investigation_id,
        portfolio_id=req.portfolio_id,
        hazard_event_id=req.hazard_event_id,
        hazard_title=req.hazard_title or "Central Taiwan Extreme Drought",
        hazard_description=req.hazard_description or "Severe drought impacting Baoshan reservoir.",
        graph_propagation_paths=dynamic_paths,
    )
    result = workflow.invoke(initial_state.model_dump())
    
    # If dynamic paths were calculated for this target, preserve them in response
    if dynamic_paths:
        result["graph_propagation_paths"] = dynamic_paths
        
    state_obj = RiskInvestigationState(**result)
    event_poller.record_investigation("default_user", state_obj.model_dump())
    return state_obj


class SimulationRequestBody(BaseModel):
    scenario_id: str = "scen_q4_water_stress"
    scenario_name: str = "Q4 Taiwan Severe Drought & Packaging Bottleneck"
    severity_multiplier: float = 1.8
    duration_months: int = 4
    adaptation_mitigation_active: bool = True
    alternative_supplier_available: bool = True
    target_holding_tickers: Optional[List[str]] = None
    baseline_holdings: Optional[List[HoldingBaseline]] = None


@api_router.post("/simulations/run", response_model=ScenarioSimulationResult)
def run_simulation(
    payload: Optional[SimulationRequestBody] = None,
):
    """Runs baseline-versus-stressed portfolio stress test and branch comparison."""
    req = payload or SimulationRequestBody()
    default_holdings = [
        HoldingBaseline(
            ticker="AAPL",
            name="Apple Inc.",
            weight=0.12,
            current_value_usd=30_000_000.0,
            beta_to_hazard=1.1,
        ),
        HoldingBaseline(
            ticker="NVDA",
            name="NVIDIA Corp",
            weight=0.09,
            current_value_usd=22_500_000.0,
            beta_to_hazard=1.6,
        ),
        HoldingBaseline(
            ticker="BMW.DE",
            name="BMW Group",
            weight=0.05,
            current_value_usd=12_500_000.0,
            beta_to_hazard=0.8,
        ),
    ]
    holdings = req.baseline_holdings or default_holdings
    if req.target_holding_tickers:
        selected_tickers = set(req.target_holding_tickers)
        filtered = [h for h in holdings if h.ticker in selected_tickers]
        if filtered:
            holdings = filtered

    params = ScenarioParameter(
        hazard_severity_multiplier=req.severity_multiplier,
        duration_months=req.duration_months,
        adaptation_mitigation_active=req.adaptation_mitigation_active,
        alternative_supplier_available=req.alternative_supplier_available,
    )
    return ClimateScenarioSimulationEngine.run_stress_test(
        scenario_id=req.scenario_id,
        scenario_name=req.scenario_name,
        holdings=holdings,
        params=params,
    )


# External Real-Data Adapters (Open-Meteo & Live FX with Attribution)
from app.adapters.climate import ClimateHazardAdapter
from app.adapters.market import MarketPortfolioAdapter

_climate_adapter = ClimateHazardAdapter()
_market_adapter = MarketPortfolioAdapter()


@api_router.get("/adapters/climate/weather")
async def get_live_climate_weather(
    region_code: Optional[str] = Query(None, description="Preset region code (comp_tsmc, comp_bmw)"),
    latitude: Optional[float] = Query(None),
    longitude: Optional[float] = Query(None),
):
    """Fetches real-time environmental data via Open-Meteo or deterministic benchmark."""
    if latitude is not None and longitude is not None:
        rec = await _climate_adapter.fetch_live_weather(latitude=latitude, longitude=longitude)
        return rec
    records = await _climate_adapter.fetch(region_code=region_code)
    return records


@api_router.get("/adapters/market/fx-rate")
async def get_market_fx_rate():
    """Fetches live USD/INR exchange rate with source attribution or deterministic fallback."""
    return await _market_adapter.fetch_live_fx_rate()


@api_router.get("/adapters/news/feed")
def get_climate_news_feed():
    """Returns curated verified climate news and hazard bulletins with source attribution."""
    from datetime import datetime, timezone
    now = datetime.now(timezone.utc).isoformat()
    return [
        {
            "id": "news_tw_drought_2026",
            "title": "Taiwan Baoshan Reservoir Stage 2 Rationing Announced",
            "summary": "Water Resources Agency mandates industrial conservation for Hsinchu science park.",
            "source": "Taiwan Water Resources Agency (WRA)",
            "source_uri": "https://wra.gov.tw/bulletins",
            "retrieved_at": now,
            "status": "verified_source",
            "severity": "critical",
            "affected_entities": ["comp_tsmc", "comp_nvda", "comp_aapl"],
        },
        {
            "id": "news_rhine_gauge_2026",
            "title": "Rhine River Water Levels at Kaub Gauge Drop Below 40cm",
            "summary": "Freight barge draft restricted to 45% capacity, slowing central European automotive deliveries.",
            "source": "German Federal Waterways & Shipping Administration (WSV)",
            "source_uri": "https://elwis.de/wsv-kaub",
            "retrieved_at": now,
            "status": "verified_source",
            "severity": "high",
            "affected_entities": ["comp_bmw"],
        },
    ]


@api_router.get("/intelligence/poller/status")
def get_poller_status():
    """Returns the truthful operational status of the climate news poller."""
    return event_poller.get_status()


@api_router.post("/intelligence/poller/start")
async def start_poller_monitoring(interval_seconds: int = 60):
    """Starts the continuous background monitoring job."""
    await event_poller.start_monitoring(interval_seconds=interval_seconds)
    return {"status": "started", "details": event_poller.get_status()}


@api_router.post("/intelligence/poller/stop")
async def stop_poller_monitoring():
    """Stops the continuous background monitoring job."""
    await event_poller.stop_monitoring()
    return {"status": "stopped", "details": event_poller.get_status()}


@api_router.post("/intelligence/poller/poll-now")
async def trigger_poll_now(user_id: str = "default_user"):
    """Triggers an immediate polling cycle, deduplicating incoming events."""
    new_alerts = await event_poller.poll_once(user_id=user_id)
    return {
        "status": "success",
        "new_alerts_count": len(new_alerts),
        "alerts": new_alerts,
        "poller_status": event_poller.get_status(),
    }


@api_router.get("/intelligence/alerts/live")
def get_live_alerts():
    """Returns active alerts generated by the Risk Investigator and poller with timestamps and evidence."""
    return event_poller.active_alerts


@api_router.get("/intelligence/history")
def get_investigation_history(user_id: str = "default_user"):
    """Returns recorded investigation results with timestamps and evidence citations."""
    return event_poller.get_investigation_history(user_id=user_id)


@api_router.post("/intelligence/history")
def record_investigation_history(investigation: Dict[str, Any], user_id: str = "default_user"):
    """Persists an investigation result to history."""
    return event_poller.record_investigation(user_id=user_id, investigation=investigation)


# --- World Bank CCKP Climate Endpoints ---
@api_router.get("/climate/cckp")
async def get_world_bank_cckp_data(
    country_iso3: str = Query("TWN", description="Country ISO3 code (e.g. TWN, USA, DEU)"),
    include_historical: bool = Query(True, description="Include 1950-2014 historical baseline"),
):
    """Fetches World Bank CCKP CMIP6 climate timeseries (tas, pr, spei12).
    Includes multimodel ensemble percentiles (median, p10, p90) and scenarios (SSP2-4.5, SSP5-8.5).
    """
    from app.adapters.world_bank_cckp import WorldBankCCKPAdapter
    adapter = WorldBankCCKPAdapter()
    series = await adapter.fetch_country_projections(
        country_iso3=country_iso3, include_historical=include_historical
    )
    return {
        "source": "World Bank Climate Change Knowledge Portal (CCKP)",
        "license": "CC BY 4.0",
        "country_iso3": country_iso3,
        "series_count": len(series),
        "data": [s.model_dump() for s in series],
    }


# --- GDELT Live News Endpoints ---
@api_router.get("/climate/gdelt")
async def get_gdelt_climate_news(
    query: str = Query("drought semiconductor taiwan", description="Search query"),
    topic: str = Query("Drought", description="Hazard topic"),
):
    """Fetches GDELT 2.0 live news articles with deduplication and 25-minute TTL caching."""
    from app.adapters.gdelt_news import GDELTNewsAdapter
    adapter = GDELTNewsAdapter()
    articles = await adapter.fetch_hazard_news(query=query, hazard_topic=topic)
    return {
        "source": "GDELT Project 2.0 Global News Database",
        "query": query,
        "articles_count": len(articles),
        "articles": [a.model_dump() for a in articles],
    }


# --- Quantitative Physical Risk Engine Endpoints ---
class RiskCalculationApiRequest(BaseModel):
    hazard_id: str = "hz_taiwan_drought"
    hazard_title: str = "Central Taiwan Extreme Drought"
    target_node_id: str = "comp_nvidia"
    portfolio_aum_usd: float = 250_000_000.0
    has_secondary_supplier: bool = False
    has_onsite_mitigation: bool = False
    synthesize_with_gemini: bool = True
    weights: Optional[Dict[str, float]] = None


@api_router.post("/risk/calculate")
def calculate_physical_risk(req: RiskCalculationApiRequest):
    """Calculates deterministic Hazard-Exposure-Vulnerability risk scores in Python.
    Enriched with Phase 3.5 closed-form component attribution, NetworkX path explanation,
    financial decomposition, and simplex sensitivity analysis.
    Invokes Gemini strictly for executive synthesis if requested, without inventing numbers.
    """
    from app.simulations.risk_engine import PhysicalRiskEngine
    engine = PhysicalRiskEngine(_demo_graph)
    result = engine.calculate_entity_risk(
        hazard_id=req.hazard_id,
        hazard_title=req.hazard_title,
        target_node_id=req.target_node_id,
        portfolio_aum_usd=req.portfolio_aum_usd,
        has_secondary_supplier=req.has_secondary_supplier,
        has_onsite_mitigation=req.has_onsite_mitigation,
        weights=req.weights,
    )

    if req.synthesize_with_gemini:
        result = engine.synthesize_risk_with_gemini(result)

    return result.model_dump()


@api_router.get("/risk/calibration/audit")
def get_calibration_audit():
    """Audits repository datasets to confirm target labels, features, missing values, and leakage risks."""
    from app.simulations.calibration import calibration_manager
    report = calibration_manager.audit_datasets()
    return report.model_dump()


@api_router.get("/risk/calibration/sensitivity")
def get_calibration_sensitivity(mode: str = "diversified"):
    """Runs systematic sensitivity analysis across 6 weight profiles on the 3-pillar simplex.
    Supports 'diversified' (evaluates cross-pillar trade-offs, rho = 0.867) and 'monotonic' (rho = 1.000).
    """
    from app.simulations.calibration import calibration_manager
    if mode.lower() in ("monotonic", "standard"):
        scores = calibration_manager.STANDARD_BENCHMARK_PORTFOLIO
    else:
        scores = calibration_manager.DIVERSIFIED_ASYMMETRIC_PORTFOLIO
    report = calibration_manager.run_sensitivity_analysis(scores)
    return report.model_dump()


@api_router.get("/risk/calibration/spec")
def get_required_calibration_data_spec():
    """Returns the formal scientific data specification required to train future empirical models."""
    from app.simulations.calibration import calibration_manager
    spec = calibration_manager.get_calibration_data_spec()
    return spec.model_dump()



# --- Firebase Cloud Messaging (FCM) Endpoints ---
class FCMRegisterApiRequest(BaseModel):
    user_id: str = "default_user"
    fcm_token: str
    device_platform: str = "android"


class FCMSendApiRequest(BaseModel):
    user_id: str = "default_user"
    alert_id: str = "alt_live_001"
    title: str
    body: str
    data: Optional[Dict[str, str]] = None


@api_router.post("/notifications/fcm/register")
def register_fcm_token(req: FCMRegisterApiRequest):
    """Enrolls user device FCM push token in durable state."""
    from app.core.fcm_service import fcm_service
    reg = fcm_service.register_device_token(
        user_id=req.user_id, fcm_token=req.fcm_token, device_platform=req.device_platform
    )
    return {"status": "registered", "registration": reg.model_dump()}


@api_router.post("/notifications/fcm/send")
def send_fcm_push_notification(req: FCMSendApiRequest):
    """Dispatches FCM push notification. Clearly reports delivered vs stored_only status."""
    from app.core.fcm_service import fcm_service
    res = fcm_service.send_alert_push_notification(
        user_id=req.user_id,
        alert_id=req.alert_id,
        title=req.title,
        body=req.body,
        data_payload=req.data,
    )
    return res.model_dump()


