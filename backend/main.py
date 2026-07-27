from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from config import settings

from routers import api

app = FastAPI(title="PhraseCards API")

app.include_router(api.router, prefix="/api", tags=["api"])

@app.get("/api/health")
def health_check():
    return {"status": "ok"}
