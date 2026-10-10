# CLIMATWIN

> **Mobile-first, agentic climate-risk intelligence platform for investment portfolios.**

CLIMATWIN bridges geospatial climate hazard modeling, multi-tier corporate supply-chain dependencies, and portfolio risk management. It combines a live interactive dependency graph, LangGraph multi-agent investigations, deterministic risk models, and scenario stress testing.

---

### 📲 Download & Install Android App
> **⚠️ Important Notice**: Please download and install this APK **directly on an Android phone** (or Android device/emulator). It connects directly to the live production cloud backend.
> 
> 👉 **[Download Production APK (v1.0.0)](https://github.com/MAYnk111/climatwin/releases/download/v1.0.0/climatwin-release.apk)**  
> Direct URL: `https://github.com/MAYnk111/climatwin/releases/download/v1.0.0/climatwin-release.apk`

---

## Quick Navigation
- [Download Android APK](#-download--install-android-app)
- [What Does CLIMATWIN Do?](#-what-does-climatwin-do)
- [System Architecture](#-system-architecture)
- [Platform Development Phases & Key Features](#-platform-development-phases--key-features)
- [How to Run Locally](#-how-to-run-locally)
- [Deploying the Backend on Render](#-deploying-the-backend-on-render)
- [Connecting the Mobile App](#-connecting-the-mobile-app)
- [Automated Test Suites](#-automated-test-suites)
- [Repository Structure](#-repository-structure)

---

## 🌟 What Does CLIMATWIN Do?

1. **Geospatial Climate Hazard Modeling**: Fetches and evaluates climate anomalies (drought, extreme heat, river low-water levels) from live sources like GDELT and CMIP6 climate data.
2. **Multi-Tier Dependency Graph**: Visualizes second- and third-order supply-chain dependencies (`Hazard` → `Facility/Port` → `Supplier/Commodity` → `Company` → `Portfolio Holdings`).
3. **Multi-Agent Intelligence (LangGraph)**: Orchestrates specialized agents (Hazard Analyst, Supply Chain Detective, Vulnerability Specialist, Financial Impact Assessor, and Risk Investigator) to generate auditable mitigation strategies.
4. **Deterministic Physical Risk Engine**: Calculates transparent Hazard-Exposure-Vulnerability (H-E-V) scores without LLM hallucinations.
5. **Stress-Testing Simulation**: Allows portfolio managers to branch climate scenarios, adjust mitigation buffers, and evaluate capital saved (in ₹ INR & $ USD).

---

## 🏗️ System Architecture

```text
       ┌────────────────────────────────────────────────────────┐
       │              Flutter Mobile App (Android/iOS)          │
       │   [Home]      [Explore Graph]    [Intelligence]  [Simulate]
       └───────────────────────────┬────────────────────────────┘
                                   │ REST APIs
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │           FastAPI Intelligence Gateway (Backend)       │
       │                                                        │
       │  • NetworkX DiGraph Engine (18 Nodes, 19 Edges)        │
       │  • Deterministic H-E-V Risk Engine (Pillar Scoring)    │
       │  • LangGraph Multi-Agent Investigation Workflow        │
       │  • GDELT 2.0 Live News & World Bank CCKP Adapters      │
       │  • Token-Efficient Offline Caching & In-Memory Redis   │
       └────────────────────────────────────────────────────────┘
```

---

## 📈 Platform Development Phases & Key Features

The CLIMATWIN application was built across structured engineering phases, integrating physical climate modeling, multi-agent reasoning, deterministic financial arithmetic, and a high-performance mobile UI:

### 🔹 Phase 1: Core Foundation & API Binding
- **FastAPI Gateway**: Asynchronous gateway serving portfolio health, hazard feeds, and risk telemetry.
- **Flutter 4-Destination Shell**: Clean, professional mobile design with Emerald/Teal accents adhering to financial interface standards:
  1. **Home**: Portfolio Climate Value-at-Risk (VaR), physical vs. transition risk dials, active alert cards.
  2. **Explore**: Corporate search, multi-tier supply chain dependencies, and interactive canvas.
  3. **Intelligence**: Real-time climate disruptions, source evidence attribution, multi-agent AI investigations.
  4. **Simulate**: Scenario branch tuning, baseline vs. stressed comparisons, and capital preservation metrics.
- **Typed Data Layer**: Robust client-side models handling edge-cases, null tolerance, and resilient network exception translation.

---

### 🔹 Phase 2: Live Climate & Geospatial Adapters
- **World Bank CCKP CMIP6 Integration**:
  - Global climate projection timeseries for surface temperature (`tas`), precipitation (`pr`), and 12-month drought index (`spei12`).
  - Historical observations (`1950–2014`) vs. future climate pathways (`2015–2100` under `ssp245` & `ssp585`).
  - 24-hour disk cache with zero silent ISO-3 country substitution.
- **GDELT 2.0 Live News Pipeline**:
  - Real-time climate disruption scanning with SHA-256 event deduplication and 25-minute TTL caching.
  - Automated background news poller feeding urgent hazard alerts to the portfolio risk monitor.

---

### 🔹 Phase 3: Deterministic Physical Risk Engine & Multi-Tier Graph
- **Quantitative H-E-V Model**:
  - Closed-form Hazard-Exposure-Vulnerability formulation:
    $$\text{Composite Risk} = 0.35 \times H + 0.35 \times E + 0.30 \times V$$
  - Pure deterministic Python calculations without numerical LLM hallucinations.
- **NetworkX Multi-Tier Dependency Graph**:
  - 18 nodes and 19 directed edges across 5 structural tiers:
    - **Tier 0 (Hazards)**: Droughts, river low-water bottlenecks.
    - **Tier 1 (Facilities & Regions)**: Semiconductor Fabs, chemical complexes, deep-water ports.
    - **Tier 2 (Commodities & Corridors)**: High-purity neon gas, ultra-pure water, shipping lanes, barge corridors.
    - **Tier 3 (Companies)**: Apple, NVIDIA, BMW.
    - **Tier 4 (Portfolio)**: Global climate-resilient equity fund.
  - Multi-tier risk attenuation factor (15% damping per supply chain hop).

---

### 🔹 Phase 3.5: Risk Calibration, Sensitivity & Explainability
- **Dataset Audit**: Audits empirical corporate supply-chain benchmarks (Sectivia CC BY 4.0).
- **Simplex Sensitivity Analysis**:
  - Evaluates 6 alternative weight profiles across the 3-pillar simplex ($\sum w_i = 1$).
  - Reports Spearman rank correlation ($\rho$), max score delta ($\Delta$), and Ranking Stability Index ($0.867$).
- **Multi-Layer Explainability**:
  - Closed-form component attribution (exact points & percentages).
  - Graph propagation narratives explaining multi-hop bottlenecks.
  - Step-by-step financial arithmetic decomposing portfolio drawdown.

---

### 🔹 Phase 4: LangGraph Multi-Agent Intelligence
- **Specialized Climate Agents**:
  - **Hazard Analyst Agent**: Assesses climate severity, anomaly duration, and geospatial bounds.
  - **Supply Chain Detective Agent**: Identifies tier-1 to tier-3 bottlenecks, logistics hubs, and single-source dependencies.
  - **Vulnerability Specialist Agent**: Evaluates operational redundancies, water recycling, and facility adaptation.
  - **Financial Impact Assessor Agent**: Models unmitigated revenue disruption and Value-at-Risk (VaR).
  - **Risk Investigator & Mitigation Advisor**: Synthesizes verified multi-agent findings into prioritized mitigation interventions.
- **LangSmith Tracing**: Optional zero-overhead execution tracing on LangSmith for agent debugging and auditability.
- **Token-Efficient Offline Fallback**: Deterministic rule-based intelligence synthesizer that runs when no API keys are configured, preventing quota failures.

---

### 🔹 Phase 5: Interactive Mobile Dependency Graph Canvas
- **Native Canvas Architecture**:
  - Built using Flutter's native `InteractiveViewer` + `CustomPainter` with unconstrained canvas sizing (`constrained: false`).
  - Smooth 60 FPS multi-touch gestures: fluid panning, pinch-to-zoom (`0.20x` to `3.0x`), and interactive node selection.
  - `fitGraphToViewport`: Auto-centers and uniformly scales all 18 nodes and 19 edges to fit mobile portrait screens cleanly.
  - Interactive hit-testing triggering native bottom sheets with live in-situ agent investigations.

---

### 🔹 Phase 6: Enterprise User Experience & Cloud Deployment
- **Firebase Authentication & User Isolation**:
  - Email/password authentication, guest login, and password reset flows.
  - Scoped Firestore user data isolation (`/users/{uid}/scenarios`, `/users/{uid}/watchlists`, `/users/{uid}/investigations`).
- **Financial Market Dials & INR Localization**:
  - Multi-currency support formatting in Indian Rupees (₹ Crores and Lakhs at ₹83.50/USD benchmark) and US Dollars.
  - Live watchlist, market index tracking, and interactive candlestick price charts.
- **Push Notification & Alerts Center**:
  - Firebase Cloud Messaging (FCM) integration with in-app notification bell and severity filtering (Critical, High, Medium).
- **One-Click Cloud Deployment**:
  - Infrastructure-as-Code `render.yaml` blueprint and multi-stage `Dockerfile` for free zero-downtime hosting on Render.
  - Automated release pipeline producing signed release APKs (`flutter build apk --release`).

---

## 🚀 How to Run Locally

### Prerequisites
- **Python**: 3.10 or newer (tested on 3.11 & 3.13)
- **Flutter**: 3.16 or newer (tested on Flutter 3.24+ / Dart 3.5+)

---

### 1. Backend Setup

```bash
# Clone the repository
git clone https://github.com/MAYnk111/climatwin.git
cd climatwin

# Set up Python virtual environment (optional but recommended)
python -m venv venv
# On Windows:
.\venv\Scripts\activate
# On Mac/Linux:
source venv/bin/activate

# Install dependencies
pip install -r backend/requirements.txt

# Create .env from template
cp backend/.env.example backend/.env

# Start the FastAPI server
cd backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Once running:
- **API Documentation**: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- **Health Check**: [http://127.0.0.1:8000/api/v1/health](http://127.0.0.1:8000/api/v1/health)

---

### 2. Mobile App Setup (Flutter)

```bash
# Navigate to mobile directory
cd mobile

# Fetch Flutter dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

> **Testing on a physical Android device via USB?**
> Run this ADB port-forwarding command so your phone can reach your computer's local backend:
> ```bash
> adb reverse tcp:8000 tcp:8000
> ```

---

## ☁️ Deploying the Backend on Render

The repository includes a ready-to-use [`render.yaml`](render.yaml) blueprint and [`Dockerfile`](Dockerfile) for free cloud hosting on [Render.com](https://render.com).

### Option 1: One-Click Blueprint (Recommended)
1. Go to your [Render Dashboard](https://dashboard.render.com/).
2. Click **New +** $\rightarrow$ **Blueprint**.
3. Select the repository: `MAYnk111/climatwin`.
4. Render will read `render.yaml` automatically:
   - **Service Name**: `climatwin-backend`
   - **Runtime**: Python 3.11
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
5. *(Optional)* Enter your `GOOGLE_API_KEY` (Gemini API key). If left blank, the backend automatically uses its deterministic offline engine.
6. Click **Apply**. Within 2–3 minutes, your backend is live with a public HTTPS URL (e.g. `https://climatwin-backend.onrender.com`).

---

### Option 2: Manual Web Service Setup
1. Click **New +** $\rightarrow$ **Web Service**.
2. Connect `MAYnk111/climatwin`.
3. Set the following fields:
   - **Root Directory**: `backend`
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Health Check Path**: `/api/v1/health`
4. Under **Environment Variables**:
   - `ENVIRONMENT` = `production`
   - `DEBUG` = `false`
   - `FIREBASE_PROJECT_ID` = `invest-2-77a18`
   - `GOOGLE_API_KEY` = *(your Gemini key, optional)*

---

## 📱 Connecting the Mobile App to Render

Once your Render backend is live:

1. **Option A (In-App)**:
   - Open the app on your phone.
   - Tap the top-right profile/settings icon.
   - Enter your Render backend URL (e.g., `https://climatwin-backend.onrender.com/api/v1`).

2. **Option B (In Code)**:
   - Open `mobile/lib/core/api_client.dart` and update the default base URL:
     ```dart
     static const String defaultBaseUrl = 'https://climatwin-backend.onrender.com/api/v1';
     ```

---

## 🧪 Automated Test Suites

Both mobile and backend suites have 100% automated test coverage with zero mock drift:

### Run Backend Tests (54 Tests)
```bash
python -m pytest backend/tests -v
```
- Tests deterministic H-E-V scoring formulas and sensitivity simplex.
- Validates NetworkX multi-tier graph coordinates and propagation routes.
- Verifies token-efficient offline execution and GDELT deduplication.

### Run Mobile Flutter Tests (41 Tests)
```bash
cd mobile
flutter test
```
- Validates graph bounds calculation, matrix fitting, and interactive gestures.
- Tests multi-currency formatting (₹ INR Lakhs/Crores & $ USD).
- Verifies user-isolated Firestore and Firebase Authentication flows.

---

## 📁 Repository Structure

```text
climatwin/
├── Dockerfile                         # Root Dockerfile for containerized cloud deployment
├── render.yaml                        # Render Infrastructure-as-Code Blueprint
├── DEMO_WALKTHROUGH.md                # Step-by-step hackathon demo presentation guide
├── datasets/                          # Sectivia corporate supply chain benchmarks
│
├── backend/
│   ├── requirements.txt               # FastAPI, NetworkX, LangGraph, Uvicorn
│   ├── app/
│   │   ├── main.py                    # Gateway entrypoint & automated news poller
│   │   ├── core/                      # Configuration, LLM token routing & Redis store
│   │   ├── graph/                     # NetworkX engine, deterministic layout, Sectivia loader
│   │   ├── agents/                    # LangGraph multi-agent state graph & workflow
│   │   ├── adapters/                  # GDELT 2.0 live news & World Bank CCKP CMIP6
│   │   └── simulations/               # Deterministic H-E-V risk engine & explainability
│   └── tests/                         # Pytest test suite (54 tests)
│
└── mobile/
    ├── pubspec.yaml                   # Flutter dependencies
    ├── lib/
    │   ├── main.dart                  # Flutter entrypoint
    │   ├── core/                      # Theme, navigation, currency utils, API client
    │   └── features/
    │       ├── home/                  # Risk score gauges, VaR & quick actions
    │       ├── explore/               # 18-node dependency graph canvas with smooth pan/zoom
    │       ├── intelligence/          # Live climate news, AI investigation modal
    │       ├── simulate/              # Stress-test sliders & capital preservation breakdown
    │       ├── market/                # Live markets, commodities & INR candlestick charts
    │       └── alerts/                # Push notifications & severity filter strips
    └── test/                          # Flutter unit & widget test suite (41 tests)
```

---

## 📄 License
Supply-chain relationship dataset sourced from Sectivia under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
The software platform is open source under the MIT License.
