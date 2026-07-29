from models import Phrase


def test_health_check(client):
    response = client.get("/api/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_get_phrases_returns_empty_list(client):
    response = client.get("/api/phrases")

    assert response.status_code == 200
    assert response.json() == []


def test_get_phrases_returns_database_rows(client, db_session):
    db_session.add_all(
        [
            Phrase(
                source="Good morning!",
                target="Jó reggelt!",
                new=False,
                rating=3,
            ),
            Phrase(
                source="New phrase",
                target="Új kifejezés",
                new=True,
                rating=None,
            ),
        ]
    )
    db_session.commit()

    response = client.get("/api/phrases")

    assert response.status_code == 200
    assert response.json() == [
        {
            "id": 1,
            "source": "Good morning!",
            "target": "Jó reggelt!",
            "new": False,
            "rating": 3,
            "audio_path": None,
        },
        {
            "id": 2,
            "source": "New phrase",
            "target": "Új kifejezés",
            "new": True,
            "rating": None,
            "audio_path": None,
        },
    ]


def test_post_phrases_is_not_allowed(client):
    response = client.post("/api/phrases")

    assert response.status_code == 405


def test_mark_phrase_seen_clears_new_flag(client, db_session):
    phrase = Phrase(
        source="New phrase",
        target="Új kifejezés",
        new=True,
        rating=3,
    )
    db_session.add(phrase)
    db_session.commit()

    response = client.patch(f"/api/phrases/{phrase.id}/seen")

    assert response.status_code == 204
    db_session.refresh(phrase)
    assert phrase.new is False


def test_mark_phrase_seen_is_idempotent(client, db_session):
    phrase = Phrase(
        source="Known phrase",
        target="Ismert kifejezés",
        new=False,
        rating=3,
    )
    db_session.add(phrase)
    db_session.commit()

    response = client.patch(f"/api/phrases/{phrase.id}/seen")

    assert response.status_code == 204
    db_session.refresh(phrase)
    assert phrase.new is False


def test_mark_phrase_seen_returns_not_found(client):
    response = client.patch("/api/phrases/999/seen")

    assert response.status_code == 404
    assert response.json() == {"detail": "Phrase not found"}
