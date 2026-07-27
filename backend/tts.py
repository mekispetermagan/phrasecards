import hashlib
import io
import logging
import os
import tempfile
from pathlib import Path
from typing import Protocol

from sqlalchemy.orm import Session

from config import settings
from database import SessionLocal
from models import Phrase

logger = logging.getLogger(__name__)


class SpeechSynthesizer(Protocol):
    def synthesize_mp3(self, text: str) -> bytes: ...


class GTtsSynthesizer:
    def synthesize_mp3(self, text: str) -> bytes:
        from gtts import gTTS

        output = io.BytesIO()
        speech = gTTS(
            text=text,
            lang=settings.tts_language,
            tld=settings.tts_tld,
        )
        speech.write_to_fp(output)
        return output.getvalue()


def phrase_audio_filename(phrase: Phrase) -> str:
    fingerprint = "\0".join(
        (phrase.target, "gtts", settings.tts_language, settings.tts_tld, "mp3")
    )
    digest = hashlib.sha256(fingerprint.encode("utf-8")).hexdigest()[:16]
    return f"phrase-{phrase.id}-{digest}.mp3"


def synthesize_phrase_audio(
    phrase: Phrase,
    synthesizer: SpeechSynthesizer,
    audio_directory: Path = settings.audio_directory,
) -> str:
    filename = phrase_audio_filename(phrase)
    destination = audio_directory / filename
    audio = synthesizer.synthesize_mp3(phrase.target)
    if not audio:
        raise ValueError("Text-to-speech returned an empty audio file")

    audio_directory.mkdir(parents=True, exist_ok=True)
    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            dir=audio_directory,
            prefix=f".{filename}.",
            suffix=".tmp",
            delete=False,
        ) as temporary_file:
            temporary_path = Path(temporary_file.name)
            temporary_file.write(audio)
            temporary_file.flush()
            os.fsync(temporary_file.fileno())
        os.replace(temporary_path, destination)
    finally:
        if temporary_path is not None and temporary_path.exists():
            temporary_path.unlink()

    return f"{settings.audio_url_path.rstrip('/')}/{filename}"


def generate_phrase_audio(
    phrase_id: int,
    synthesizer: SpeechSynthesizer | None = None,
) -> bool:
    db = SessionLocal()
    try:
        phrase = db.get(Phrase, phrase_id)
        if phrase is None:
            logger.warning("Cannot generate audio: phrase %s does not exist", phrase_id)
            return False
        phrase.audio_path = synthesize_phrase_audio(
            phrase, synthesizer or GTtsSynthesizer()
        )
        db.commit()
        return True
    except Exception:
        db.rollback()
        logger.exception("Failed to generate audio for phrase %s", phrase_id)
        return False
    finally:
        db.close()


def generate_missing_audio(
    db: Session,
    synthesizer: SpeechSynthesizer | None = None,
) -> tuple[int, int]:
    phrases = db.query(Phrase).filter(Phrase.audio_path.is_(None)).all()
    if not phrases:
        return (0, 0)

    active_synthesizer = synthesizer or GTtsSynthesizer()
    generated = 0
    for phrase in phrases:
        try:
            phrase.audio_path = synthesize_phrase_audio(phrase, active_synthesizer)
            db.commit()
            generated += 1
        except Exception:
            db.rollback()
            logger.exception("Failed to generate audio for phrase %s", phrase.id)

    return (generated, len(phrases) - generated)
