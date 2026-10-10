# CLIMATWIN

> **Mobile-first, agentic climate-risk intelligence platform for investment portfolios.**

CLIMATWIN bridges geospatial climate hazard modeling, multi-tier corporate supply-chain dependencies, and portfolio risk management. It features an interactive dependency graph, LangGraph-driven risk investigations traced via LangSmith, and stress-testing simulation workflows.

---

## 1. Product Structure & Visual Reference

The mobile app implements the approved CLIMATWIN design guidelines:
- **Clean white/light surfaces** (`#FFFFFF`, `#F9FAFB`) with restrained borders (`#E5E7EB`).
- **Dark-green primary actions and accents** (`#0F3E30`, `#185A46`).
- **Meaningful risk status colors**: Green (Low), Amber (Medium), Red (High), Deep Red (Critical).
- **Secondary access**: Profile and settings are accessible via the header icon, preserving a strict **4-destination bottom navigation**:
  1. **Home**: Portfolio climate risk overview, indicators, important alerts, and quick actions.
  2. **Explore**: Portfolio holdings, watchlist, company search, and the interactive dependency graph.
  3. **Intelligence**: Climate events, source evidence, LangGraph agent risk investigations, and mitigation actions.
  4. **Simulate**: Scenario parameters, scenario branches, baseline vs. stressed comparisons, and mitigation results.

---

## 2. Repository Layout

```
fusion_r2/
├── .env.example                     # Root environment configuration template
├── .gitignore                        # Git exclusion rules (secrets, venvs, build artifacts)
├── architecture.md                   # System topology, graph calculations, and security spec
├── README.md                         # Project documentation and run guide
│
├── backend/
│   ├── .env.example                  # Backend environment template
│   ├── requirements.txt              # Python server dependencies
│   ├── app/
│   │   ├── main.py                   # FastAPI application entrypoint with CORS & routes
│   │   ├── core/
│   │   │   └── config.py             # Configuration management with environment fallbacks
│   │   ├── graph/
│   │   │   ├── models.py             # Typed nodes, directional edges, propagation paths
│   │   │   ├── engine.py             # NetworkX DiGraph engine with deterministic layout
│   │   │   └── demo_data.py          # Deterministic demo supply chain & hazard graph
│   │   ├── agents/
│   │   │   ├── state.py              # Investigation state schema
│   │   │   └── workflow.py           # LangGraph StateGraph workflow with LangSmith hooks
│   │   ├── adapters/
│   │   │   ├── base.py               # Abstract base adapter with source attribution & ISO timestamps
│   │   │   ├── climate.py            # Climate hazard adapter (connection-state tracked)
│   │   │   └── market.py             # Market & portfolio pricing adapter
│   │   ├── simulations/
│   │   │   ├── models.py             # Scenario configuration & stressed result models
│   │   │   └── engine.py             # Baseline-vs-stressed portfolio simulation engine
│   │   └── api/
│   │       └── router.py             # REST API routers (/health, /graph, /investigate, /simulations)
│   └── tests/
│       ├── test_graph_engine.py      # NetworkX layout and propagation tests
│       └── test_simulations.py       # Stress testing and mitigation calculation tests
│
└── mobile/
    ├── pubspec.yaml                  # Flutter package definition
    ├── test/
    │   └── widget_test.dart          # Flutter widget navigation test
    └── lib/
        ├── main.dart                 # Flutter application entrypoint
        ├── core/
        │   ├── theme.dart            # Approved CLIMATWIN light theme & color tokens
        │   └── navigation.dart       # 4-destination navigation shell & header profile launcher
        └── features/
            ├── home/                 # Portfolio overview, risk gauges, quick actions
            ├── explore/              # Interactive dependency graph canvas & holdings search
            ├── intelligence/         # Verified evidence, AI investigations, mitigations
            ├── simulate/             # Scenario branch tuning & baseline vs stressed comparisons
            └── settings/             # Profile & environment settings
```

---

## 3. How to Run the Project

### Prerequisites
- Python 3.10+ (Verified on Python 3.13.5)
- Flutter 3.16+ (Verified on Flutter 3.41.2 / Dart 3.11.0)

### Backend (FastAPI + NetworkX + LangGraph)

1. **Configure Environment Variables**:
   ```bash
   cp backend/.env.example backend/.env
   ```
2. **Install Dependencies** (in your Python virtual environment):
   ```bash
   pip install -r backend/requirements.txt
   ```
3. **Run Unit Tests**:
   ```bash
   pytest backend/tests -v
   ```
4. **Start the FastAPI Server**:
   ```bash
   cd backend
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```
   - API Documentation: [http://localhost:8000/docs](http://localhost:8000/docs)
   - Healthcheck: [http://localhost:8000/api/v1/health](http://localhost:8000/api/v1/health)

### Mobile App (Flutter)

1. **Verify Dependencies**:
   ```bash
   cd mobile
   flutter pub get
   ```
2. **Run Flutter Tests**:
   ```bash
   flutter test
   ```
3. **Run the App** (on connected emulator, device, or desktop/web):
   ```bash
   flutter run
   ```

---

## 4. Graph-Rendering Evaluation (Task 7)

- **Library Audit**: Before this phase, `mobile/pubspec.yaml` contained zero installed graph libraries.
- **Evaluation**:
  1. *Third-Party Graph Packages (e.g. `graphview`)*: Provide layout algorithms (Sugiyama / Buchheim-Walker), but introduce layout instability/jitter on mobile orientation changes and lack fine-grained directional arrow label styling.
  2. *WebView + Cytoscape.js*: Heavy memory overhead and poor touch gesture integration with Flutter bottom sheets.
  3. *Native `InteractiveViewer` + `CustomPainter` with Deterministic Layout (Selected)*:
     - Leverages NetworkX on the backend (or deterministic client-side tiers) to precompute stable coordinates:
       $\text{Hazard} \rightarrow \text{Facility/Route} \rightarrow \text{Supplier} \rightarrow \text{Company} \rightarrow \text{Portfolio}$.
     - 60 FPS smooth pan and zoom (`0.4x` to `2.5x`) via `InteractiveViewer`.
     - Direct tap hit-testing triggers the native Flutter modal bottom sheet.
     - Clean directional bezier curves with arrows, relationship labels, and highlighted hazard propagation routes.
     - Zero external dependency bloat or breaking pub version conflicts.

---

## 5. Phase 4 Integrations & API Endpoints

### World Bank CCKP CMIP6 Climate Data
- **Endpoint**: `GET /api/v1/climate/cckp?country_iso3=TWN&include_historical=true`
- Integrates `cmip6-x0.25` timeseries for `tas` (°C), `pr` (mm/yr), and `spei12` (drought index).
- Preserves historical observations (`1950-2014`) vs. future projections (`2015-2100` under `ssp245` & `ssp585`).
- Multi-model ensemble percentiles (`median`, `p10`, `p90`) are documented as distribution statistics, not guaranteed bounds.
- Strict geographic mapping: `TWN` strictly maps to Taiwan, with zero silent substitution.
- Cached for 24 hours with local durable JSON fallback.

### Sectivia U.S. Supply-Chain Graph (CC BY 4.0)
- **Endpoint**: `GET /api/v1/graph?include_sectivia=true`
- Integrates 215 companies and 350 directed relationships (`supplier -> customer`).
- Preserves sectors, segments, exchange, and country metadata.
- Attribution strictly embedded: `"Supply-chain data: Sectivia (https://sectivia.com), CC BY 4.0"`.
- Non-damage disclaimer: Commercial links represent commercial buyer-supplier relations, not evidence of climate loss.

### Deterministic Quantitative Physical Risk Engine
- **Endpoint**: `POST /api/v1/risk/calculate`
- Computes Hazard-Exposure-Vulnerability (H-E-V) scores purely in Python:
  $$\text{Composite Risk} = 0.35 \times H + 0.35 \times E + 0.30 \times V$$
- Evaluates capital preserved by mitigation strategies (dual sourcing + adaptation buffers).
- LLM constraint: Gemini Flash Lite synthesizes executive findings only upon explicit request, with no numbers hallucinated.

### Phase 3.5 Calibration, Sensitivity & Explainability Endpoints
- **Dataset Audit**: `GET /api/v1/risk/calibration/audit`
  - Formally audits repository datasets (`sectivia-companies.csv`, `sectivia-relations.csv`).
  - Confirms 0 empirical physical loss/disruption labels; enforces provisional engineering model disclosure.
- **Simplex Sensitivity Analysis**: `GET /api/v1/risk/calibration/sensitivity`
  - Evaluates 6 alternative weight profiles on the 3-pillar simplex ($\sum w_i = 1, w_i \ge 0$).
  - Reports Spearman rank correlation ($\rho$), max score delta ($\Delta$), and Ranking Stability Index ($0.867$).
- **Calibration Specification**: `GET /api/v1/risk/calibration/spec`
  - Documents formal scientific specification of SEC 10-K, Munich Re NatCatSERVICE, and WRA logs required for future empirical calibration.
- **Multi-Layer Explainability**:
  - Exact closed-form component attribution (points and percentages).
  - NetworkX structural propagation path narrative and tier discount factors.
  - Step-by-step financial arithmetic breakdown.
  - Segregated SHAP safety policy for non-linear models.

### GDELT 2.0 Live News & Firebase Push Notifications
- **GDELT News**: `GET /api/v1/climate/gdelt?query=drought%20taiwan` (SHA-256 deduplication, 25m TTL cache).
- **FCM Device Registration**: `POST /api/v1/notifications/fcm/register`.
- **FCM Push Notification**: `POST /api/v1/notifications/fcm/send` (strictly distinguishes `delivered` from `stored_only`).

---

## 6. Phase 5 Final Demo Readiness & Graph Completion

### Multi-Tier Dependency Graph (18 Nodes, 19 Edges)
- **Logistics Hubs**: Port of Kaohsiung Container Terminal (`hub_kaohsiung_port`), Port of Rotterdam Chemical Gateway (`hub_rotterdam_port`).
- **Sourced Commodities**: High-Purity Neon Lithography Gas (`comm_neon_gas`), Ultra-Pure Water & Silicon Wafers (`comm_ultrapure_water`).
- **Transport Corridors**: Taiwan Strait Feeder Shipping (`tr_taiwan_strait_shipping`), Rhine Barge Corridor (`tr_rhine_barge`).
- **Provenance Taxonomy**:
  - `verified_sectivia`: Verified corporate buyer-supplier links (CC BY 4.0).
  - `verified_physical_facility`: Verified physical infrastructure (TSMC Fab 12, BASF Verbund site, Kaohsiung Port).
  - `verified_transport_corridor`: Verified freight corridors (UNCTAD/WSV).
  - `sourced_industrial_commodity`: Verified industrial inputs (USGS Neon / Taiwan WRA Water).
  - `synthetic_scenario_hazard`: Climate stress test scenario shocks (clearly disclosed).
  - `portfolio_benchmark`: Fund holding allocations.
- **Multi-Tier Propagation**: Traces 2nd- and 3rd-order risk propagation from Taiwan drought to Kaohsiung Port -> Neon gas -> Fab 12 -> TSMC -> NVDA/AAPL -> Fund Holdings.

### Risk Calibration & Sensitivity Discrepancy Reconciliation
- **Discrepancy Resolved**:
  - **Monotonic Benchmark**: When evaluated on entities that uniformly dominate all pillars (`TSM > NVDA > AAPL > BMW > MSFT > AMZN`), rankings are invariant to weight shifts on the simplex ($\bar{\rho} = 1.000$).
  - **Diversified Asymmetric Portfolio**: When evaluated on realistic portfolios with cross-pillar score asymmetries (e.g., high-hazard/low-exposure foundry vs low-hazard/high-exposure OEM), parameter shifts cause realistic trade-offs, yielding $\bar{\rho} = 0.867$.
  - Both benchmarks confirm that relative rankings remain robust ($\bar{\rho} \ge 0.85$) while demonstrating that the H-E-V weights actively influence prioritization decisions.

### Repeatable Demo Walkthrough
- Complete step-by-step hackathon presentation guide available in [`DEMO_WALKTHROUGH.md`](DEMO_WALKTHROUGH.md).

---

## 7. Verification & Test Suite Results

### Backend Suite (`pytest`)
- **Command**: `python -m pytest tests -v` (from `backend/`)
- **Status**: **48 passed** (0 failed) in 20s
  - `test_calibration_and_sensitivity.py` (14 tests): Empirical label audit, simplex weight constraints ($\sum w=1, w_i \ge 0$), sensitivity analysis across 6 weight profiles, 0.867 vs 1.0 ranking stability reconciliation, exact component attribution closure, NetworkX path narratives, financial arithmetic decomposition, segregated SHAP safety policy, and Gemini numerical isolation.
  - `test_graph_engine.py` (6 tests): NetworkX layout coordinates, propagation path calculations, logistics hubs and commodity provenance, and multi-tier 2nd- and 3rd-order propagation to portfolio.
  - `test_world_bank_cckp.py` (5 tests): response parser, scenario separation, Taiwan ISO3 matching, ensemble caveats, 24h caching.
  - `test_sectivia_loader.py` (5 tests): dataset loading, supplier->customer direction, deduplication, core ID preservation, NetworkX multi-tier propagation.
  - `test_risk_engine.py` (4 tests): deterministic H-E-V scores, mitigation capital preservation, provisional weights transparency, Gemini constraint.
  - `test_gdelt_and_fcm.py` (4 tests): GDELT URL deduplication, 25m TTL caching, FCM token registration, `delivered` vs `stored_only` status distinction.
  - `test_adapters.py`, `test_agents.py`, `test_simulations.py` (10 tests).

### Flutter Mobile App Suite (`flutter test`)
- **Command**: `flutter test` (from `mobile/`)
- **Status**: **25 passed** (0 failed) in 15s
  - Auth, user-scoped Firestore persistence, graph binding, intelligence & simulation screens, market & candlestick charts, alert screen filters, and typed `PhysicalRiskResult` model parsing.

### Physical Device Verification
- **Device**: Realme 9 Pro+ 5G (`RMX3395` • `K7GASWEA4XXKHYTC` • Android 14 • API 34)
- **Connectivity**: `adb reverse tcp:8000 tcp:8000` (FastAPI at `http://localhost:8000/api/v1`)
- **Verified Flow**: Home Dashboard -> Explore (18 nodes live canvas) -> Intelligence (LangGraph + LangSmith + transmission paths) -> Simulate (₹55.41 Cr capital saved, zero overflow) -> Alerts (Push notification triggered).

---

## 8. Execution Commands

1. **Start FastAPI Intelligence Gateway**:
   ```powershell
   cd backend
   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```
2. **Setup Android Port Forwarding**:
   ```powershell
   adb -s K7GASWEA4XXKHYTC reverse tcp:8000 tcp:8000
   ```
3. **Run Backend Test Suite**:
   ```powershell
   cd backend
   python -m pytest tests -v
   ```
4. **Run Flutter App Tests**:
   ```powershell
   cd mobile
   flutter test
   ```
5. **Launch Flutter Mobile Application**:
   ```powershell
   cd mobile
   flutter run -d K7GASWEA4XXKHYTC
   ```

