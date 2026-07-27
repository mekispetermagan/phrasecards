from typing import Annotated

from pydantic import BaseModel, Field, StringConstraints

PhraseSource = Annotated[
    str,
    StringConstraints(strip_whitespace=True, min_length=1, max_length=255),
]

class PhraseOut(BaseModel):
    id: int
    source: str
    target: str
    new: bool
    rating: int | None


class PhraseRequestCreate(BaseModel):
    source: PhraseSource


class PhraseRequestResolve(BaseModel):
    request_id: int = Field(gt=0)
    source: PhraseSource
    target: PhraseSource


class PhraseRequestOut(BaseModel):
    id: int
    source: str
