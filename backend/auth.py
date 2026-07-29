import secrets
from typing import Annotated

from fastapi import Header, HTTPException, status

from config import settings


def require_api_key(
    supplied_key: Annotated[str | None, Header(alias="X-PhraseCards-Key")] = None,
) -> None:
    if not settings.api_key:
        return
    if supplied_key is None or not secrets.compare_digest(
        supplied_key,
        settings.api_key,
    ):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)
