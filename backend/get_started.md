From `backend/`:

1. Create/activate the virtual environment and install dependencies:
   `python -m pip install -r requirements.txt -r requirements-dev.txt`
2. Copy `.env.example` to `.env` and adjust local paths/origins.
3. Recreate the development database and synthesize seed audio: `python seed_db.py`.
4. Retry any missing files later without touching database rows: `python generate_audio.py`.
5. Run the API: `python -m uvicorn main:app --reload`.

Audio is served at `/audio`. In production, Nginx may serve `backend/public/audio/`
directly at the same URL and reverse-proxy `/api` to Uvicorn. Set `CORS_ORIGINS` to
a JSON list of exact frontend web origins, for example
`["https://phrasecards.mekis.dev"]`. Native Flutter apps do not require CORS.
