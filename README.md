# CLIMATWIN

> **Mobile-first, agentic climate-risk intelligence platform for investment portfolios.**

CLIMATWIN bridges geospatial climate hazard modeling, multi-tier corporate supply-chain dependencies, and portfolio risk management. It combines a live interactive dependency graph, LangGraph multi-agent investigations, deterministic risk models, and scenario stress testing.

---

## Quick Navigation
- [What Does CLIMATWIN Do?](#-what-does-climatwin-do)
- [System Architecture](#-system-architecture)
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
