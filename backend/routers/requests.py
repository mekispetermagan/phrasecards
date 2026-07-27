from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from database import get_db
from models import Phrase, PhraseRequest
from schemas.api import (
    PhraseOut,
    PhraseRequestCreate,
    PhraseRequestOut,
    PhraseRequestResolve,
)

DbSession = Annotated[Session, Depends(get_db)]

router = APIRouter()


@router.get(
    "/requests",
    response_model=list[PhraseRequestOut],
)
def get_requests(db: DbSession):
    requests = db.query(PhraseRequest).all()

    return [
        PhraseRequestOut(
            id=request.id,
            source=request.source,
        )
        for request in requests
    ]


@router.post(
    "/requests",
    response_model=PhraseRequestOut,
    status_code=status.HTTP_201_CREATED,
)
def add_request(request_data: PhraseRequestCreate, db: DbSession):
    resolved_phrase = (
        db.query(Phrase).filter(Phrase.source == request_data.source).first()
    )
    if resolved_phrase is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Phrase already exists",
        )

    pending_request = (
        db.query(PhraseRequest)
        .filter(PhraseRequest.source == request_data.source)
        .first()
    )
    if pending_request is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Phrase request already exists",
        )

    request = PhraseRequest(source=request_data.source)
    db.add(request)

    try:
        db.commit()
    except IntegrityError as error:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Phrase request already exists",
        ) from error

    db.refresh(request)

    return PhraseRequestOut(
        id=request.id,
        source=request.source,
    )



@router.post(
    "/requests/resolve",
    response_model=PhraseOut,
    status_code=status.HTTP_201_CREATED,
)
def resolve_request(resolution: PhraseRequestResolve, db: DbSession):
    request = db.get(PhraseRequest, resolution.request_id)
    if request is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Phrase request not found",
        )

    phrase = Phrase(
        source=resolution.source,
        target=resolution.target,
        new=True,
        rating=3,
    )
    db.add(phrase)
    db.delete(request)

    try:
        db.commit()
    except IntegrityError as error:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Phrase already exists",
        ) from error

    db.refresh(phrase)

    return PhraseOut(
        id=phrase.id,
        source=phrase.source,
        target=phrase.target,
        new=phrase.new,
        rating=phrase.rating,
    )
