from typing import Generic, TypeVar, Optional
from pydantic import BaseModel, Field

T = TypeVar("T")

class MetaPage(BaseModel):
    limit: int = Field(default=50, ge=1, le=100)
    offset: int = Field(default=0, ge=0)
    total: int = Field(default=0, ge=0)

class Envelope(BaseModel, Generic[T]):
    data: T

class ListEnvelope(BaseModel, Generic[T]):
    data: list[T]
    meta: MetaPage

class MessageOut(BaseModel):
    message: str
