from config import settings


def test_api_key_hides_protected_routes_when_missing_or_wrong(client):
    previous_key = settings.api_key
    settings.api_key = "correct-key"
    try:
        assert client.get("/api/phrases").status_code == 404
        assert client.get(
            "/api/phrases",
            headers={"X-PhraseCards-Key": "wrong-key"},
        ).status_code == 404
        assert client.get(
            "/api/phrases",
            headers={"X-PhraseCards-Key": "correct-key"},
        ).status_code == 200
        assert client.get("/api/health").status_code == 200
    finally:
        settings.api_key = previous_key
