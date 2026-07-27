from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from config import settings

from routers import api

settings.audio_directory.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="PhraseCards API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
)
app.mount(
    settings.audio_url_path,
    StaticFiles(directory=settings.audio_directory),
    name="audio",
)

app.include_router(api.router, prefix="/api", tags=["api"])

@app.get("/api/health")
def health_check():
    return {"status": "ok"}
