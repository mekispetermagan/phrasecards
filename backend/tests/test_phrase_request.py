import pytest
from pydantic import ValidationError

from models import Phrase, PhraseRequest
from schemas.api import PhraseRequestCreate, PhraseRequestOut


def test_phrase_request_can_be_persisted(db_session):
    request = PhraseRequest(source="Good afternoon!")
    db_session.add(request)
    db_session.commit()
    db_session.refresh(request)

    assert request.id == 1
    assert request.source == "Good afternoon!"


def test_phrase_request_create_strips_surrounding_whitespace():
    request = PhraseRequestCreate(source="  Good afternoon!  ")

    assert request.source == "Good afternoon!"


@pytest.mark.parametrize("source", ["", "   "])
def test_phrase_request_create_rejects_empty_source(source):
    with pytest.raises(ValidationError):
        PhraseRequestCreate(source=source)


def test_phrase_request_create_rejects_bare_string():
    with pytest.raises(ValidationError):
        PhraseRequestCreate.model_validate("Good afternoon!")


def test_phrase_request_out_has_identity():
    response = PhraseRequestOut(id=7, source="Good afternoon!")

    assert response.model_dump() == {
        "id": 7,
        "source": "Good afternoon!",
    }



def test_get_requests_returns_empty_list(client):
    response = client.get("/api/requests")

    assert response.status_code == 200
    assert response.json() == []


def test_post_request_creates_and_returns_request(client, db_session):
    response = client.post(
        "/api/requests",
        json={"source": "  Good afternoon!  "},
    )

    assert response.status_code == 201
    assert response.json() == {
        "id": 1,
        "source": "Good afternoon!",
    }

    stored = db_session.query(PhraseRequest).one()
    assert stored.source == "Good afternoon!"


def test_get_requests_returns_stored_requests(client, db_session):
    db_session.add_all(
        [
            PhraseRequest(source="Good afternoon!"),
            PhraseRequest(source="Where is the station?"),
        ]
    )
    db_session.commit()

    response = client.get("/api/requests")

    assert response.status_code == 200
    assert response.json() == [
        {"id": 1, "source": "Good afternoon!"},
        {"id": 2, "source": "Where is the station?"},
    ]


@pytest.mark.parametrize(
    "body",
    [
        "Good afternoon!",
        {"source": ""},
        {"source": "   "},
        {},
    ],
)
def test_post_request_rejects_invalid_body(client, body):
    response = client.post("/api/requests", json=body)

    assert response.status_code == 422



def test_post_request_rejects_existing_pending_request(client, db_session):
    db_session.add(PhraseRequest(source="Good afternoon!"))
    db_session.commit()

    response = client.post(
        "/api/requests",
        json={"source": "Good afternoon!"},
    )

    assert response.status_code == 409
    assert response.json() == {"detail": "Phrase request already exists"}


def test_post_request_rejects_resolved_phrase(client, db_session):
    db_session.add(
        Phrase(
            source="Good afternoon!",
            target="Jó napot!",
            new=False,
            rating=3,
        )
    )
    db_session.commit()

    response = client.post(
        "/api/requests",
        json={"source": "Good afternoon!"},
    )

    assert response.status_code == 409
    assert response.json() == {"detail": "Phrase already exists"}


def test_put_request_is_not_allowed(client):
    response = client.put(
        "/api/requests",
        json={"source": "Good afternoon!"},
    )

    assert response.status_code == 405



def test_phrase_request_source_is_unique():
    assert PhraseRequest.__table__.c.source.unique is True



def test_resolve_request_creates_phrase_and_removes_request(client, db_session):
    request = PhraseRequest(source="Good afternon!")
    db_session.add(request)
    db_session.commit()
    db_session.refresh(request)

    response = client.post(
        "/api/requests/resolve",
        json={
            "request_id": request.id,
            "source": "  Good afternoon!  ",
            "target": "  Jó napot!  ",
        },
    )

    assert response.status_code == 201
    assert response.json() == {
        "id": 1,
        "source": "Good afternoon!",
        "target": "Jó napot!",
        "new": True,
        "rating": 3,
    }
    assert db_session.query(PhraseRequest).count() == 0

    phrase = db_session.query(Phrase).one()
    assert phrase.source == "Good afternoon!"
    assert phrase.target == "Jó napot!"
    assert phrase.new is True
    assert phrase.rating == 3


def test_resolve_request_returns_not_found(client):
    response = client.post(
        "/api/requests/resolve",
        json={
            "request_id": 999,
            "source": "Good afternoon!",
            "target": "Jó napot!",
        },
    )

    assert response.status_code == 404
    assert response.json() == {"detail": "Phrase request not found"}


@pytest.mark.parametrize(
    "body",
    [
        {"request_id": 0, "source": "Good afternoon!", "target": "Jó napot!"},
        {"request_id": -1, "source": "Good afternoon!", "target": "Jó napot!"},
        {"request_id": 1, "source": "", "target": "Jó napot!"},
        {"request_id": 1, "source": "   ", "target": "Jó napot!"},
        {"request_id": 1, "source": "Good afternoon!", "target": ""},
        {"request_id": 1, "source": "Good afternoon!", "target": "   "},
        {"request_id": 1, "source": "Good afternoon!"},
        {"request_id": 1, "target": "Jó napot!"},
        {"source": "Good afternoon!", "target": "Jó napot!"},
        "Jó napot!",
    ],
)
def test_resolve_request_rejects_invalid_body(client, body):
    response = client.post("/api/requests/resolve", json=body)

    assert response.status_code == 422


def test_resolve_conflict_keeps_request(client, db_session):
    db_session.add_all(
        [
            PhraseRequest(source="Good afternoon!"),
            Phrase(
                source="Good afternoon!",
                target="Existing translation",
                new=False,
                rating=2,
            ),
        ]
    )
    db_session.commit()
    request = db_session.query(PhraseRequest).one()

    response = client.post(
        "/api/requests/resolve",
        json={
            "request_id": request.id,
            "source": "Good afternoon!",
            "target": "Jó napot!",
        },
    )

    assert response.status_code == 409
    assert response.json() == {"detail": "Phrase already exists"}
    assert db_session.query(PhraseRequest).count() == 1
    assert db_session.query(Phrase).count() == 1
