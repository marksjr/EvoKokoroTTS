from pydantic import BaseModel, Field
from typing import Literal


class TTSRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=10000, description="Texto para sintetizar")
    voice: str = Field(default="pf_dora", description="ID da voz")
    speed: float = Field(default=1.0, ge=0.5, le=2.0, description="Velocidade da fala")
    format: Literal["mp3", "wav"] = Field(default="mp3", description="Formato de saída")


class TTSStreamRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=10000, description="Texto para sintetizar")
    voice: str = Field(default="pf_dora", description="ID da voz")
    speed: float = Field(default=1.0, ge=0.5, le=2.0, description="Velocidade da fala")


class HealthResponse(BaseModel):
    status: str
    device: str
    model_loaded: bool


class VoiceInfo(BaseModel):
    id: str
    name: str
    gender: str
    lang: str
    description: str
