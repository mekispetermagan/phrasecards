from fastapi import APIRouter, Depends

from auth import require_api_key
from routers import phrases, requests

router = APIRouter(dependencies=[Depends(require_api_key)])
router.include_router(phrases.router)
router.include_router(requests.router)
