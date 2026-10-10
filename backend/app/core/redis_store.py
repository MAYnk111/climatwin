"""Redis state and cache manager for CLIMATWIN.
Provides shared event deduplication, alert persistence, investigation history,
and API telemetry caching.
Gracefully falls back to local durable file/memory persistence when Redis is offline.
"""

import json
import logging
import os
import time
from typing import Any, Dict, List, Optional, Set
from pathlib import Path

logger = logging.getLogger("climatwin.redis_store")


class RedisStateStore:
    """Manages Redis connection with zero-downtime durable fallback."""

    def __init__(self, redis_url: Optional[str] = None):
        self.redis_url = redis_url or os.getenv("REDIS_URL", "redis://localhost:6379/0")
        self._redis_client = None
        self._is_redis_available = False
        self._checked_connection = False

        # Local durable fallback storage path
        self._data_dir = Path(__file__).resolve().parent.parent.parent / "data"
        self._state_file = self._data_dir / "climatwin_state.json"

        # In-memory mirrors
        self._local_seen_events: Set[str] = set()
        self._local_alerts: List[Dict[str, Any]] = []
        self._local_history: List[Dict[str, Any]] = []
        self._local_cache: Dict[str, Dict[str, Any]] = {}

        self._init_local_storage()
        self._init_redis()

    def _init_local_storage(self):
        """Initializes local storage directory and loads persisted state if present."""
        try:
            self._data_dir.mkdir(parents=True, exist_ok=True)
            if self._state_file.exists():
                with open(self._state_file, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    self._local_seen_events = set(data.get("seen_events", []))
                    self._local_alerts = data.get("alerts", [])
                    self._local_history = data.get("history", [])
        except Exception as e:
            logger.warning(f"Could not load local state file: {e}")

    def _json_default(self, obj: Any):
        if hasattr(obj, "model_dump"):
            return obj.model_dump()
        if hasattr(obj, "dict"):
            return obj.dict()
        return str(obj)

    def _persist_local_state(self):
        """Flushes in-memory fallback state to durable disk file."""
        try:
            state = self._read_state()
            state["seen_events"] = list(self._local_seen_events)
            state["alerts"] = self._local_alerts
            state["history"] = self._local_history
            state["updated_at"] = time.time()
            self._write_state(state)
        except Exception as e:
            logger.warning(f"Failed to persist local state to file: {e}")

    def _read_state(self) -> Dict[str, Any]:
        """Reads complete raw dictionary state from local durable file."""
        if self._state_file.exists():
            try:
                with open(self._state_file, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                pass
        return {
            "seen_events": list(self._local_seen_events),
            "alerts": self._local_alerts,
            "history": self._local_history,
            "fcm_device_tokens": {},
        }

    def _write_state(self, state: Dict[str, Any]) -> None:
        """Writes raw dictionary state to local durable file."""
        try:
            with open(self._state_file, "w", encoding="utf-8") as f:
                json.dump(state, f, indent=2, default=self._json_default)
        except Exception as e:
            logger.warning(f"Failed to write state to file: {e}")

    def _init_redis(self):
        """Attempts connection to Redis with short timeout."""
        try:
            import redis
            client = redis.Redis.from_url(
                self.redis_url,
                socket_connect_timeout=1.0,
                socket_timeout=1.0,
                decode_responses=True,
            )
            client.ping()
            self._redis_client = client
            self._is_redis_available = True
            logger.info(f"Connected to Redis at {self.redis_url}")
        except Exception as e:
            self._is_redis_available = False
            self._redis_client = None
            logger.info(f"Redis not available at {self.redis_url} ({e}); using durable local fallback.")

    @property
    def is_redis_available(self) -> bool:
        return self._is_redis_available

    def get_status(self) -> Dict[str, Any]:
        """Returns storage status and active persistence mechanism."""
        return {
            "redis_url": self.redis_url,
            "redis_connected": self._is_redis_available,
            "storage_backend": "redis_cluster" if self._is_redis_available else "durable_local_fallback",
            "durable_state_file": str(self._state_file),
            "seen_events_count": len(self.get_seen_event_ids()),
            "cached_alerts_count": len(self.get_alerts()),
            "cached_investigations_count": len(self.get_investigations()),
        }

    # 1. Deduplication (Seen Events)
    def add_seen_event(self, event_id: str) -> None:
        self._local_seen_events.add(event_id)
        if self._is_redis_available and self._redis_client:
            try:
                self._redis_client.sadd("climatwin:seen_events", event_id)
            except Exception:
                pass
        self._persist_local_state()

    def is_event_seen(self, event_id: str) -> bool:
        if self._is_redis_available and self._redis_client:
            try:
                return bool(self._redis_client.sismember("climatwin:seen_events", event_id))
            except Exception:
                pass
        return event_id in self._local_seen_events

    def get_seen_event_ids(self) -> Set[str]:
        if self._is_redis_available and self._redis_client:
            try:
                members = self._redis_client.smembers("climatwin:seen_events")
                return set(members) if members else self._local_seen_events
            except Exception:
                pass
        return self._local_seen_events

    # 2. Alert Storage
    def save_alert(self, alert: Dict[str, Any]) -> None:
        # Prepend to list
        self._local_alerts = [a for a in self._local_alerts if a.get("id") != alert.get("id")]
        self._local_alerts.insert(0, alert)
        if self._is_redis_available and self._redis_client:
            try:
                self._redis_client.lpush("climatwin:alerts", json.dumps(alert, default=self._json_default))
                self._redis_client.ltrim("climatwin:alerts", 0, 99)  # Keep latest 100 alerts
            except Exception:
                pass
        self._persist_local_state()

    def get_alerts(self, limit: int = 50) -> List[Dict[str, Any]]:
        if self._is_redis_available and self._redis_client:
            try:
                raw_items = self._redis_client.lrange("climatwin:alerts", 0, limit - 1)
                if raw_items:
                    return [json.loads(item) for item in raw_items]
            except Exception:
                pass
        return self._local_alerts[:limit]

    # 3. Investigation History
    def save_investigation(self, investigation: Dict[str, Any]) -> None:
        self._local_history.insert(0, investigation)
        if self._is_redis_available and self._redis_client:
            try:
                self._redis_client.lpush("climatwin:investigations", json.dumps(investigation, default=self._json_default))
                self._redis_client.ltrim("climatwin:investigations", 0, 99)
            except Exception:
                pass
        self._persist_local_state()

    def get_investigations(self, user_id: str = "default_user", limit: int = 50) -> List[Dict[str, Any]]:
        items = []
        if self._is_redis_available and self._redis_client:
            try:
                raw_items = self._redis_client.lrange("climatwin:investigations", 0, limit - 1)
                if raw_items:
                    items = [json.loads(item) for item in raw_items]
            except Exception:
                pass
        if not items:
            items = self._local_history

        if user_id == "all":
            return items[:limit]
        return [inv for inv in items if inv.get("user_id") == user_id][:limit]

    # 4. Key-Value Caching with TTL
    def cache_set(self, key: str, value: Any, ttl_seconds: int = 300) -> None:
        expire_at = time.time() + ttl_seconds
        self._local_cache[key] = {"val": value, "exp": expire_at}
        if self._is_redis_available and self._redis_client:
            try:
                self._redis_client.setex(f"climatwin:cache:{key}", ttl_seconds, json.dumps(value))
            except Exception:
                pass

    def cache_get(self, key: str) -> Optional[Any]:
        if self._is_redis_available and self._redis_client:
            try:
                raw = self._redis_client.get(f"climatwin:cache:{key}")
                if raw:
                    return json.loads(raw)
            except Exception:
                pass

        cached = self._local_cache.get(key)
        if cached:
            if time.time() < cached["exp"]:
                return cached["val"]
            del self._local_cache[key]
        return None

    def clear_all(self):
        """Utility for test resets."""
        self._local_seen_events.clear()
        self._local_alerts.clear()
        self._local_history.clear()
        self._local_cache.clear()
        if self._is_redis_available and self._redis_client:
            try:
                self._redis_client.delete("climatwin:seen_events", "climatwin:alerts", "climatwin:investigations")
                cache_keys = self._redis_client.keys("climatwin:cache:*")
                if cache_keys:
                    self._redis_client.delete(*cache_keys)
            except Exception:
                pass
        self._persist_local_state()


# Global store instance
redis_store = RedisStateStore()
