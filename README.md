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

## 5. Unresolved Configuration Requirements

The following items are templates in `.env.example` and will need actual credentials when deploying to live environments:
1. `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / `GOOGLE_API_KEY`: Required for live LLM inference in the LangGraph agent node.
2. `LANGCHAIN_API_KEY`: Required for publishing trace logs to LangSmith.
3. `FIREBASE_PROJECT_ID` & `serviceAccountKey.json`: Required for live Cloud Firestore read/write sync.
4. `REDIS_URL`: Required for distributed multi-agent task queueing.

---

## 6. Phase 1 and Phase 2 Roadmap (Task 8)

### Phase 1: End-to-End API Integration & Dynamic Graph Binding
1. Bind mobile `InteractiveDependencyGraph` directly to `GET /api/v1/graph` using an HTTP client (`http` or `dio`).
2. Implement dynamic node selection to fetch real-time NetworkX propagation paths from `GET /api/v1/graph/propagation`.
3. Connect the "Investigate Propagation Risk" bottom sheet action to trigger `POST /api/v1/intelligence/investigate`.
4. Connect the Simulate slider controls to call `POST /api/v1/simulations/run` and update stressed portfolio values dynamically.

### Phase 2: Live Firebase Sync, LangSmith Traces & Scenario Branching
1. Initialize Firebase Auth and Cloud Firestore in the Flutter client for persistent user portfolios and watchlists.
2. Implement Firestore persistence for agent investigations, evidence audit trails, and scenario bookmarks.
3. Integrate live Open-Meteo / Copernicus weather feeds in `ClimateHazardAdapter`.
4. Add multi-branch comparison views in Simulate tab allowing side-by-side evaluation of multiple adaptation strategies.
