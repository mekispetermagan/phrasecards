from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import get_db
from models import Phrase
from schemas.api import PhraseOut

DbSession = Annotated[Session, Depends(get_db)]

router = APIRouter()


@router.get(
    "/phrases",
    response_model=list[PhraseOut],
)
def get_phrases(db: DbSession):
    phrases = db.query(Phrase).all()

    return [
        PhraseOut(
            id=phrase.id,
            source=phrase.source,
            target=phrase.target,
            new=phrase.new,
            rating=phrase.rating,
            audio_path=phrase.audio_path,
        )
        for phrase in phrases
    ]
