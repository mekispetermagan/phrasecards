from sqlalchemy import Boolean, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from database import Base


class Phrase(Base):
    __tablename__ = "phrase"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    source: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    target: Mapped[str] = mapped_column(String(255), unique=False, nullable=False)
    new: Mapped[bool] = mapped_column(Boolean, unique=False, nullable=False)
    rating: Mapped[int] = mapped_column(Integer, unique=False, nullable=True)
    audio_path: Mapped[str | None] = mapped_column(
        String(255),
        unique=False,
        nullable=True,
    )


class PhraseRequest(Base):
    __tablename__ = "phrase_request"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    source: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
