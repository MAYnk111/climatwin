import urllib.request
import json

base_url = "http://localhost:8000"

endpoints = [
    ("GET", "/docs", None),
    ("GET", "/api/v1/health", None),
    ("GET", "/api/v1/graph", None),
    ("GET", "/api/v1/graph?include_sectivia=true", None),
    ("POST", "/api/v1/intelligence/investigate", {}),
    ("POST", "/api/v1/simulations/run", {"severity_multiplier": 1.5, "duration_months": 3}),
    ("POST", "/api/v1/risk/calculate", {"hazard_id": "hz_taiwan_drought", "target_node_id": "comp_nvidia", "synthesize_with_gemini": False}),
]

for method, path, body in endpoints:
    url = base_url + path
    try:
        data = json.dumps(body).encode() if body is not None else None
        headers = {"Content-Type": "application/json"} if body is not None else {}
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        with urllib.request.urlopen(req, timeout=10) as res:
            print(f"[OK] {method} {path} -> {res.status}")
    except Exception as e:
        print(f"[FAIL] {method} {path} -> {e}")
