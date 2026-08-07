# PhraseCards

PhraseCards is a small, personal language-learning app I built for my wife,
Patience, to help her practise Hungarian—my native language.

It began with a simple idea: give her a quiet, friendly way to learn the
phrases that are useful in our actual life, rather than working through a
generic vocabulary course. The app is deliberately modest, but it is a real
full-stack application designed for two people to use from different places.

## What it does

- **Learn with phrase cards.** Read the English phrase, turn the card, and
  reveal its Hungarian translation.
- **Hear Hungarian pronunciation.** Target phrases have generated Hungarian
  speech using `gTTS`. Audio is downloaded only when requested and cached on
  the device for later use.
- **Practise with a quiz.** Choose the correct translation from four options
  and get immediate visual and audio feedback.
- **Request useful phrases.** Patience can submit a phrase whenever she needs
  one—even while she is at work.
- **Resolve requests remotely.** I can see the pending requests, correct any
  hurried spelling, add a natural Hungarian translation, and turn the request
  into a new phrase card.
- **Keep working when audio is unavailable.** Speech generation and playback
  are optional enhancements; a missing recording never prevents the phrase
  itself from being used.

The app currently has no accounts or public social features. It is intended as
a private shared space, not as a general language-learning platform.

## How it is built

The frontend is a Flutter application with controller-owned state and
presentation-only screens. It supports Linux, Android, and the web.

The backend is a FastAPI service backed by SQLite. It provides phrase and
request APIs, generates Hungarian MP3 files outside database transactions, and
serves those files from a public audio route. Generated filenames include a
content hash, so corrected translations naturally receive new recordings.

On native devices, recordings are stored under Flutter's application cache
directory. The client checks the local cache first, downloads only when
necessary, retries failed downloads, and writes files atomically. The web build
plays downloaded audio directly from memory.

## Repository layout

```text
backend/    FastAPI, SQLite, gTTS generation, and backend tests
frontend/   Flutter application, feature controllers, screens, and tests
```

## Running locally

Start the backend:

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt -r requirements-dev.txt
cp .env.example .env
python seed_db.py
python -m uvicorn main:app --reload
```

Then start Flutter in another terminal:

```bash
cd frontend
flutter pub get
flutter run -d linux
```

The default frontend configuration expects the API at
`http://127.0.0.1:8000`. A different endpoint can be supplied at build time:

```bash
flutter run -d linux --dart-define=API_BASE_URL=https://phrasecards.mekis.dev
```

See [`frontend/BUILDING.md`](frontend/BUILDING.md) for the ARM64-only Android
release process and complete frontend build instructions.

For more backend and reverse-proxy notes, see
[`backend/get_started.md`](backend/get_started.md).

## Tests

```bash
cd backend
python -m pytest
```

```bash
cd frontend
flutter analyze
flutter test
```

## A personal note

This project is intentionally small. Its purpose is not to compete with
language-learning products; it is to make Hungarian a little more present in
our everyday life, one useful phrase at a time.
