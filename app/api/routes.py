import logging
from fastapi import APIRouter, HTTPException
from fastapi.responses import Response, StreamingResponse
from app.models.schemas import TTSRequest, TTSStreamRequest, HealthResponse, VoiceInfo
from app.services.tts_service import tts_service

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/health", response_model=HealthResponse)
async def health():
    return HealthResponse(
        status="ok" if tts_service.model_loaded else "loading",
        device=tts_service.device,
        model_loaded=tts_service.model_loaded,
    )


@router.get("/voices", response_model=list[VoiceInfo])
async def list_voices():
    return [VoiceInfo(**v) for v in tts_service.get_voices()]


@router.post("/tts")
async def text_to_speech(req: TTSRequest):
    if not tts_service.validate_voice(req.voice):
        raise HTTPException(400, f"Voz '{req.voice}' não disponível. Use GET /voices.")

    try:
        audio_bytes = await tts_service.generate(
            text=req.text, voice=req.voice, speed=req.speed, fmt=req.format,
        )
    except Exception as e:
        logger.exception("Erro na geração de áudio")
        raise HTTPException(500, f"Erro na geração: {str(e)}")

    media_type = "audio/mpeg" if req.format == "mp3" else "audio/wav"
    return Response(
        content=audio_bytes,
        media_type=media_type,
        headers={"Content-Disposition": f'attachment; filename="tts.{req.format}"'},
    )


@router.post("/tts/stream")
async def text_to_speech_stream(req: TTSStreamRequest):
    if not tts_service.validate_voice(req.voice):
        raise HTTPException(400, f"Voz '{req.voice}' não disponível.")

    async def audio_generator():
        async for chunk in tts_service.generate_stream(
            text=req.text, voice=req.voice, speed=req.speed,
        ):
            yield chunk

    return StreamingResponse(
        audio_generator(),
        media_type="audio/mpeg",
        headers={"Content-Disposition": 'attachment; filename="tts_stream.mp3"'},
    )
