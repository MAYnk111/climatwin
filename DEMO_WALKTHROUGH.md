# CLIMATWIN — Hackathon Demonstration Walkthrough

> **Repeatable Demo Scenario**: Taiwan Semiconductor Extreme Drought Shock  
> **Target Holdings**: NVIDIA Corp (NVDA), Apple Inc. (AAPL)  
> **Physical Bottleneck**: TSMC Fab 12, Hsinchu Science Park & Kaohsiung Port Corridor  
> **Platform**: Flutter Android (Physical Device) + FastAPI Backend (Port 8000 via USB reverse)

---

## 1. Demonstration Narrative Arc

CLIMATWIN demonstrates how a localized physical climate hazard (reservoir deficit in central Taiwan) propagates through multi-tier supply-chain infrastructure to threaten major global equity portfolio holdings, and how pre-emptive mitigation contracts preserve portfolio capital.

```
[Physical Climate Telemetry]
  - World Bank CCKP CMIP6: SPEI12 = -1.35 (Severe Drought Anomaly)
  - Taiwan Water Resources Agency (WRA): Baoshan No. 2 Reservoir at 17.8% Capacity
  - Open-Meteo Weather: 29.5°C Surface Temperature, 85% Precip Deficit
         │
         ▼
[Tier-0: Physical Hazard Node]
  Central Taiwan Extreme Drought (Risk: 92/100, CRITICAL)
         │
         ▼
[Tier-1: Regional Infrastructure & Physical Facilities]
  Hsinchu Science Park Basin ──► Fab 12 Advanced Silicon Wafer Fab (TSMC)
         │                               │
         │ (Freight Feeder)              │ (Consumes 45,000 m³/day)
         ▼                               ▼
  Taiwan Strait Shipping Corridor   Ultra-Pure Water & Silicon Wafers
         │
         ▼
  Port of Kaohsiung Logistics Hub ──► High-Purity Neon & Lithography Gases
         │                               │
         └───────────────────────────────┘
                         │
                         ▼
[Tier-2: Contract Foundry Supplier (Sectivia Verified)]
  TSMC (Taiwan Semiconductor Manufacturing Co.)
         │
         ├─── (Tier-1 GPU Foundry: Exclusive 4N/3nm)
         │    ▼
         │  NVIDIA Corp (NVDA) [Portfolio Weight: 9%]
         │
         └─── (Tier-1 A/M-Series Silicon Foundry)
              ▼
            Apple Inc. (AAPL) [Portfolio Weight: 12%]
                         │
                         ▼
[Tier-3: Investment Fund Holding]
  Global Climate-Resilient Tech Portfolio (AUM: $250,000,000 / ₹2,087.50 Cr)
                         │
                         ▼
[Quantitative Risk Quantification (Deterministic Python Engine)]
  - Hazard Score (H): 92.0 / 100
  - Exposure Score (E): 65.0 / 100 (Tier-discounted NetworkX topological depth)
  - Vulnerability Score (V): 85.0 / 100 (Single-foundry single-sourcing)
  - Composite Risk Score: 79.0 / 100 (HIGH RISK)
  - Unmitigated Drawdown: -15.8% ($-39,500,000 USD / ₹329.8 Cr Loss)
                         │
                         ▼
[Mitigation Optimization & Explainable AI]
  - Intervention A: Water Recycling & Closed-Loop Adaptation (-40% vulnerability)
  - Intervention B: Secondary Foundry Dual-Sourcing (-30% single-source bottleneck)
  - Mitigated Residual Drawdown: -4.38% ($-10,950,000 USD / ₹91.4 Cr Loss)
  - Net Capital Preserved: +$28,550,000 USD (+₹238.4 Cr Preserved)
```

---

## 2. Step-by-Step Live Demo Execution

### Pre-Flight Check (30 seconds)
1. **Verify Backend**:
   - `python -m uvicorn app.main:app --host 0.0.0.0 --port 8000` is active.
   - `http://localhost:8000/api/v1/health` returns `healthy` with `graph_nodes_loaded: 18`.
2. **Verify ADB Port Forwarding**:
   - `adb -s K7GASWEA4XXKHYTC reverse tcp:8000 tcp:8000`.
   - `adb -s K7GASWEA4XXKHYTC reverse --list` returns `UsbFfs tcp:8000 tcp:8000`.
3. **Verify Mobile App**:
   - CLIMATWIN is open in foreground on Realme 9 Pro+ 5G (`RMX3395`).

---

### Step 1: Home Dashboard — Portfolio Climate Exposure (Screen 1)
- **What the audience sees**:
  - **Portfolio Climate Risk**: `68.5 / 100` (`MODERATE EXPOSURE`).
  - **Portfolio Valuation**: `₹83.50 Cr` Total AUM, `₹15.20 Cr` Climate Value-at-Risk.
  - **Risk Indicators**: Physical Hazard (`74 High`), Supply Chain (`81 Critical`), Transition (`42 Low`).
  - **Incoming Alert**: "Taiwan Baoshan Reservoir Stage 2 Water Rationing — Affects TSMC Fab 12 • Propagates to NVDA & AAPL".
- **Presenter Talking Point**:
  > *"CLIMATWIN doesn't treat portfolio risk as an abstract ESG rating. It tracks live physical hydrological stress in industrial basins and quantifies direct capital exposure in Indian Rupees and US Dollars."*

---

### Step 2: Explore Screen — Interactive Multi-Tier Dependency Graph (Screen 2)
- **Action**: Tap **Explore** on the bottom navigation bar.
- **What the audience sees**:
  - `18 nodes • 19 edges (Backend Live)` rendered on the native 60 FPS interactive canvas.
  - **Left Tier**: Red hazard node `Central Taiwan Extreme Drought (Risk: 92)`.
  - **Infrastructure Tier**: `Hsinchu Science Park`, `Fab 12 Semiconductor Fab`, `Port of Kaohsiung Logistics Hub`, `Port of Rotterdam Chemical Gateway`.
  - **Commodity Tier**: `Ultra-Pure Water & Silicon Wafers`, `High-Purity Neon & Specialty Gases`.
  - **Supplier Tier**: `TSMC (Contract Foundry)` and `BASF SE`.
  - **Holdings Tier**: `NVIDIA Corp (NVDA)`, `Apple Inc. (AAPL)`, `BMW Group (BMW.DE)`.
  - Tap `Fab 12` or `Port of Kaohsiung`: Modal sheet displays verified asset attributes (water intensity 45,000 m³/day, container berths, data source attribution: TIPC / TSMC CSR).
- **Presenter Talking Point**:
  > *"Here is the multi-tier NetworkX graph. Notice how Taiwan drought doesn't just hit the fab; it propagates through regional shipping to the Port of Kaohsiung, constrains neon lithography gas transshipment, bottlenecks TSMC foundry capacity, and transmits directly to NVIDIA and Apple holdings."*

---

### Step 3: Intelligence Screen — LangGraph Agent Investigation & Evidence (Screen 3)
- **Action**: Tap **Intelligence** on the bottom navigation bar (or tap *Investigate Propagation* from an alert).
- **What the audience sees**:
  - **LangGraph Agent Badge**: `LANGGRAPH AGENT WORKFLOW` with `LangSmith Traced` green verification pill.
  - **Executive Finding**: Detailed physical disruption bottleneck analysis.
  - **Active Graph Transmission Paths**:
    - `taiwan_drought ──► hsinchu ──► fab12 ──► tsmc ──► nvidia`
    - `taiwan_drought ──► hsinchu ──► tr_taiwan_strait_shipping ──► hub_kaohsiung_port ──► comm_neon_gas ──► fab12 ──► tsmc ──► apple`
  - **Physical Evidence Citations**:
    - Taiwan Water Resources Agency (WRA): Baoshan Reservoir at 17.8%
    - World Bank CCKP CMIP6: SPEI12 drought index = -1.35
    - Open-Meteo: 29.5°C surface temperature, 85% precipitation deficit
  - Tap `Ask AI for Insights`: Triggers Gemini Flash Lite with strict mathematical isolation (explaining Python numbers without hallucinating statistics).
- **Presenter Talking Point**:
  > *"Every claim made by the LangGraph risk investigator is backed by real physical telemetry from the World Bank and meteorological gauges. Python computes the deterministic losses, while Gemini provides executive synthesis."*

---

### Step 4: Simulate Screen — What-If Stress Testing & Mitigation Savings (Screen 4)
- **Action**: Tap **Simulate** on the bottom navigation bar.
- **Interactions**:
  1. Set Hazard Multiplier to `1.8x Baseline`, Disruption Duration to `4 Months`.
  2. Toggle `Water Recycling & Site Adaptation` ON.
  3. Toggle `Secondary Foundry Dual-Sourcing` ON.
  4. Tap `Execute Scenario Simulation`.
- **What the audience sees**:
  - **Baseline Portfolio Value**: `₹542.8 Cr ($65.0M)`
  - **Stressed Portfolio Value**: `₹519.0 Cr ($62.2M)`
  - **Residual Drawdown**: `-4.38% (₹23.75 Cr)` vs **Unmitigated Shock**: `-14.58%`
  - **Mitigation Capital Saved**: `+₹55.41 Cr` preserved!
  - **Holdings Breakdown**:
    - `AAPL`: Saved `+₹23.15 Cr`
    - `NVDA`: Saved `+₹25.25 Cr`
    - `BMW.DE`: Saved `+₹7.01 Cr`
  - `[ MODEL ESTIMATE ]` transparency tag clearly shown.
- **Presenter Talking Point**:
  > *"In Step 5, we see the return on adaptation investment. By pre-securing dual-foundry allocations and closed-loop water treatment, the portfolio preserves ₹55.41 Crore in capital that would otherwise be destroyed by the drought."*

---

### Step 5: Alerts & Push Notifications (Verification)
- **Action**: Tap the Notification Bell in the header.
- **What the audience sees**:
  - Active Android system notification channel: `climatwin_alerts`.
  - Tap `Test Alert`: Native Android push notification appears with audible alert and heads-up banner on Realme device.
- **Presenter Talking Point**:
  > *"CLIMATWIN doesn't require fund managers to stare at a screen all day. Background monitoring checks GDELT news feeds and reservoir telemetry, alerting the portfolio manager instantly when physical thresholds are breached."*

---

## 3. Key Defensibility & Scientific Highlights

| Feature | Engineering Implementation | Why It Matters |
|---|---|---|
| **No Hallucinated Numbers** | All financial drawdowns, losses, and scores computed strictly in deterministic Python. | Institutional investors cannot rely on LLMs guessing financial statistics. |
| **Simplex Weight Sensitivity** | Evaluated across 6 weight profiles on 3-pillar simplex ($\sum w_i = 1$). | Proves ranking stability ($\bar{\rho} = 0.867$) without claiming false empirical calibration. |
| **Data Provenance Separation** | Strict tagging: `verified_sectivia` vs `verified_physical_facility` vs `synthetic_scenario_hazard`. | Ethical AI disclosure; commercial links are never disguised as observed climate damage. |
| **Physical Device Native** | Running on physical Realme 9 Pro+ 5G hardware via Android USB reverse forwarding. | Proves production mobile feasibility, not a browser mockup. |
