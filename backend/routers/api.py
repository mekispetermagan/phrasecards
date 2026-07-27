from fastapi import APIRouter

from routers import phrases, requests

router = APIRouter()
router.include_router(phrases.router)
router.include_router(requests.router)
