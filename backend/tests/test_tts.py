from pathlib import Path

import pytest

from models import Phrase
from tts import phrase_audio_filename, synthesize_phrase_audio


class FakeSynthesizer:
    def __init__(self, audio: bytes = b"fake mp3") -> None:
        self.audio = audio
        self.texts: list[str] = []

    def synthesize_mp3(self, text: str) -> bytes:
        self.texts.append(text)
        return self.audio


def test_synthesize_phrase_audio_writes_target_atomically(tmp_path: Path):
    phrase = Phrase(id=12, source="Thank you", target="Köszönöm")
    synthesizer = FakeSynthesizer()

    audio_path = synthesize_phrase_audio(phrase, synthesizer, tmp_path)

    filename = phrase_audio_filename(phrase)
    assert audio_path == f"/audio/{filename}"
    assert (tmp_path / filename).read_bytes() == b"fake mp3"
    assert synthesizer.texts == ["Köszönöm"]
    assert list(tmp_path.glob("*.tmp")) == []


def test_audio_filename_changes_when_target_changes():
    original = Phrase(id=12, source="Thank you", target="Köszönöm")
    corrected = Phrase(id=12, source="Thank you", target="Nagyon köszönöm")

    assert phrase_audio_filename(original) != phrase_audio_filename(corrected)


def test_empty_synthesis_does_not_create_file(tmp_path: Path):
    phrase = Phrase(id=12, source="Thank you", target="Köszönöm")

    with pytest.raises(ValueError, match="empty"):
        synthesize_phrase_audio(phrase, FakeSynthesizer(b""), tmp_path)

    assert list(tmp_path.iterdir()) == []
