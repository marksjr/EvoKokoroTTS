import numpy as np
import logging
import torch
from app.core.config import LANG_CODE, VOICES, DEFAULT_VOICE, DEVICE
from app.utils.text import preprocess_text_ptbr, chunk_text
from app.utils.audio import crossfade_chunks, trim_silence, normalize_audio

logger = logging.getLogger(__name__)


class KokoroEngine:
    """Evo KokoroTTS - Engine Kokoro-82M para pt-BR."""

    def __init__(self):
        self._pipeline = None
        self._loaded = False

    def load(self) -> None:
        if self._loaded:
            return
        from kokoro import KPipeline

        logger.info(f"[Kokoro] Carregando modelo (lang={LANG_CODE}, device={DEVICE})")
        self._pipeline = KPipeline(lang_code=LANG_CODE)
        self._loaded = True
        logger.info("[Kokoro] Modelo carregado com sucesso")

    @property
    def is_loaded(self) -> bool:
        return self._loaded

    def get_voices(self) -> list[dict]:
        return list(VOICES.values())

    def get_default_voice(self) -> str:
        return DEFAULT_VOICE

    def validate_voice(self, voice: str) -> bool:
        return voice in VOICES

    @torch.inference_mode()
    def _synth_chunk(self, text_chunk: str, voice: str, speed: float) -> list[np.ndarray]:
        parts = []
        for gs, ps, audio in self._pipeline(text_chunk, voice=voice, speed=speed, split_pattern=r'\n+'):
            if audio is not None:
                parts.append(audio)
        return parts

    def synthesize(self, text: str, voice: str, speed: float) -> np.ndarray:
        text = preprocess_text_ptbr(text)
        chunks = chunk_text(text)
        logger.debug(f"[Kokoro] Texto dividido em {len(chunks)} chunks")

        audio_segments = []
        for chunk in chunks:
            parts = self._synth_chunk(chunk, voice, speed)
            if parts:
                audio_segments.append(np.concatenate(parts))

        if not audio_segments:
            raise RuntimeError("Nenhum áudio gerado")

        audio = crossfade_chunks(audio_segments)
        audio = trim_silence(audio)
        audio = normalize_audio(audio)
        return audio

    def synthesize_chunks(self, text: str, voice: str, speed: float) -> list[np.ndarray]:
        text = preprocess_text_ptbr(text)
        chunks = chunk_text(text)
        result = []

        for chunk in chunks:
            parts = self._synth_chunk(chunk, voice, speed)
            if parts:
                segment = np.concatenate(parts)
                segment = normalize_audio(segment)
                result.append(segment)

        return result

    def synthesize_chunk_generator(self, text: str, voice: str, speed: float):
        """Gera chunks de áudio um a um (para streaming verdadeiro)."""
        text = preprocess_text_ptbr(text)
        chunks = chunk_text(text)

        for chunk in chunks:
            parts = self._synth_chunk(chunk, voice, speed)
            if parts:
                segment = np.concatenate(parts)
                segment = normalize_audio(segment)
                yield segment
