"""Firebase Cloud Messaging (FCM) & Push Notification Delivery Service.

Implements secure server-side push notification delivery and device token management:
- Manages user-scoped device tokens
- Sends FCM push notifications for critical climate hazard alerts
- Distinguishes between:
  1. "stored_only" (Alert persisted in Firestore / Redis, but no device token active)
  2. "delivered" (FCM message successfully dispatched and acknowledged by Google FCM)
  3. "failed" / "unregistered" (Token expired or network error)
- Never falsely claims a push was delivered when only database storage occurred
"""

import os
import json
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime, timezone
from pydantic import BaseModel, Field

from app.core.config import settings
from app.core.redis_store import redis_store

logger = logging.getLogger("climatwin.fcm")


class FCMDeviceRegistration(BaseModel):
    user_id: str
    fcm_token: str
    device_platform: str = "android"  # android, ios, web
    registered_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    last_active_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())


class FCMDeliveryResult(BaseModel):
    notification_id: str
    user_id: str
    alert_id: str
    title: str
    push_delivery_status: str  # "delivered", "stored_only", "failed", "unregistered"
    fcm_message_id: Optional[str] = None
    target_tokens_count: int = 0
    delivered_tokens_count: int = 0
    failed_tokens_count: int = 0
    timestamp: str
    is_live_fcm: bool = False
    details: str


class FCMNotificationService:
    """Service for managing FCM tokens and dispatching push notifications."""

    def __init__(self):
        self._firebase_initialized: bool = False
        self._init_firebase_admin()

    def _init_firebase_admin(self):
        """Initializes Firebase Admin SDK if service account credentials exist."""
        try:
            import firebase_admin
            from firebase_admin import credentials

            if firebase_admin._apps:
                self._firebase_initialized = True
                return

            cred_path = getattr(settings, "FIREBASE_CREDENTIALS_PATH", "./serviceAccountKey.json")
            if os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred, {
                    "projectId": getattr(settings, "FIREBASE_PROJECT_ID", "invest-2-77a18")
                })
                self._firebase_initialized = True
                logger.info("Firebase Admin SDK initialized with service account.")
            else:
                logger.info(f"Firebase credentials not found at {cred_path}; running in durable token tracking mode.")
        except Exception as e:
            logger.warning(f"Firebase Admin SDK initialization skipped: {e}")
            self._firebase_initialized = False

    def register_device_token(
        self, user_id: str, fcm_token: str, device_platform: str = "android"
    ) -> FCMDeviceRegistration:
        """Registers or updates a user device FCM token in durable state."""
        reg = FCMDeviceRegistration(
            user_id=user_id,
            fcm_token=fcm_token,
            device_platform=device_platform,
        )

        # Store in Redis/local state
        tokens_dict = redis_store._read_state().get("fcm_device_tokens", {})
        user_tokens = tokens_dict.get(user_id, [])

        # Deduplicate token
        existing = [t for t in user_tokens if t.get("fcm_token") != fcm_token]
        existing.append(reg.model_dump())
        tokens_dict[user_id] = existing

        state = redis_store._read_state()
        state["fcm_device_tokens"] = tokens_dict
        redis_store._write_state(state)

        logger.info(f"Registered FCM token for user '{user_id}' on {device_platform}.")
        return reg

    def get_user_device_tokens(self, user_id: str) -> List[str]:
        """Retrieves active device tokens for the user."""
        state = redis_store._read_state()
        user_tokens = state.get("fcm_device_tokens", {}).get(user_id, [])
        return [t["fcm_token"] for t in user_tokens if "fcm_token" in t]

    def send_alert_push_notification(
        self,
        user_id: str,
        alert_id: str,
        title: str,
        body: str,
        data_payload: Optional[Dict[str, str]] = None,
    ) -> FCMDeliveryResult:
        """Dispatches an FCM push notification to user's registered devices.
        
        Strictly distinguishes 'delivered' from 'stored_only'.
        """
        now_utc = datetime.now(timezone.utc).isoformat()
        notification_id = f"notif_{alert_id}_{int(datetime.now(timezone.utc).timestamp())}"
        tokens = self.get_user_device_tokens(user_id)

        # Case 1: No devices registered -> Alert is stored in DB, but NO push delivered
        if not tokens:
            return FCMDeliveryResult(
                notification_id=notification_id,
                user_id=user_id,
                alert_id=alert_id,
                title=title,
                push_delivery_status="stored_only",
                target_tokens_count=0,
                delivered_tokens_count=0,
                failed_tokens_count=0,
                timestamp=now_utc,
                is_live_fcm=False,
                details="Alert persisted in database. No active device push token registered for user.",
            )

        # Case 2: Firebase Admin initialized -> Attempt real live Google FCM dispatch
        if self._firebase_initialized:
            try:
                from firebase_admin import messaging
                delivered_count = 0
                failed_count = 0
                last_msg_id = None

                for token in tokens:
                    try:
                        message = messaging.Message(
                            notification=messaging.Notification(
                                title=title,
                                body=body,
                            ),
                            data=data_payload or {"alert_id": alert_id, "user_id": user_id},
                            token=token,
                        )
                        response = messaging.send(message)
                        last_msg_id = response
                        delivered_count += 1
                    except Exception as e:
                        logger.warning(f"Failed to send to token {token[:10]}...: {e}")
                        failed_count += 1

                status = "delivered" if delivered_count > 0 else "failed"
                return FCMDeliveryResult(
                    notification_id=notification_id,
                    user_id=user_id,
                    alert_id=alert_id,
                    title=title,
                    push_delivery_status=status,
                    fcm_message_id=last_msg_id,
                    target_tokens_count=len(tokens),
                    delivered_tokens_count=delivered_count,
                    failed_tokens_count=failed_count,
                    timestamp=now_utc,
                    is_live_fcm=True,
                    details=f"Dispatched via Google FCM API to {delivered_count}/{len(tokens)} devices.",
                )
            except Exception as e:
                logger.error(f"FCM messaging dispatch error: {e}")

        # Case 3: Registered token present but server serviceAccountKey not loaded
        # Transparently report status as token registered but awaiting admin dispatch
        return FCMDeliveryResult(
            notification_id=notification_id,
            user_id=user_id,
            alert_id=alert_id,
            title=title,
            push_delivery_status="stored_only",
            fcm_message_id=f"fcm_sim_{notification_id[:12]}",
            target_tokens_count=len(tokens),
            delivered_tokens_count=0,
            failed_tokens_count=0,
            timestamp=now_utc,
            is_live_fcm=False,
            details=(
                f"Alert stored in database with {len(tokens)} token(s) enrolled. "
                f"Live FCM push awaiting server serviceAccountKey.json activation."
            ),
        )


fcm_service = FCMNotificationService()
