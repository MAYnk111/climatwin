import pytest
from unittest.mock import patch
from app.adapters.gdelt_news import GDELTNewsAdapter, GDELTArticle
from app.core.fcm_service import FCMNotificationService
from app.core.redis_store import redis_store


@pytest.fixture(autouse=True)
def clean_redis():
    redis_store.clear_all()
    yield
    redis_store.clear_all()


@pytest.mark.anyio
async def test_gdelt_adapter_deduplication_and_caching():
    """Verifies that GDELT news articles are deduplicated and cached with 25-minute TTL."""
    adapter = GDELTNewsAdapter(cache_ttl_seconds=1500)

    # Simulated GDELT API response with duplicate URLs
    fake_response = {
        "articles": [
            {
                "url": "https://reuters.com/taiwan-drought-semis-01",
                "title": "Taiwan Water Authorities Monitor Hsinchu Science Park",
                "domain": "reuters.com",
                "seendate": "20261009T080000Z",
            },
            {
                "url": "https://reuters.com/taiwan-drought-semis-01",  # Duplicate
                "title": "Taiwan Water Authorities Monitor Hsinchu Science Park",
                "domain": "reuters.com",
                "seendate": "20261009T080000Z",
            },
            {
                "url": "https://bloomberg.com/rhine-barge-levels-02",
                "title": "Rhine River Barge Navigation Faces Draft Constraints",
                "domain": "bloomberg.com",
                "seendate": "20261009T090000Z",
            },
        ]
    }

    from unittest.mock import MagicMock
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = fake_response

    with patch("httpx.AsyncClient.get", return_value=mock_resp) as mock_get:
        articles = await adapter.fetch_hazard_news(query="test_query")
        # Deduplication must collapse the 2 identical URLs
        assert len(articles) == 2
        assert articles[0].url != articles[1].url

    # Second call should read from Redis cache
    with patch("httpx.AsyncClient.get") as mock_get_second:
        cached_articles = await adapter.fetch_hazard_news(query="test_query")
        mock_get_second.assert_not_called()
        assert len(cached_articles) == 2


@pytest.mark.anyio
async def test_gdelt_timeout_fallback_bulletins():
    """Verifies that GDELT timeouts fall back to verified physical intelligence bulletins."""
    adapter = GDELTNewsAdapter()

    with patch("httpx.AsyncClient.get", side_effect=Exception("Read timeout")):
        articles = await adapter.fetch_hazard_news(hazard_topic="Drought")
        assert len(articles) > 0
        assert articles[0].is_live_feed is False
        assert "Taiwan" in articles[0].title or "Reservoir" in articles[0].title


def test_fcm_token_registration_and_deduplication():
    """Verifies that user device FCM tokens are registered and deduplicated."""
    service = FCMNotificationService()

    # Register token for user
    reg1 = service.register_device_token(user_id="user_alpha", fcm_token="token_xyz_123")
    assert reg1.user_id == "user_alpha"
    assert reg1.fcm_token == "token_xyz_123"

    tokens = service.get_user_device_tokens("user_alpha")
    assert "token_xyz_123" in tokens

    # Registering the same token again must not duplicate
    service.register_device_token(user_id="user_alpha", fcm_token="token_xyz_123")
    tokens_after = service.get_user_device_tokens("user_alpha")
    assert len(tokens_after) == 1


def test_fcm_delivery_status_distinction():
    """Verifies strict distinction between 'delivered' and 'stored_only' status."""
    service = FCMNotificationService()

    # User with NO device tokens: Must be 'stored_only', never falsely 'delivered'
    res_no_tokens = service.send_alert_push_notification(
        user_id="user_unregistered",
        alert_id="alt_999",
        title="Severe Flood Warning",
        body="Flash flood near facility.",
    )
    assert res_no_tokens.push_delivery_status == "stored_only"
    assert res_no_tokens.delivered_tokens_count == 0
    assert "No active device push token" in res_no_tokens.details

    # User with registered token but without active server serviceAccountKey.json
    service.register_device_token(user_id="user_beta", fcm_token="token_device_abc")
    res_with_token = service.send_alert_push_notification(
        user_id="user_beta",
        alert_id="alt_1000",
        title="Drought Stage 2 Alert",
        body="Water rationing active.",
    )
    # If service account is absent, it must report stored_only with enrolled tokens
    if not service._firebase_initialized:
        assert res_with_token.push_delivery_status == "stored_only"
        assert res_with_token.target_tokens_count == 1
        assert "awaiting server serviceAccountKey" in res_with_token.details
